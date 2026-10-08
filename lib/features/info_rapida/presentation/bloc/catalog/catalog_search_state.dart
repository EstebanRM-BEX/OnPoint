part of 'catalog_search_bloc.dart';

enum CatalogStatus { initial, loading, success, failure }

class CatalogSearchState extends Equatable {
  final CatalogStatus statusProductos;
  final CatalogStatus statusUbicaciones;
  final List<ProductoCatalogo> productos;
  final List<ProductoCatalogo> productosFiltrados;
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
    this.productos = const [],
    this.productosFiltrados = const [],
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
    List<ProductoCatalogo>? productos,
    List<ProductoCatalogo>? productosFiltrados,
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
      productos: productos ?? this.productos,
      productosFiltrados: productosFiltrados ?? this.productosFiltrados,
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
        productos,
        productosFiltrados,
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
