import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/paquete_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/pedido_pack.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/asignar_ubicacion_paquetes_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/desempacar_producto_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/eliminar_paquete_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/get_ubicaciones_muelle_usecase.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/common/packing_operacion.dart';

part 'packing_packages_event.dart';
part 'packing_packages_state.dart';

/// Paquetes de un pedido: selección, desempacar, eliminar y ubicación de
/// muelle. Los datos los pone la página con [PaquetesPackActualizados]
/// (salen del detalle); tras cada cambio [PackingPackagesState.cambios]
/// sube y la página recarga el detalle.
@injectable
class PackingPackagesBloc
    extends Bloc<PackingPackagesEvent, PackingPackagesState> {
  final DesempacarProductoUseCase desempacar;
  final EliminarPaqueteUseCase eliminarPaquete;
  final GetUbicacionesMuelleUseCase getUbicaciones;
  final AsignarUbicacionPaquetesUseCase asignarUbicacion;

  PackingPackagesBloc(
    this.desempacar,
    this.eliminarPaquete,
    this.getUbicaciones,
    this.asignarUbicacion,
  ) : super(const PackingPackagesState()) {
    on<PaquetesPackActualizados>(_onActualizados);
    on<PaquetePackSeleccionado>(_onSeleccionado);
    on<SeleccionPaquetesPackReemplazada>(_onSeleccionReemplazada);
    on<PaquetePackEscaneado>(_onEscaneado);
    on<PaquetePackExpandido>(_onExpandido);
    on<ProductoPackDesempacado>(_onDesempacar, transformer: droppable());
    on<PaquetePackEliminado>(_onEliminar, transformer: droppable());
    on<UbicacionesMuellePackCargadas>(
      _onCargarUbicaciones,
      transformer: droppable(),
    );
    on<BusquedaUbicacionPackCambiada>(_onBusquedaUbicacion);
    on<UbicacionMuellePackElegida>(_onUbicacionElegida);
    on<UbicacionMuellePackEscaneada>(_onUbicacionEscaneada);
    on<UbicacionPaquetesPackAsignada>(_onAsignar, transformer: droppable());
  }

  void _onActualizados(
    PaquetesPackActualizados event,
    Emitter<PackingPackagesState> emit,
  ) {
    final ids = event.paquetes.map((p) => p.id).toSet();
    emit(
      state.copyWith(
        pedido: event.pedido,
        paquetes: event.paquetes,
        seleccionados: state.seleccionados.intersection(ids),
        limpiarExpandido: !ids.contains(state.expandido),
      ),
    );
  }

  void _onSeleccionado(
    PaquetePackSeleccionado event,
    Emitter<PackingPackagesState> emit,
  ) {
    final s = {...state.seleccionados};
    event.seleccionado ? s.add(event.paqueteId) : s.remove(event.paqueteId);
    emit(state.copyWith(seleccionados: s));
  }

  void _onSeleccionReemplazada(
    SeleccionPaquetesPackReemplazada event,
    Emitter<PackingPackagesState> emit,
  ) => emit(state.copyWith(seleccionados: {...event.paqueteIds}));

  /// Escanear una caja la agrega a la selección.
  void _onEscaneado(
    PaquetePackEscaneado event,
    Emitter<PackingPackagesState> emit,
  ) {
    final p = state.paquetes
        .where((p) => p.coincideCon(event.valor))
        .firstOrNull;
    if (p == null) {
      emit(
        state.copyWith(
          operacion: state.operacion.error('escaneo', 'Paquete no encontrado'),
        ),
      );
      return;
    }
    emit(state.copyWith(seleccionados: {...state.seleccionados, p.id}));
  }

  void _onExpandido(
    PaquetePackExpandido event,
    Emitter<PackingPackagesState> emit,
  ) => emit(
    state.copyWith(
      expandido: event.paqueteId,
      limpiarExpandido:
          event.paqueteId == null || event.paqueteId == state.expandido,
    ),
  );

  Future<void> _onDesempacar(
    ProductoPackDesempacado event,
    Emitter<PackingPackagesState> emit,
  ) async {
    final pedido = state.pedido;
    if (pedido == null) return;
    emit(
      state.copyWith(
        operacion: state.operacion.procesar('desempacar', 'Desempacando...'),
      ),
    );
    final r = await desempacar(
      DesempacarProductoParams(
        pedido: pedido,
        paquete: event.paquete,
        producto: event.producto,
      ),
    );
    r.fold(
      (f) => emit(
        state.copyWith(operacion: state.operacion.fallo('desempacar', f)),
      ),
      (res) => emit(
        state.copyWith(
          cambios: state.cambios + 1,
          operacion: res.desincronizado
              ? PackingOperacion(
                  tipo: TipoOperacion.desincronizado,
                  mensaje: res.mensaje,
                  accion: 'desempacar',
                  seq: state.operacion.seq + 1,
                )
              : state.operacion.exito('desempacar', res.mensaje),
        ),
      ),
    );
  }

  Future<void> _onEliminar(
    PaquetePackEliminado event,
    Emitter<PackingPackagesState> emit,
  ) async {
    final pedido = state.pedido;
    if (pedido == null) return;
    emit(
      state.copyWith(
        operacion: state.operacion.procesar(
          'eliminar',
          'Eliminando paquete...',
        ),
      ),
    );
    final r = await eliminarPaquete(
      EliminarPaqueteParams(pedido: pedido, paquete: event.paquete),
    );
    r.fold(
      (f) =>
          emit(state.copyWith(operacion: state.operacion.fallo('eliminar', f))),
      (msg) => emit(
        state.copyWith(
          cambios: state.cambios + 1,
          seleccionados: {...state.seleccionados}..remove(event.paquete.id),
          operacion: state.operacion.exito('eliminar', msg),
        ),
      ),
    );
  }

  Future<void> _onCargarUbicaciones(
    UbicacionesMuellePackCargadas event,
    Emitter<PackingPackagesState> emit,
  ) async {
    final r = await getUbicaciones(NoParams());
    r.fold(
      (f) => emit(
        state.copyWith(operacion: state.operacion.fallo('ubicaciones', f)),
      ),
      (u) => emit(state.copyWith(ubicaciones: u)),
    );
  }

  void _onBusquedaUbicacion(
    BusquedaUbicacionPackCambiada event,
    Emitter<PackingPackagesState> emit,
  ) => emit(state.copyWith(queryUbicacion: event.query));

  void _onUbicacionElegida(
    UbicacionMuellePackElegida event,
    Emitter<PackingPackagesState> emit,
  ) => emit(state.copyWith(ubicacion: event.ubicacion));

  void _onUbicacionEscaneada(
    UbicacionMuellePackEscaneada event,
    Emitter<PackingPackagesState> emit,
  ) {
    final v = event.valor.trim().toLowerCase();
    final u = state.ubicaciones
        .where((u) => u.barcode.toLowerCase() == v || u.name.toLowerCase() == v)
        .firstOrNull;
    if (u == null) {
      emit(
        state.copyWith(
          operacion: state.operacion.error(
            'escaneo',
            'Ubicación no encontrada',
          ),
        ),
      );
      return;
    }
    emit(state.copyWith(ubicacion: u));
  }

  Future<void> _onAsignar(
    UbicacionPaquetesPackAsignada event,
    Emitter<PackingPackagesState> emit,
  ) async {
    final pedido = state.pedido;
    final ubicacion = state.ubicacion;
    if (pedido == null) return;
    if (ubicacion == null) {
      emit(
        state.copyWith(
          operacion: state.operacion.error(
            'asignar',
            'Seleccione una ubicación',
          ),
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        operacion: state.operacion.procesar(
          'asignar',
          'Asignando ubicación...',
        ),
      ),
    );
    final r = await asignarUbicacion(
      AsignarUbicacionPaquetesParams(
        pedidoId: pedido.id,
        paquetes: state.paquetesSeleccionados,
        ubicacion: ubicacion,
      ),
    );
    r.fold(
      (f) =>
          emit(state.copyWith(operacion: state.operacion.fallo('asignar', f))),
      (msg) => emit(
        state.copyWith(
          cambios: state.cambios + 1,
          seleccionados: const {},
          limpiarUbicacion: true,
          operacion: state.operacion.exito('asignar', msg),
        ),
      ),
    );
  }
}
