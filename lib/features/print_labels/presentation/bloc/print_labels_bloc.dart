import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/features/print_labels/data/models/product_label.dart';
import 'package:wms_app/features/user/data/models/user_configuration_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';

part 'print_labels_event.dart';
part 'print_labels_state.dart';

class PrintLabelsBloc extends Bloc<PrintLabelsEvent, PrintLabelsState> {
  List<ResultUbicaciones> ubicaciones = [];
  List<ResultUbicaciones> ubicacionesFilters = [];
  List<ProductLabel> productos = [];
  List<ProductLabel> productosFilters = [];
  UserConfigurationModel configurations = UserConfigurationModel();

  TextEditingController searchControllerLocation = TextEditingController();
  TextEditingController searchControllerProducts = TextEditingController();
  TextEditingController rangeStartController = TextEditingController();
  TextEditingController rangeEndController = TextEditingController();

  List<ResultUbicaciones> ubicacionesRange = [];

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
    on<SearchLocationEvent>(_onSearchLocationEvent);
    on<SearchProductEvent>(_onSearchProductEvent);
    on<SearchRangeLocationEvent>(_onSearchRangeLocationEvent);
    on<RemoveRangeLocationEvent>(_onRemoveRangeLocationEvent);
    on<AddRangeLocationEvent>(_onAddRangeLocationEvent);
    on<AddSelectedProductEvent>(_onAddSelectedProductEvent);
    on<RemoveSelectedProductEvent>(_onRemoveSelectedProductEvent);
    on<IncrementProductQtyEvent>(_onIncrementProductQty);
    on<DecrementProductQtyEvent>(_onDecrementProductQty);
    on<ClearSelectedProductsEvent>(_onClearSelectedProducts);
    on<ClearRangeLocationsEvent>(_onClearRangeLocations);
  }

  @override
  Future<void> close() {
    searchControllerLocation.dispose();
    searchControllerProducts.dispose();
    rangeStartController.dispose();
    rangeEndController.dispose();
    return super.close();
  }

  void _onLoadLocations(
      GetListLocationsEvent event, Emitter<PrintLabelsState> emit) async {
    try {
      emit(LoadLocationsLoading());
      final response = await db.ubicacionesRepository.getAllUbicaciones();
      ubicaciones.clear();
      ubicacionesFilters.clear();
      if (response.isNotEmpty) {
        // Ordenar por nombre una sola vez aquí; el filtro de búsqueda preserva
        // el orden, evitando re-ordenar en cada build de la pantalla (P-04).
        ubicaciones = response
          ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
        ubicacionesFilters = List.from(ubicaciones);
        debugPrint('####################>>>>>ubicaciones ${ubicaciones.length}');
        emit(LoadLocationsSuccess(ubicaciones));
      } else {
        emit(LoadLocationsFailure('No se encontraron ubicaciones'));
      }
    } catch (e, s) {
      emit(LoadLocationsFailure('Error al cargar las ubicaciones'));
      debugPrint('Error en el fetch de ubicaciones: $e=>$s');
    }
  }

  void _onGetProductsBD(
      GetProductsList event, Emitter<PrintLabelsState> emit) async {
    try {
      emit(GetProductsLoading());
      // Proyección liviana (id/name/code/barcode) en vez de SELECT * + parseo
      // de las ~35 columnas del modelo Product.
      final rows = await db.productoInventarioRepository.getProductLabelRows();
      productos.clear();
      productosFilters.clear();
      if (rows.isNotEmpty) {
        productos = rows.map(ProductLabel.fromMap).toList();
        productosFilters = List.from(productos);
        debugPrint('####################>>>>>productos ${productos.length}');
        emit(GetProductsSuccess(productos));
      } else {
        emit(GetProductsFailure('No se encontraron productos'));
      }
    } catch (e, s) {
      emit(GetProductsFailure('Error al cargar los productos'));
      debugPrint('Error en el fetch de productos: $e=>$s');
    }
  }

  void _onLoadConfigurationsUserEvent(
      LoadConfigurationsUserInfo event, Emitter<PrintLabelsState> emit) async {
    try {
      int userId = await PrefUtils.getUserId();
      final response =
          await db.configurationsRepository.getConfiguration(userId);

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

  void _onSearchLocationEvent(
      SearchLocationEvent event, Emitter<PrintLabelsState> emit) {
    ubicacionesFilters = [];
    final query = event.query.toLowerCase();
    if (query.isEmpty) {
      ubicacionesFilters = List.from(ubicaciones);
    } else {
      ubicacionesFilters = ubicaciones.where((location) {
        return location.name?.toLowerCase().contains(query) ?? false;
      }).toList();
    }
    emit(SearchLocationSuccess(ubicacionesFilters));
  }

  void _onSearchProductEvent(
      SearchProductEvent event, Emitter<PrintLabelsState> emit) {
    productosFilters = [];
    final query = event.query.toLowerCase();
    if (query.isEmpty) {
      productosFilters = List.from(productos);
    } else {
      productosFilters = productos.where((product) {
        return product.name.toLowerCase().contains(query) ||
            product.code.toLowerCase().contains(query) ||
            product.barcode.toLowerCase().contains(query);
      }).toList();
    }
    emit(SearchProductSuccess(productosFilters));
  }

  void _onSearchRangeLocationEvent(
      SearchRangeLocationEvent event, Emitter<PrintLabelsState> emit) {
    ubicacionesRange = [];
    final start = event.start.toLowerCase();
    final end = event.end.toLowerCase();

    if (start.isEmpty) {
      ubicacionesRange = [];
    } else if (end.isEmpty) {
      // Búsqueda por prefijo: todas las ubicaciones que inicien con el valor de inicio
      ubicacionesRange = ubicaciones.where((location) {
        final name = location.name?.toLowerCase() ?? '';
        return name.startsWith(start);
      }).toList();
      ubicacionesRange.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
    } else {
      ubicacionesRange = ubicaciones.where((location) {
        final name = location.name?.toLowerCase() ?? '';
        return name.compareTo(start) >= 0 && name.compareTo(end) <= 0;
      }).toList();
      ubicacionesRange.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
    }
    emit(SearchRangeLocationSuccess(ubicacionesRange));
  }

  void _onRemoveRangeLocationEvent(
      RemoveRangeLocationEvent event, Emitter<PrintLabelsState> emit) {
    ubicacionesRange =
        ubicacionesRange.where((l) => l.id != event.locationId).toList();
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
    emit(SearchRangeLocationSuccess(ubicacionesRange));
  }
}
