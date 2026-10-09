part of 'catalog_search_bloc.dart';

sealed class CatalogSearchEvent extends Equatable {
  const CatalogSearchEvent();

  @override
  List<Object?> get props => [];
}

/// Carga la primera página de productos (con la búsqueda y el propietario
/// actuales) y la lista de propietarios. También refresca la lista abierta.
class CargarCatalogoProductosEvent extends CatalogSearchEvent {
  const CargarCatalogoProductosEvent();
}

/// Busca productos por nombre, código interno o códigos de barras.
class BuscarProductosCatalogoEvent extends CatalogSearchEvent {
  final String query;

  const BuscarProductosCatalogoEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Filtra los productos por propietario (null = todos).
class FiltrarProductosPorPropietarioEvent extends CatalogSearchEvent {
  final String? propietario;

  const FiltrarProductosPorPropietarioEvent(this.propietario);

  @override
  List<Object?> get props => [propietario];
}

/// Siguiente página de productos para la búsqueda actual.
class CargarMasProductosCatalogoEvent extends CatalogSearchEvent {
  const CargarMasProductosCatalogoEvent();
}

/// Interno: consulta la primera página con el estado actual.
class _ConsultaProductosEvent extends CatalogSearchEvent {
  final bool cargarPropietarios;

  const _ConsultaProductosEvent({this.cargarPropietarios = false});

  @override
  List<Object?> get props => [cargarPropietarios];
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
