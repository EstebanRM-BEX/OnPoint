part of 'catalog_search_bloc.dart';

enum CatalogStatus { initial, loading, success, failure }

class CatalogSearchState extends Equatable {
  final CatalogStatus statusProductos;
  final CatalogStatus statusUbicaciones;
  /// Páginas de productos traídas de SQLite para la búsqueda actual.
  final List<ProductoCatalogo> productosFiltrados;
  final bool hayMasProductos;
  final String? propietarioProducto;
  final List<String> propietarios;
  final List<UbicacionCatalogo> ubicaciones;
  final List<UbicacionCatalogo> ubicacionesFiltradas;
  final String queryProducto;
  final String queryUbicacion;
  final String? almacenUbicacionesFiltro;
  final List<String> almacenesDisponibles;
  final String? mensajeErrorProductos;
  final String? mensajeErrorUbicaciones;
  final Failure? failureProductos;
  final Failure? failureUbicaciones;

  const CatalogSearchState({
    this.statusProductos = CatalogStatus.initial,
    this.statusUbicaciones = CatalogStatus.initial,
    this.productosFiltrados = const [],
    this.hayMasProductos = false,
    this.propietarioProducto,
    this.propietarios = const [],
    this.ubicaciones = const [],
    this.ubicacionesFiltradas = const [],
    this.queryProducto = '',
    this.queryUbicacion = '',
    this.almacenUbicacionesFiltro,
    this.almacenesDisponibles = const [],
    this.mensajeErrorProductos,
    this.mensajeErrorUbicaciones,
    this.failureProductos,
    this.failureUbicaciones,
  });

  bool get isLoadingProductos => statusProductos == CatalogStatus.loading;
  bool get isLoadingUbicaciones => statusUbicaciones == CatalogStatus.loading;

  CatalogSearchState copyWith({
    CatalogStatus? statusProductos,
    CatalogStatus? statusUbicaciones,
    List<ProductoCatalogo>? productosFiltrados,
    bool? hayMasProductos,
    String? Function()? propietarioProducto,
    List<String>? propietarios,
    List<UbicacionCatalogo>? ubicaciones,
    List<UbicacionCatalogo>? ubicacionesFiltradas,
    String? queryProducto,
    String? queryUbicacion,
    String? Function()? almacenUbicacionesFiltro,
    List<String>? almacenesDisponibles,
    String? Function()? mensajeErrorProductos,
    String? Function()? mensajeErrorUbicaciones,
    Failure? Function()? failureProductos,
    Failure? Function()? failureUbicaciones,
  }) {
    return CatalogSearchState(
      statusProductos: statusProductos ?? this.statusProductos,
      statusUbicaciones: statusUbicaciones ?? this.statusUbicaciones,
      productosFiltrados: productosFiltrados ?? this.productosFiltrados,
      hayMasProductos: hayMasProductos ?? this.hayMasProductos,
      propietarioProducto: propietarioProducto != null
          ? propietarioProducto()
          : this.propietarioProducto,
      propietarios: propietarios ?? this.propietarios,
      ubicaciones: ubicaciones ?? this.ubicaciones,
      ubicacionesFiltradas: ubicacionesFiltradas ?? this.ubicacionesFiltradas,
      queryProducto: queryProducto ?? this.queryProducto,
      queryUbicacion: queryUbicacion ?? this.queryUbicacion,
      almacenUbicacionesFiltro: almacenUbicacionesFiltro != null
          ? almacenUbicacionesFiltro()
          : this.almacenUbicacionesFiltro,
      almacenesDisponibles: almacenesDisponibles ?? this.almacenesDisponibles,
      mensajeErrorProductos: mensajeErrorProductos != null
          ? mensajeErrorProductos()
          : this.mensajeErrorProductos,
      mensajeErrorUbicaciones: mensajeErrorUbicaciones != null
          ? mensajeErrorUbicaciones()
          : this.mensajeErrorUbicaciones,
      failureProductos: failureProductos != null
          ? failureProductos()
          : this.failureProductos,
      failureUbicaciones: failureUbicaciones != null
          ? failureUbicaciones()
          : this.failureUbicaciones,
    );
  }

  @override
  List<Object?> get props => [
        statusProductos,
        statusUbicaciones,
        productosFiltrados,
        hayMasProductos,
        propietarioProducto,
        propietarios,
        ubicaciones,
        ubicacionesFiltradas,
        queryProducto,
        queryUbicacion,
        almacenUbicacionesFiltro,
        almacenesDisponibles,
        mensajeErrorProductos,
        mensajeErrorUbicaciones,
        failureProductos,
        failureUbicaciones,
      ];
}
