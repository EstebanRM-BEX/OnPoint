import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/features/expedition/domain/usecases/confirmar_pedido_usecase.dart';

part 'expedicion_confirm_event.dart';
part 'expedicion_confirm_state.dart';

/// Bloc de expedicion_detail_tab_detalles.dart: confirma (cierra) el pedido
/// de expedición completo vía api/complete_out, y complete_transfer/expire
/// cuando hay que forzar productos vencidos.
@injectable
class ExpedicionConfirmBloc
    extends Bloc<ExpedicionConfirmEvent, ExpedicionConfirmState> {
  final ConfirmarPedidoUseCase confirmarPedidoUseCase;

  ExpedicionConfirmBloc({required this.confirmarPedidoUseCase})
      : super(const ExpedicionConfirmInitial()) {
    on<ConfirmarPedidoEvent>(_onConfirmarPedido);
  }

  Future<void> _onConfirmarPedido(
    ConfirmarPedidoEvent event,
    Emitter<ExpedicionConfirmState> emit,
  ) async {
    emit(const ExpedicionConfirmLoading());

    final result = await confirmarPedidoUseCase(ConfirmarPedidoParams(
      expeditionId: event.expeditionId,
      forzarVencidos: event.forzarVencidos,
      crearBackorder: event.crearBackorder,
    ));

    result.fold(
      (failure) => emit(ExpedicionConfirmError(failure.message)),
      (_) => emit(const ExpedicionConfirmSuccess()),
    );
  }
}
