part of 'location_info_bloc.dart';

enum LocationInfoStatus { initial, ready, failure }

class LocationInfoState extends Equatable {
  final LocationInfoStatus status;
  final UbicacionInfo? ubicacion;
  final List<ProductoUbicacion> productosFiltrados;
  final String queryFiltro;
  final String criterioOrden; // 'name', 'cantidad', 'lote'
  final bool ordenAscendente;
  final bool isEditing;
  final bool isSaving;
  final bool modoSeleccionMasiva;
  final List<ProductoUbicacion> productosSeleccionados;
  final String? mensajeExito;
  final String? mensajeError;
  final Failure? failure;

  const LocationInfoState({
    this.status = LocationInfoStatus.initial,
    this.ubicacion,
    this.productosFiltrados = const [],
    this.queryFiltro = '',
    this.criterioOrden = 'name',
    this.ordenAscendente = true,
    this.isEditing = false,
    this.isSaving = false,
    this.modoSeleccionMasiva = false,
    this.productosSeleccionados = const [],
    this.mensajeExito,
    this.mensajeError,
    this.failure,
  });

  bool get isReady => status == LocationInfoStatus.ready && ubicacion != null;
  int get totalProductos => ubicacion?.productos.length ?? 0;
  int get totalSeleccionados => productosSeleccionados.length;

  /// Productos que entran en "Seleccionar todos": disponibles para la masiva
  /// y del mismo propietario que la selección actual (o que el primer
  /// disponible si no hay nada seleccionado). Igual que el legacy.
  List<ProductoUbicacion> get compatiblesSeleccionTodos {
    final disponibles = (ubicacion?.productos ?? const <ProductoUbicacion>[])
        .where(esDisponibleParaMasiva)
        .toList();
    if (disponibles.isEmpty) return const [];

    final keyObjetivo = productosSeleccionados.isNotEmpty
        ? propietarioActivoKey
        : PropietarioRules.normalizeKey(
            tieneManejoPropietario: disponibles.first.manejoPropietario,
            propietario: disponibles.first.propietario,
          );

    return disponibles
        .where((p) => PropietarioRules.sonCompatibles(
              keyObjetivo,
              PropietarioRules.normalizeKey(
                tieneManejoPropietario: p.manejoPropietario,
                propietario: p.propietario,
              ),
            ))
        .toList();
  }

  bool estaSeleccionado(ProductoUbicacion p) => productosSeleccionados
      .any((s) => s.id == p.id && s.loteId == p.loteId);

  /// `true` si "Seleccionar todos" ya está aplicado: el botón pasa a
  /// deseleccionar.
  bool get todosCompatiblesSeleccionados {
    final compatibles = compatiblesSeleccionTodos;
    return compatibles.isNotEmpty && compatibles.every(estaSeleccionado);
  }

  /// Retorna la clave canónica del propietario de los productos seleccionados actualmente,
  /// o null si no hay ninguno seleccionado o todos son sin propietario.
  String? get propietarioActivoKey {
    if (productosSeleccionados.isEmpty) return null;
    final first = productosSeleccionados.first;
    return PropietarioRules.normalizeKey(
      tieneManejoPropietario: first.manejoPropietario,
      propietario: first.propietario,
    );
  }

  LocationInfoState copyWith({
    LocationInfoStatus? status,
    UbicacionInfo? Function()? ubicacion,
    List<ProductoUbicacion>? productosFiltrados,
    String? queryFiltro,
    String? criterioOrden,
    bool? ordenAscendente,
    bool? isEditing,
    bool? isSaving,
    bool? modoSeleccionMasiva,
    List<ProductoUbicacion>? productosSeleccionados,
    String? Function()? mensajeExito,
    String? Function()? mensajeError,
    Failure? Function()? failure,
  }) {
    return LocationInfoState(
      status: status ?? this.status,
      ubicacion: ubicacion != null ? ubicacion() : this.ubicacion,
      productosFiltrados: productosFiltrados ?? productosFiltradas,
      queryFiltro: queryFiltro ?? this.queryFiltro,
      criterioOrden: criterioOrden ?? this.criterioOrden,
      ordenAscendente: ordenAscendente ?? this.ordenAscendente,
      isEditing: isEditing ?? this.isEditing,
      isSaving: isSaving ?? this.isSaving,
      modoSeleccionMasiva: modoSeleccionMasiva ?? this.modoSeleccionMasiva,
      productosSeleccionados:
          productosSeleccionados ?? this.productosSeleccionados,
      mensajeExito: mensajeExito != null ? mensajeExito() : this.mensajeExito,
      mensajeError: mensajeError != null ? mensajeError() : this.mensajeError,
      failure: failure != null ? failure() : this.failure,
    );
  }

  // Helper typo guard:
  List<ProductoUbicacion> get productosFiltradas => productosFiltrados;

  @override
  List<Object?> get props => [
        status,
        ubicacion,
        productosFiltrados,
        queryFiltro,
        criterioOrden,
        ordenAscendente,
        isEditing,
        isSaving,
        modoSeleccionMasiva,
        productosSeleccionados,
        mensajeExito,
        mensajeError,
        failure,
      ];
}
