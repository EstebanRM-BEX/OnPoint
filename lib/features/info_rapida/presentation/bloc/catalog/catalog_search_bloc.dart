import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:wms_app/core/bloc/safe_bloc_mixin.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/info_rapida/domain/entities/catalogo_info.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/buscar_catalogo_productos_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/get_catalogo_ubicaciones_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/get_propietarios_catalogo_usecase.dart';

part 'catalog_search_event.dart';
part 'catalog_search_state.dart';

@injectable
class CatalogSearchBloc
    extends Bloc<CatalogSearchEvent, CatalogSearchState>
    with SafeBlocMixin<CatalogSearchEvent, CatalogSearchState> {
  final BuscarCatalogoProductosUseCase buscarCatalogoProductos;
  final GetPropietariosCatalogoUseCase getPropietariosCatalogo;
  final GetCatalogoUbicacionesUseCase getCatalogoUbicaciones;

  /// Productos por página: el catálogo (~72 mil) se consulta en SQLite de a
  /// páginas en vez de cargarse completo en memoria.
  static const int paginaProductos = 50;

  CatalogSearchBloc({
    required this.buscarCatalogoProductos,
    required this.getPropietariosCatalogo,
    required this.getCatalogoUbicaciones,
  }) : super(const CatalogSearchState()) {
    // Las tres reemplazan la primera página: la última pedida gana.
    on<_ConsultaProductosEvent>(_onConsultarProductos, transformer: restartable());
    on<CargarCatalogoProductosEvent>(
      (e, emit) => add(const _ConsultaProductosEvent(cargarPropietarios: true)),
    );
    on<BuscarProductosCatalogoEvent>((e, emit) {
      emit(state.copyWith(queryProducto: e.query));
      add(const _ConsultaProductosEvent());
    });
    on<FiltrarProductosPorPropietarioEvent>((e, emit) {
      emit(state.copyWith(propietarioProducto: () => e.propietario));
      add(const _ConsultaProductosEvent());
    });
    on<CargarMasProductosCatalogoEvent>(
      _onCargarMasProductos,
      transformer: droppable(),
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

  /// Si el catálogo ya está en memoria responde en unos milisegundos: en ese
  /// caso no se emite `loading` para que el "Cargando…" no parpadee al abrir
  /// la lista.
  static const _umbralLoading = Duration(milliseconds: 150);

  Future<bool> _terminaRapido(Future<Object?> carga) {
    return Future.any([
      carga.then((_) => true, onError: (_) => true),
      Future.delayed(_umbralLoading, () => false),
    ]);
  }

  /// Primera página con la búsqueda y el propietario actuales. Si ya había
  /// más cargadas (p. ej. al refrescar por WebSocket) trae la misma cantidad
  /// para no perder lo que el operario ya recorrió.
  Future<void> _onConsultarProductos(
    _ConsultaProductosEvent event,
    Emitter<CatalogSearchState> emit,
  ) async {
    final limit = state.productosFiltrados.length > paginaProductos
        ? state.productosFiltrados.length
        : paginaProductos;
    final carga = buscarCatalogoProductos(
      BuscarCatalogoProductosParams(
        query: state.queryProducto,
        propietario: state.propietarioProducto,
        limit: limit,
      ),
    );
    if (!await _terminaRapido(carga)) {
      emit(state.copyWith(
        statusProductos: CatalogStatus.loading,
        mensajeErrorProductos: () => null,
        failureProductos: () => null,
      ));
    }
    final result = await carga;

    result.match(
      (failure) {
        emit(state.copyWith(
          statusProductos: CatalogStatus.failure,
          mensajeErrorProductos: () => failure.message,
          failureProductos: () => failure,
        ));
      },
      (productos) {
        emit(state.copyWith(
          statusProductos: CatalogStatus.success,
          productosFiltrados: productos,
          hayMasProductos: productos.length == limit,
          mensajeErrorProductos: () => null,
          failureProductos: () => null,
        ));
      },
    );

    if (event.cargarPropietarios) {
      final propietarios = await getPropietariosCatalogo(NoParams());
      propietarios.match(
        (_) {},
        (lista) => emit(state.copyWith(propietarios: lista)),
      );
    }
  }

  Future<void> _onCargarMasProductos(
    CargarMasProductosCatalogoEvent event,
    Emitter<CatalogSearchState> emit,
  ) async {
    if (!state.hayMasProductos) return;
    final query = state.queryProducto;
    final propietario = state.propietarioProducto;
    final offset = state.productosFiltrados.length;
    final result = await buscarCatalogoProductos(
      BuscarCatalogoProductosParams(
        query: query,
        propietario: propietario,
        limit: paginaProductos,
        offset: offset,
      ),
    );
    // Si mientras tanto cambió la búsqueda, esta página ya no corresponde.
    if (query != state.queryProducto ||
        propietario != state.propietarioProducto ||
        offset != state.productosFiltrados.length) {
      return;
    }
    result.match(
      (failure) => emit(state.copyWith(
        mensajeErrorProductos: () => failure.message,
        failureProductos: () => failure,
      )),
      (pagina) => emit(state.copyWith(
        productosFiltrados: [...state.productosFiltrados, ...pagina],
        hayMasProductos: pagina.length == paginaProductos,
      )),
    );
  }

  Future<void> _onCargarUbicaciones(
    CargarCatalogoUbicacionesEvent event,
    Emitter<CatalogSearchState> emit,
  ) async {
    final carga = getCatalogoUbicaciones(
      GetCatalogoUbicacionesParams(forceRefresh: event.forceRefresh),
    );
    if (!await _terminaRapido(carga)) {
      emit(state.copyWith(
        statusUbicaciones: CatalogStatus.loading,
        mensajeErrorUbicaciones: () => null,
        failureUbicaciones: () => null,
      ));
    }
    final result = await carga;

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
