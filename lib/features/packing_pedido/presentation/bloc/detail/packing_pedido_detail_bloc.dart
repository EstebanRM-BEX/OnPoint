import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packaging_types/domain/entities/packaging_type.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_resultados.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/crear_paquete_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/deshacer_separacion_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/get_config_packing_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/get_pedido_pack_detalle_usecase.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/common/packing_operacion.dart';

part 'packing_pedido_detail_event.dart';
part 'packing_pedido_detail_state.dart';

/// Detalle de un pedido: líneas por estado, selección para empacar, crear
/// caja y deshacer una separación. Los paquetes (desempacar, eliminar,
/// ubicación) van en PackingPackagesBloc; tras cada cambio allá la página
/// manda [DetallePackRecargado] acá.
@injectable
class PackingPedidoDetailBloc
    extends Bloc<PackingPedidoDetailEvent, PackingPedidoDetailState> {
  final GetPedidoPackDetalleUseCase getDetalle;
  final CrearPaqueteUseCase crearPaquete;
  final DeshacerSeparacionUseCase deshacerSeparacion;
  final GetConfigPackingUseCase getConfig;

  PackingPedidoDetailBloc(
    this.getDetalle,
    this.crearPaquete,
    this.deshacerSeparacion,
    this.getConfig,
  ) : super(const PackingPedidoDetailState()) {
    on<DetallePackIniciado>(_onIniciado, transformer: restartable());
    on<DetallePackRecargado>(_onRecargado, transformer: restartable());
    on<BusquedaProductoPackCambiada>(_onBusqueda);
    on<ProductoPackSeleccionado>(_onSeleccionado);
    on<SeleccionPackReemplazada>(_onSeleccionReemplazada);
    on<StickerPackCambiado>(_onSticker);
    on<PaquetePackCreado>(_onCrearPaquete, transformer: droppable());
    on<SeparacionPackDeshecha>(_onDeshacer, transformer: droppable());
  }

  Future<void> _onIniciado(
    DetallePackIniciado event,
    Emitter<PackingPedidoDetailState> emit,
  ) async {
    emit(
      PackingPedidoDetailState(
        pedidoId: event.pedidoId,
        status: DetallePackStatus.cargando,
      ),
    );
    final config = await getConfig(NoParams());
    emit(state.copyWith(config: config.getOrElse((_) => state.config)));
    await _cargar(emit);
  }

  Future<void> _onRecargado(
    DetallePackRecargado event,
    Emitter<PackingPedidoDetailState> emit,
  ) => _cargar(emit);

  Future<void> _cargar(Emitter<PackingPedidoDetailState> emit) async {
    final id = state.pedidoId;
    if (id == null) return;
    final r = await getDetalle(GetPedidoPackDetalleParams(pedidoId: id));
    r.fold(
      (f) => emit(
        state.copyWith(
          status: DetallePackStatus.error,
          operacion: state.operacion.fallo('cargar', f),
        ),
      ),
      (detalle) {
        // La selección solo conserva líneas que siguen existiendo.
        final vigentes = {
          for (final p in [...detalle.porHacer, ...detalle.listos]) p.id,
        };
        emit(
          state.copyWith(
            status: DetallePackStatus.listo,
            detalle: detalle,
            seleccionados: state.seleccionados.intersection(vigentes),
          ),
        );
      },
    );
  }

  void _onBusqueda(
    BusquedaProductoPackCambiada event,
    Emitter<PackingPedidoDetailState> emit,
  ) => emit(state.copyWith(query: event.query));

  void _onSeleccionado(
    ProductoPackSeleccionado event,
    Emitter<PackingPedidoDetailState> emit,
  ) {
    final s = {...state.seleccionados};
    event.seleccionado ? s.add(event.productoId) : s.remove(event.productoId);
    emit(state.copyWith(seleccionados: s));
  }

  void _onSeleccionReemplazada(
    SeleccionPackReemplazada event,
    Emitter<PackingPedidoDetailState> emit,
  ) => emit(state.copyWith(seleccionados: {...event.productoIds}));

  void _onSticker(
    StickerPackCambiado event,
    Emitter<PackingPedidoDetailState> emit,
  ) => emit(state.copyWith(isSticker: event.isSticker));

  Future<void> _onCrearPaquete(
    PaquetePackCreado event,
    Emitter<PackingPedidoDetailState> emit,
  ) async {
    final detalle = state.detalle;
    if (detalle == null) return;
    final productos = event.certificado
        ? state.seleccionadosListos
        : state.seleccionadosPorHacer;

    emit(
      state.copyWith(
        operacion: state.operacion.procesar('crearPaquete', 'Empacando...'),
      ),
    );
    final r = await crearPaquete(
      CrearPaqueteParams(
        pedido: detalle.pedido,
        productos: productos,
        certificado: event.certificado,
        isSticker: state.isSticker,
        peso: event.peso,
        tipoEmpaque: event.tipoEmpaque,
      ),
    );
    await r.fold(
      (f) async => emit(
        state.copyWith(operacion: state.operacion.fallo('crearPaquete', f)),
      ),
      (paquete) async {
        emit(
          state.copyWith(
            seleccionados: state.seleccionados.difference(
              productos.map((p) => p.id).toSet(),
            ),
            isSticker: false,
            operacion: state.operacion.exito(
              'crearPaquete',
              'Paquete ${paquete.name} creado',
            ),
          ),
        );
        await _cargar(emit);
      },
    );
  }

  Future<void> _onDeshacer(
    SeparacionPackDeshecha event,
    Emitter<PackingPedidoDetailState> emit,
  ) async {
    emit(
      state.copyWith(
        operacion: state.operacion.procesar('deshacer', 'Deshaciendo...'),
      ),
    );
    final r = await deshacerSeparacion(
      DeshacerSeparacionParams(producto: event.producto),
    );
    await r.fold(
      (f) async =>
          emit(state.copyWith(operacion: state.operacion.fallo('deshacer', f))),
      (_) async {
        emit(
          state.copyWith(
            seleccionados: {...state.seleccionados}..remove(event.producto.id),
            operacion: state.operacion.exito(
              'deshacer',
              'Producto devuelto a por hacer',
            ),
          ),
        );
        await _cargar(emit);
      },
    );
  }
}
