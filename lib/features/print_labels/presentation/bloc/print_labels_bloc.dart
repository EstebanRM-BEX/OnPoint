import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/views/inventario/models/response_products_model.dart';
import 'package:wms_app/features/user/data/models/user_configuration_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';

part 'print_labels_event.dart';
part 'print_labels_state.dart';

class PrintLabelsBloc extends Bloc<PrintLabelsEvent, PrintLabelsState> {
  List<ResultUbicaciones> ubicaciones = [];
  List<ResultUbicaciones> ubicacionesFilters = [];
  List<Product> productos = [];
  List<Product> productosFilters = [];
  UserConfigurationModel configurations = UserConfigurationModel();

  TextEditingController searchControllerLocation = TextEditingController();
  TextEditingController searchControllerProducts = TextEditingController();
  TextEditingController rangeStartController = TextEditingController();
  TextEditingController rangeEndController = TextEditingController();

  List<ResultUbicaciones> ubicacionesRange = [];
  List<Product> productosSelected = [];

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
  }

  void _onLoadLocations(
      GetListLocationsEvent event, Emitter<PrintLabelsState> emit) async {
    try {
      emit(LoadLocationsLoading());
      final response = await db.ubicacionesRepository.getAllUbicaciones();
      ubicaciones.clear();
      ubicacionesFilters.clear();
      if (response.isNotEmpty) {
        ubicaciones = response;
        ubicacionesFilters = List.from(ubicaciones);
        print('####################>>>>>ubicaciones ${ubicaciones.length}');
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
      final response =
          await db.productoInventarioRepository.getAllUniqueProducts();
      productos.clear();
      productosFilters.clear();
      if (response.isNotEmpty) {
        productos = response;
        productosFilters = List.from(productos);
        print('####################>>>>>productos ${productos.length}');
        emit(GetProductsSuccess(response));
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
        return (product.name?.toLowerCase().contains(query) ?? false) ||
            (product.code?.toLowerCase().contains(query) ?? false) ||
            (product.barcode?.toLowerCase().contains(query) ?? false);
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
    final alreadyAdded = productosSelected.any((p) => p.productId == event.product.productId);
    if (!alreadyAdded) {
      productosSelected = [...productosSelected, event.product];
      productosSelected.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
    }
    emit(SearchProductSuccess(productosFilters));
  }

  void _onRemoveSelectedProductEvent(
      RemoveSelectedProductEvent event, Emitter<PrintLabelsState> emit) {
    productosSelected =
        productosSelected.where((p) => p.productId != event.productId).toList();
    emit(SearchProductSuccess(productosFilters));
  }
}
