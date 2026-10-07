import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_resultados.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/pedido_pack.dart';
import 'package:wms_app/features/packing_pedido/domain/rules/packing_rules.dart';
import 'package:wms_app/features/packing_pedido/domain/failures/packing_failures.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/validar_pedido_pack_usecase.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/common/packing_operacion.dart';

part 'packing_confirm_event.dart';
part 'packing_confirm_state.dart';

/// Cierre del pedido en Odoo, con o sin backorder. Si Odoo avisa productos
/// vencidos, queda esperando que el operario acepte y se reintenta.
@injectable
class PackingConfirmBloc
    extends Bloc<PackingConfirmEvent, PackingConfirmState> {
  final ValidarPedidoPackUseCase validarPedido;

  PackingConfirmBloc(this.validarPedido) : super(const PackingConfirmState()) {
    on<ValidacionPackSolicitada>(_onValidar, transformer: droppable());
    on<VencidosPackAceptados>(_onAceptarVencidos, transformer: droppable());
    on<VencidosPackRechazados>(_onRechazarVencidos);
  }

  Future<void> _onValidar(
    ValidacionPackSolicitada event,
    Emitter<PackingConfirmState> emit,
  ) async {
    final error = PackingRules.validarCierre(event.detalle);
    if (error != null) {
      emit(state.copyWith(operacion: state.operacion.error('validar', error)));
      return;
    }
    await _validar(
      emit,
      event.detalle.pedido,
      event.crearBackorder,
      aceptarVencidos: false,
    );
  }

  Future<void> _onAceptarVencidos(
    VencidosPackAceptados event,
    Emitter<PackingConfirmState> emit,
  ) async {
    final pendiente = state.vencidosPendientes;
    if (pendiente == null) return;
    await _validar(
      emit,
      pendiente.pedido,
      pendiente.crearBackorder,
      aceptarVencidos: true,
    );
  }

  void _onRechazarVencidos(
    VencidosPackRechazados event,
    Emitter<PackingConfirmState> emit,
  ) => emit(state.copyWith(limpiarVencidos: true));

  Future<void> _validar(
    Emitter<PackingConfirmState> emit,
    PedidoPack pedido,
    bool crearBackorder, {
    required bool aceptarVencidos,
  }) async {
    emit(
      state.copyWith(
        limpiarVencidos: true,
        operacion: state.operacion.procesar('validar', 'Validando pedido...'),
      ),
    );
    final r = await validarPedido(
      ValidarPedidoPackParams(
        pedido: pedido,
        crearBackorder: crearBackorder,
        aceptarVencidos: aceptarVencidos,
      ),
    );
    r.fold(
      (f) => f is PackingVencidosFailure
          ? emit(
              state.copyWith(
                vencidosPendientes: VencidosPendientes(pedido, crearBackorder),
                // Cierra el "procesando"; la UI pregunta por vencidosPendientes.
                operacion: PackingOperacion(
                  accion: 'vencidos',
                  mensaje: f.message,
                  seq: state.operacion.seq + 1,
                ),
              ),
            )
          : emit(
              state.copyWith(operacion: state.operacion.fallo('validar', f)),
            ),
      (res) => emit(
        state.copyWith(
          validado: true,
          conBackorder: res.conBackorder,
          operacion: state.operacion.exito('validar', res.mensaje),
        ),
      ),
    );
  }
}
