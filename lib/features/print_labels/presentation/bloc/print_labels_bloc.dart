import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/material.dart';
import 'package:wms_app/core/bloc/safe_bloc_mixin.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/features/print_labels/data/models/product_label.dart';
import 'package:wms_app/features/user/data/models/user_configuration_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_ubicaciones/paginador_ubicaciones.dart';
import 'package:wms_app/core/services/configuracion_cache_service.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/injection_container.dart';

part 'print_labels_event.dart';
part 'print_labels_state.dart';

class PrintLabelsBloc extends Bloc<PrintLabelsEvent, PrintLabelsState>
    with SafeBlocMixin<PrintLabelsEvent, PrintLabelsState> {
  /// Ubicaciones de la búsqueda: páginas de una consulta a SQLite ordenadas
  /// por nombre (hasta ~19 mil por cliente; ya no se cargan completas en
  /// memoria). Ver docs/plan_ubicaciones_sqlite.md.
  late final PaginadorUbicaciones paginadorUbicaciones =
      PaginadorUbicaciones(() => db.ubicacionesRepository);
  List<ResultUbicaciones> get ubicacionesFilters => paginadorUbicaciones.items;
  bool get hayMasUbicaciones => paginadorUbicaciones.hayMas;

  /// Hay ubicaciones descargadas (lo confirma [GetListLocationsEvent]).
  bool hayUbicaciones = false;

  /// Tope del rango de etiquetas: un rango amplio puede abarcar miles de
  /// ubicaciones.
  static const topeRango = 1000;

  /// El último rango llegó al tope: hay más ubicaciones que no se muestran.
  bool rangoEnTope = false;
  /// Productos visibles: páginas de una consulta a SQLite. El catálogo
  /// completo (~24 mil productos) ya no se carga en memoria (ver
  /// docs/plan_fix_oom_catalogo_productos.md).
  List<ProductLabel> productosFilters = [];
  bool hayMasProductos = false;

  /// Hay catálogo descargado (lo confirma [GetProductsList]).
  bool hayCatalogo = false;
  static const _paginaProductos = 50;
  String _queryProductos = '';
  // Sube con cada búsqueda nueva: una página que llega tarde no se mezcla
  // con los resultados de otra búsqueda.
  int _busquedaProductos = 0;
  UserConfigurationModel configurations = UserConfigurationModel();

  TextEditingController searchControllerLocation = TextEditingController();
  TextEditingController searchControllerProducts = TextEditingController();
  TextEditingController rangeStartController = TextEditingController();
  TextEditingController rangeEndController = TextEditingController();

  List<ResultUbicaciones> ubicacionesRange = [];

  /// Cantidad de etiquetas por ubicación del rango: locationId → cantidad.
  /// Si no hay entrada, se asume 1. Se repite el id en `active_ids` al enviar.
  final Map<int, int> locationQuantities = {};

  /// Ids de ubicaciones expandidos según su cantidad (mín 1 por ubicación),
  /// preservando el orden de `ubicacionesRange`.
  List<int> get expandedLocationResIds => [
        for (final loc in ubicacionesRange)
          if (loc.id != null)
            for (int i = 0; i < (locationQuantities[loc.id] ?? 1); i++) loc.id!,
      ];

  /// Productos seleccionados para imprimir: productId → cantidad de etiquetas.
  /// El `Map` da membresía O(1) por id y guarda cuántas veces se debe imprimir
  /// cada producto (se repite el id en `active_ids` al enviar).
  final Map<int, int> selectedProducts = {};

  /// Lista de ids expandida según la cantidad de cada producto:
  /// {21558: 3} → [21558, 21558, 21558]. Es lo que viaja como `active_ids`.
  List<int> get expandedResIds => [
        for (final e in selectedProducts.entries)
          for (int i = 0; i < e.value; i++) e.key,
      ];

  DataBaseSqlite db = DataBaseSqlite();

  PrintLabelsBloc() : super(PrintLabelsInitial()) {
    on<GetListLocationsEvent>(_onLoadLocations);
    on<GetProductsList>(_onGetProductsBD);
    on<LoadConfigurationsUserInfo>(_onLoadConfigurationsUserEvent);
    // restartable: cada tecla cancela la búsqueda anterior (debounce en el
    // handler).
    on<SearchLocationEvent>(
      _onSearchLocationEvent,
      transformer: restartable(),
    );
    on<LoadMoreLocationsEvent>(
      _onLoadMoreLocations,
      transformer: droppable(),
    );
    // restartable: si llega otra búsqueda, se descarta la anterior.
    on<SearchProductEvent>(_onSearchProductEvent, transformer: restartable());
    on<LoadMoreProductsEvent>(
      _onLoadMoreProductsEvent,
      transformer: droppable(),
    );
    on<SearchRangeLocationEvent>(
      _onSearchRangeLocationEvent,
      transformer: restartable(),
    );
    on<RemoveRangeLocationEvent>(_onRemoveRangeLocationEvent);
    on<AddRangeLocationEvent>(_onAddRangeLocationEvent);
    on<AddSelectedProductEvent>(_onAddSelectedProductEvent);
    on<RemoveSelectedProductEvent>(_onRemoveSelectedProductEvent);
    on<IncrementProductQtyEvent>(_onIncrementProductQty);
    on<DecrementProductQtyEvent>(_onDecrementProductQty);
    on<IncrementLocationQtyEvent>(_onIncrementLocationQty);
    on<DecrementLocationQtyEvent>(_onDecrementLocationQty);
    on<ClearSelectedProductsEvent>(_onClearSelectedProducts);
    on<ClearRangeLocationsEvent>(_onClearRangeLocations);
  }

  // ── Ciclo de vida ────────────────────────────────────────────────────────
  // Cada pantalla del módulo se registra con [attachScope]/[detachScope]
  // (PrintLabelsScope). La navegación interna es por pushReplacementNamed (la
  // siguiente pantalla se monta mientras la anterior se descarta), así que el
  // bloc se cierra solo cuando ya no queda ninguna, tras un breve margen. La
  // selección de etiquetas no se conserva al salir del módulo.
  int _scopeRefs = 0;

  void attachScope() => _scopeRefs++;

  void detachScope() {
    _scopeRefs--;
    if (_scopeRefs > 0) return;
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      // isClosing (no isClosed): en bloc 9.2.0 isClosed sigue en false
      // mientras close() termina, y un segundo close() volvería a hacer
      // dispose de los controllers.
      if (_scopeRefs <= 0 && !isClosing) close();
    });
  }

  @override
  Future<void> close() {
    searchControllerLocation.dispose();
    searchControllerProducts.dispose();
    rangeStartController.dispose();
    rangeEndController.dispose();
    return super.close();
  }

  /// Primera página de ubicaciones (ordenadas por nombre). Vacía = no hay
  /// ubicaciones descargadas.
  Future<void> _onLoadLocations(
      GetListLocationsEvent event, Emitter<PrintLabelsState> emit) async {
    try {
      emit(LoadLocationsLoading());
      await paginadorUbicaciones.buscar();
      hayUbicaciones = ubicacionesFilters.isNotEmpty;
      if (hayUbicaciones) {
        emit(LoadLocationsSuccess(ubicacionesFilters));
      } else {
        emit(LoadLocationsFailure('No se encontraron ubicaciones'));
      }
    } catch (e, s) {
      emit(LoadLocationsFailure('Error al cargar las ubicaciones'));
      debugPrint('Error en el fetch de ubicaciones: $e=>$s');
    }
  }

  Future<void> _onLoadMoreLocations(
      LoadMoreLocationsEvent event, Emitter<PrintLabelsState> emit) async {
    try {
      if (await paginadorUbicaciones.cargarMas()) {
        emit(SearchLocationSuccess(ubicacionesFilters));
      }
    } catch (e, s) {
      debugPrint('Error en LoadMoreLocationsEvent: $e=>$s');
    }
  }

  Future<List<ProductLabel>> _paginaDeProductos(String query, int offset) async {
    final rows = await db.productoInventarioRepository.buscarEtiquetas(
      query: query,
      limit: _paginaProductos,
      offset: offset,
    );
    return rows.map(ProductLabel.fromMap).toList();
  }

  /// Primera página del listado (sin búsqueda). Si viene vacía, no hay
  /// catálogo descargado.
  Future<void> _onGetProductsBD(
      GetProductsList event, Emitter<PrintLabelsState> emit) async {
    try {
      emit(GetProductsLoading());
      final busqueda = ++_busquedaProductos;
      final pagina = await _paginaDeProductos('', 0);
      if (busqueda != _busquedaProductos) return;
      _queryProductos = '';
      productosFilters = pagina;
      hayMasProductos = pagina.length == _paginaProductos;
      hayCatalogo = pagina.isNotEmpty;
      if (hayCatalogo) {
        emit(GetProductsSuccess(productosFilters));
      } else {
        emit(GetProductsFailure('No se encontraron productos'));
      }
    } catch (e, s) {
      emit(GetProductsFailure('Error al cargar los productos'));
      debugPrint('Error en el fetch de productos: $e=>$s');
    }
  }

  Future<void> _onLoadConfigurationsUserEvent(
      LoadConfigurationsUserInfo event, Emitter<PrintLabelsState> emit) async {
    try {
      int userId = await PrefUtils.getUserId();
      final response =
          await getIt<ConfiguracionCacheService>().getConfiguration(userId);

      if (response != null) {
        configurations = response;
        emit(ConfigurationLoadedPrintLabels(response));
      } else {
        emit(ConfigurationError('Error al cargar configuraciones'));
      }
    } catch (e, s) {
      emit(ConfigurationError(e.toString()));
      debugPrint('Error LoadConfigurationsUserPack: $e =>$s');
    }
  }

  Future<void> _onSearchLocationEvent(
      SearchLocationEvent event, Emitter<PrintLabelsState> emit) async {
    // Debounce: si llega otra tecla, restartable cierra este emitter.
    if (event.query.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (emit.isDone) return;
    }
    if (await paginadorUbicaciones.buscar(query: event.query) &&
        !emit.isDone) {
      emit(SearchLocationSuccess(ubicacionesFilters));
    }
  }

  Future<void> _onSearchProductEvent(
      SearchProductEvent event, Emitter<PrintLabelsState> emit) async {
    // La pantalla ya espera 200 ms tras la última tecla antes de buscar.
    final busqueda = ++_busquedaProductos;
    try {
      final pagina = await _paginaDeProductos(event.query, 0);
      if (emit.isDone || busqueda != _busquedaProductos) return;
      _queryProductos = event.query;
      productosFilters = pagina;
      hayMasProductos = pagina.length == _paginaProductos;
      emit(SearchProductSuccess(productosFilters));
    } catch (e, s) {
      debugPrint('Error en SearchProductEvent: $e=>$s');
    }
  }

  Future<void> _onLoadMoreProductsEvent(
      LoadMoreProductsEvent event, Emitter<PrintLabelsState> emit) async {
    if (!hayMasProductos) return;
    final busqueda = _busquedaProductos;
    try {
      final pagina = await _paginaDeProductos(
        _queryProductos,
        productosFilters.length,
      );
      if (busqueda != _busquedaProductos) return;
      productosFilters = [...productosFilters, ...pagina];
      hayMasProductos = pagina.length == _paginaProductos;
      emit(SearchProductSuccess(productosFilters));
    } catch (e, s) {
      debugPrint('Error en LoadMoreProductsEvent: $e=>$s');
    }
  }

  /// Rango por nombre en SQLite, sin distinguir mayúsculas: sin fin, las
  /// que empiezan con el inicio; con fin, las que están entre ambos. Acotado
  /// a [topeRango] ([rangoEnTope] avisa que hay más).
  Future<void> _onSearchRangeLocationEvent(
      SearchRangeLocationEvent event, Emitter<PrintLabelsState> emit) async {
    //nueva búsqueda de rango reemplaza la lista: limpiamos cantidades previas
    locationQuantities.clear();
    final rango = await db.ubicacionesRepository.rango(
      desde: event.start,
      hasta: event.end,
      limit: topeRango,
    );
    if (emit.isDone) return;
    ubicacionesRange = rango;
    rangoEnTope = rango.length == topeRango;
    emit(SearchRangeLocationSuccess(ubicacionesRange));
  }

  void _onRemoveRangeLocationEvent(
      RemoveRangeLocationEvent event, Emitter<PrintLabelsState> emit) {
    ubicacionesRange =
        ubicacionesRange.where((l) => l.id != event.locationId).toList();
    locationQuantities.remove(event.locationId);
    emit(SearchRangeLocationSuccess(ubicacionesRange));
  }

  void _onIncrementLocationQty(
      IncrementLocationQtyEvent event, Emitter<PrintLabelsState> emit) {
    final actual = locationQuantities[event.locationId] ?? 1;
    locationQuantities[event.locationId] = actual + 1;
    emit(SearchRangeLocationSuccess(ubicacionesRange));
  }

  void _onDecrementLocationQty(
      DecrementLocationQtyEvent event, Emitter<PrintLabelsState> emit) {
    //mínimo 1: el stepper no elimina la ubicación (eso lo hace la X)
    final actual = locationQuantities[event.locationId] ?? 1;
    if (actual > 1) {
      locationQuantities[event.locationId] = actual - 1;
    }
    emit(SearchRangeLocationSuccess(ubicacionesRange));
  }

  void _onAddRangeLocationEvent(
      AddRangeLocationEvent event, Emitter<PrintLabelsState> emit) {
    final alreadyAdded = ubicacionesRange.any((l) => l.id == event.location.id);
    if (!alreadyAdded) {
      ubicacionesRange = [...ubicacionesRange, event.location];
      ubicacionesRange.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
    }
    emit(SearchRangeLocationSuccess(ubicacionesRange));
  }

  void _onAddSelectedProductEvent(
      AddSelectedProductEvent event, Emitter<PrintLabelsState> emit) {
    //al seleccionar arranca en 1 etiqueta
    selectedProducts[event.productId] = 1;
    emit(SearchProductSuccess(productosFilters));
  }

  void _onRemoveSelectedProductEvent(
      RemoveSelectedProductEvent event, Emitter<PrintLabelsState> emit) {
    selectedProducts.remove(event.productId);
    emit(SearchProductSuccess(productosFilters));
  }

  void _onIncrementProductQty(
      IncrementProductQtyEvent event, Emitter<PrintLabelsState> emit) {
    final actual = selectedProducts[event.productId] ?? 0;
    selectedProducts[event.productId] = actual + 1;
    emit(SearchProductSuccess(productosFilters));
  }

  void _onDecrementProductQty(
      DecrementProductQtyEvent event, Emitter<PrintLabelsState> emit) {
    final actual = selectedProducts[event.productId] ?? 0;
    if (actual <= 1) {
      //mínimo 1: bajar de 1 deselecciona el producto
      selectedProducts.remove(event.productId);
    } else {
      selectedProducts[event.productId] = actual - 1;
    }
    emit(SearchProductSuccess(productosFilters));
  }

  void _onClearSelectedProducts(
      ClearSelectedProductsEvent event, Emitter<PrintLabelsState> emit) {
    selectedProducts.clear();
    emit(SearchProductSuccess(productosFilters));
  }

  void _onClearRangeLocations(
      ClearRangeLocationsEvent event, Emitter<PrintLabelsState> emit) {
    ubicacionesRange = [];
    rangoEnTope = false;
    locationQuantities.clear();
    emit(SearchRangeLocationSuccess(ubicacionesRange));
  }
}
