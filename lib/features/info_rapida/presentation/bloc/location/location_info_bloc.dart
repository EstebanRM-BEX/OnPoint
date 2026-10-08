import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:wms_app/core/bloc/safe_bloc_mixin.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida_params.dart';
import 'package:wms_app/features/info_rapida/domain/failures/info_rapida_failures.dart';
import 'package:wms_app/features/info_rapida/domain/rules/propietario_rules.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/actualizar_ubicacion_usecase.dart';

part 'location_info_event.dart';
part 'location_info_state.dart';

/// Producto que puede entrar en una transferencia masiva.
bool esDisponibleParaMasiva(ProductoUbicacion p) =>
    p.packing != true && p.cantidadMano > 0;

@injectable
class LocationInfoBloc extends Bloc<LocationInfoEvent, LocationInfoState>
    with SafeBlocMixin<LocationInfoEvent, LocationInfoState> {
  final ActualizarUbicacionUseCase actualizarUbicacion;

  LocationInfoBloc({
    required this.actualizarUbicacion,
  }) : super(const LocationInfoState()) {
    on<LocationInfoInicializado>(_onInicializado);
    on<BuscarProductosUbicacionEvent>(
      _onBuscarProductos,
      transformer: restartable(),
    );
    on<OrdenarProductosUbicacionEvent>(_onOrdenarProductos);
    on<ToggleModoEdicionUbicacionEvent>(_onToggleModoEdicion);
    on<GuardarEdicionUbicacionEvent>(
      _onGuardarEdicion,
      transformer: droppable(),
    );
    on<ToggleModoSeleccionMasivaEvent>(_onToggleModoSeleccionMasiva);
    on<ToggleProductoSeleccionadoEvent>(_onToggleProductoSeleccionado);
    on<SeleccionarTodosProductosDisponiblesEvent>(_onSeleccionarTodos);
    on<DeseleccionarTodosProductosEvent>(_onDeseleccionarTodos);
    on<LimpiarMensajeUbicacionEvent>(_onLimpiarMensaje);
  }

  void _onInicializado(
    LocationInfoInicializado event,
    Emitter<LocationInfoState> emit,
  ) {
    final ordenados = _filtrarYOrdenar(
      event.ubicacion.productos,
      query: '',
      criterio: state.criterioOrden,
      ascendente: state.ordenAscendente,
    );

    emit(state.copyWith(
      status: LocationInfoStatus.ready,
      ubicacion: () => event.ubicacion,
      productosFiltrados: ordenados,
      queryFiltro: '',
      isEditing: false,
      isSaving: false,
      modoSeleccionMasiva: false,
      productosSeleccionados: const [],
      mensajeError: () => null,
      mensajeExito: () => null,
      failure: () => null,
    ));
  }

  void _onBuscarProductos(
    BuscarProductosUbicacionEvent event,
    Emitter<LocationInfoState> emit,
  ) {
    final ubicacion = state.ubicacion;
    if (ubicacion == null) return;

    final filtrados = _filtrarYOrdenar(
      ubicacion.productos,
      query: event.query,
      criterio: state.criterioOrden,
      ascendente: state.ordenAscendente,
    );

    emit(state.copyWith(
      productosFiltrados: filtrados,
      queryFiltro: event.query,
    ));
  }

  void _onOrdenarProductos(
    OrdenarProductosUbicacionEvent event,
    Emitter<LocationInfoState> emit,
  ) {
    final ubicacion = state.ubicacion;
    if (ubicacion == null) return;

    final ordenados = _filtrarYOrdenar(
      ubicacion.productos,
      query: state.queryFiltro,
      criterio: event.criterio,
      ascendente: event.ascendente,
    );

    emit(state.copyWith(
      productosFiltrados: ordenados,
      criterioOrden: event.criterio,
      ordenAscendente: event.ascendente,
    ));
  }

  void _onToggleModoEdicion(
    ToggleModoEdicionUbicacionEvent event,
    Emitter<LocationInfoState> emit,
  ) {
    emit(state.copyWith(
      isEditing: event.isEditing,
      mensajeError: () => null,
      mensajeExito: () => null,
    ));
  }

  Future<void> _onGuardarEdicion(
    GuardarEdicionUbicacionEvent event,
    Emitter<LocationInfoState> emit,
  ) async {
    final ubicacion = state.ubicacion;
    if (ubicacion == null) return;

    emit(state.copyWith(
      isSaving: true,
      mensajeError: () => null,
      mensajeExito: () => null,
      failure: () => null,
    ));

    final params = ActualizarUbicacionParams(
      locationId: ubicacion.id,
      name: event.nombre.trim(),
      barcode: event.barcode.trim(),
    );

    final result = await actualizarUbicacion(params);

    result.match(
      (failure) {
        emit(state.copyWith(
          isSaving: false,
          mensajeError: () => failure.message,
          failure: () => failure,
        ));
      },
      (ubicacionActualizada) {
        final nuevosProductos = _filtrarYOrdenar(
          ubicacionActualizada.productos,
          query: state.queryFiltro,
          criterio: state.criterioOrden,
          ascendente: state.ordenAscendente,
        );

        emit(state.copyWith(
          isSaving: false,
          isEditing: false,
          ubicacion: () => ubicacionActualizada,
          productosFiltrados: nuevosProductos,
          mensajeExito: () => 'Ubicación actualizada exitosamente',
          mensajeError: () => null,
          failure: () => null,
        ));
      },
    );
  }

  void _onToggleModoSeleccionMasiva(
    ToggleModoSeleccionMasivaEvent event,
    Emitter<LocationInfoState> emit,
  ) {
    emit(state.copyWith(
      modoSeleccionMasiva: event.activar,
      productosSeleccionados: event.activar ? state.productosSeleccionados : const [],
      mensajeError: () => null,
      mensajeExito: () => null,
    ));
  }

  void _onToggleProductoSeleccionado(
    ToggleProductoSeleccionadoEvent event,
    Emitter<LocationInfoState> emit,
  ) {
    final seleccionados = List<ProductoUbicacion>.from(state.productosSeleccionados);

    if (event.seleccionado) {
      final keyNuevo = PropietarioRules.normalizeKey(
        tieneManejoPropietario: event.producto.manejoPropietario,
        propietario: event.producto.propietario,
      );

      if (seleccionados.isNotEmpty) {
        final keyExistente = state.propietarioActivoKey;
        final errorMsg = PropietarioRules.validarCompatibilidad(
          keyExistente: keyExistente,
          keyNuevo: keyNuevo,
        );

        if (errorMsg != null) {
          emit(state.copyWith(
            mensajeError: () => errorMsg,
            failure: () => PropietarioMismatchFailure(errorMsg),
          ));
          return;
        }
      }

      final yaExiste = seleccionados.any((p) =>
          p.id == event.producto.id && p.loteId == event.producto.loteId);
      if (!yaExiste) {
        seleccionados.add(event.producto);
      }
    } else {
      seleccionados.removeWhere((p) =>
          p.id == event.producto.id && p.loteId == event.producto.loteId);
    }

    emit(state.copyWith(
      productosSeleccionados: seleccionados,
      mensajeError: () => null,
      failure: () => null,
    ));
  }

  void _onSeleccionarTodos(
    SeleccionarTodosProductosDisponiblesEvent event,
    Emitter<LocationInfoState> emit,
  ) {
    final ubicacion = state.ubicacion;
    if (ubicacion == null) return;

    // Igual que el legacy: solo se pueden transferir los que no están en un
    // paquete y tienen cantidad a la mano.
    final disponibles =
        ubicacion.productos.where(esDisponibleParaMasiva).toList();
    if (disponibles.isEmpty) return;

    final String? keyObjetivo;
    if (state.productosSeleccionados.isNotEmpty) {
      keyObjetivo = state.propietarioActivoKey;
    } else {
      final primer = disponibles.first;
      keyObjetivo = PropietarioRules.normalizeKey(
        tieneManejoPropietario: primer.manejoPropietario,
        propietario: primer.propietario,
      );
    }

    final seleccionados = <ProductoUbicacion>[];
    int omitidosPorPropietario = 0;

    for (final prod in disponibles) {
      final prodKey = PropietarioRules.normalizeKey(
        tieneManejoPropietario: prod.manejoPropietario,
        propietario: prod.propietario,
      );

      if (PropietarioRules.sonCompatibles(keyObjetivo, prodKey)) {
        seleccionados.add(prod);
      } else {
        omitidosPorPropietario++;
      }
    }

    String? aviso;
    if (omitidosPorPropietario > 0) {
      aviso = 'Se seleccionaron ${seleccionados.length} productos. '
          '$omitidosPorPropietario fueron omitidos por pertenecer a otro propietario.';
    }

    emit(state.copyWith(
      productosSeleccionados: seleccionados,
      mensajeError: () => aviso,
    ));
  }

  void _onDeseleccionarTodos(
    DeseleccionarTodosProductosEvent event,
    Emitter<LocationInfoState> emit,
  ) {
    emit(state.copyWith(
      productosSeleccionados: const [],
      mensajeError: () => null,
      mensajeExito: () => null,
    ));
  }

  void _onLimpiarMensaje(
    LimpiarMensajeUbicacionEvent event,
    Emitter<LocationInfoState> emit,
  ) {
    emit(state.copyWith(
      mensajeExito: () => null,
      mensajeError: () => null,
      failure: () => null,
    ));
  }

  List<ProductoUbicacion> _filtrarYOrdenar(
    List<ProductoUbicacion> items, {
    required String query,
    required String criterio,
    required bool ascendente,
  }) {
    final cleanQuery = query.trim().toLowerCase();
    var filtrados = items;
    if (cleanQuery.isNotEmpty) {
      filtrados = items.where((p) {
        final matchesNombre = p.producto.toLowerCase().contains(cleanQuery);
        final matchesBarcode = p.codigoBarras.toLowerCase().contains(cleanQuery);
        final matchesLote = (p.lote ?? '').toLowerCase().contains(cleanQuery);
        return matchesNombre || matchesBarcode || matchesLote;
      }).toList();
    }

    final ordenados = List<ProductoUbicacion>.from(filtrados);
    ordenados.sort((a, b) {
      int comparison = 0;
      switch (criterio) {
        case 'name':
          comparison = a.producto.toLowerCase().compareTo(b.producto.toLowerCase());
        case 'cantidad':
          comparison = a.cantidad.compareTo(b.cantidad);
        case 'lote':
          comparison = (a.lote ?? '').toLowerCase().compareTo((b.lote ?? '').toLowerCase());
        default:
          comparison = a.producto.toLowerCase().compareTo(b.producto.toLowerCase());
      }
      return ascendente ? comparison : -comparison;
    });

    return ordenados;
  }
}
