import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:wms_app/core/bloc/safe_bloc_mixin.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/info_rapida/domain/entities/catalogo_info.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/get_catalogo_productos_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/get_catalogo_ubicaciones_usecase.dart';

part 'catalog_search_event.dart';
part 'catalog_search_state.dart';

@injectable
class CatalogSearchBloc
    extends Bloc<CatalogSearchEvent, CatalogSearchState>
    with SafeBlocMixin<CatalogSearchEvent, CatalogSearchState> {
  final GetCatalogoProductosUseCase getCatalogoProductos;
  final GetCatalogoUbicacionesUseCase getCatalogoUbicaciones;

  CatalogSearchBloc({
    required this.getCatalogoProductos,
    required this.getCatalogoUbicaciones,
  }) : super(const CatalogSearchState()) {
    on<CargarCatalogoProductosEvent>(_onCargarProductos);
    on<BuscarProductosCatalogoEvent>(
      _onBuscarProductos,
      transformer: restartable(),
    );
    on<CargarCatalogoUbicacionesEvent>(_onCargarUbicaciones);
    on<BuscarUbicacionesCatalogoEvent>(
      _onBuscarUbicaciones,
      transformer: restartable(),
    );
    on<FiltrarUbicacionesPorAlmacenEvent>(
      _onFiltrarUbicacionesPorAlmacen,
      transformer: restartable(),
    );
  }

  Future<void> _onCargarProductos(
    CargarCatalogoProductosEvent event,
    Emitter<CatalogSearchState> emit,
  ) async {
    emit(state.copyWith(
      statusProductos: CatalogStatus.loading,
      mensajeErrorProductos: () => null,
      failureProductos: () => null,
    ));

    final result = await getCatalogoProductos(
      GetCatalogoProductosParams(forceRefresh: event.forceRefresh),
    );

    result.match(
      (failure) {
        emit(state.copyWith(
          statusProductos: CatalogStatus.failure,
          mensajeErrorProductos: () => failure.message,
          failureProductos: () => failure,
        ));
      },
      (productos) {
        final filtrados = _filtrarProductos(productos, state.queryProducto);
        emit(state.copyWith(
          statusProductos: CatalogStatus.success,
          productos: productos,
          productosFiltrados: filtrados,
          mensajeErrorProductos: () => null,
          failureProductos: () => null,
        ));
      },
    );
  }

  void _onBuscarProductos(
    BuscarProductosCatalogoEvent event,
    Emitter<CatalogSearchState> emit,
  ) {
    final filtrados = _filtrarProductos(state.productos, event.query);
    emit(state.copyWith(
      queryProducto: event.query,
      productosFiltrados: filtrados,
    ));
  }

  Future<void> _onCargarUbicaciones(
    CargarCatalogoUbicacionesEvent event,
    Emitter<CatalogSearchState> emit,
  ) async {
    emit(state.copyWith(
      statusUbicaciones: CatalogStatus.loading,
      mensajeErrorUbicaciones: () => null,
      failureUbicaciones: () => null,
    ));

    final result = await getCatalogoUbicaciones(
      GetCatalogoUbicacionesParams(forceRefresh: event.forceRefresh),
    );

    result.match(
      (failure) {
        emit(state.copyWith(
          statusUbicaciones: CatalogStatus.failure,
          mensajeErrorUbicaciones: () => failure.message,
          failureUbicaciones: () => failure,
        ));
      },
      (ubicaciones) {
        final almacenes = ubicaciones
            .map((u) => u.warehouseName?.trim())
            .where((w) => w != null && w.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList()
          ..sort();

        final filtradas = _filtrarUbicaciones(
          ubicaciones,
          query: state.queryUbicacion,
          almacen: state.almacenUbicacionesFiltro,
        );

        emit(state.copyWith(
          statusUbicaciones: CatalogStatus.success,
          ubicaciones: ubicaciones,
          ubicacionesFiltradas: filtradas,
          almacenesDisponibles: almacenes,
          mensajeErrorUbicaciones: () => null,
          failureUbicaciones: () => null,
        ));
      },
    );
  }

  void _onBuscarUbicaciones(
    BuscarUbicacionesCatalogoEvent event,
    Emitter<CatalogSearchState> emit,
  ) {
    final filtradas = _filtrarUbicaciones(
      state.ubicaciones,
      query: event.query,
      almacen: state.almacenUbicacionesFiltro,
    );

    emit(state.copyWith(
      queryUbicacion: event.query,
      ubicacionesFiltradas: filtradas,
    ));
  }

  void _onFiltrarUbicacionesPorAlmacen(
    FiltrarUbicacionesPorAlmacenEvent event,
    Emitter<CatalogSearchState> emit,
  ) {
    final filtradas = _filtrarUbicaciones(
      state.ubicaciones,
      query: state.queryUbicacion,
      almacen: event.almacen,
    );

    emit(state.copyWith(
      almacenUbicacionesFiltro: () => event.almacen,
      ubicacionesFiltradas: filtradas,
    ));
  }

  List<ProductoCatalogo> _filtrarProductos(
    List<ProductoCatalogo> items,
    String query,
  ) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return items;

    return items.where((p) {
      final matchesName = p.name.toLowerCase().contains(clean);
      final matchesCode = (p.code ?? '').toLowerCase().contains(clean);
      final matchesBarcode = (p.barcode ?? '').toLowerCase().contains(clean);
      final matchesOther = p.otherBarcodes.any((b) => b.toLowerCase().contains(clean));
      return matchesName || matchesCode || matchesBarcode || matchesOther;
    }).toList();
  }

  List<UbicacionCatalogo> _filtrarUbicaciones(
    List<UbicacionCatalogo> items, {
    required String query,
    required String? almacen,
  }) {
    var resultado = items;

    if (almacen != null && almacen.trim().isNotEmpty) {
      final cleanAlmacen = almacen.trim().toLowerCase();
      resultado = resultado.where((u) {
        return (u.warehouseName ?? '').trim().toLowerCase() == cleanAlmacen;
      }).toList();
    }

    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isNotEmpty) {
      resultado = resultado.where((u) {
        final matchesName = u.name.toLowerCase().contains(cleanQuery);
        final matchesBarcode = (u.barcode ?? '').toLowerCase().contains(cleanQuery);
        return matchesName || matchesBarcode;
      }).toList();
    }

    return resultado;
  }
}
