part of 'catalog_search_bloc.dart';

sealed class CatalogSearchEvent extends Equatable {
  const CatalogSearchEvent();

  @override
  List<Object?> get props => [];
}

/// Carga el catálogo de productos desde la caché local o repositorio.
class CargarCatalogoProductosEvent extends CatalogSearchEvent {
  final bool forceRefresh;

  const CargarCatalogoProductosEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

/// Busca productos dentro del catálogo por nombre, código interno o códigos de barras.
class BuscarProductosCatalogoEvent extends CatalogSearchEvent {
  final String query;

  const BuscarProductosCatalogoEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Carga el catálogo de ubicaciones desde la caché local o repositorio.
class CargarCatalogoUbicacionesEvent extends CatalogSearchEvent {
  final bool forceRefresh;

  const CargarCatalogoUbicacionesEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

/// Busca ubicaciones dentro del catálogo por nombre o código de barras.
class BuscarUbicacionesCatalogoEvent extends CatalogSearchEvent {
  final String query;

  const BuscarUbicacionesCatalogoEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Filtra el catálogo de ubicaciones por el nombre del almacén seleccionado.
class FiltrarUbicacionesPorAlmacenEvent extends CatalogSearchEvent {
  final String? almacen;

  const FiltrarUbicacionesPorAlmacenEvent(this.almacen);

  @override
  List<Object?> get props => [almacen];
}
