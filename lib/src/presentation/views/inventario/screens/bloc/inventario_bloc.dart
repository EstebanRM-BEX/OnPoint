// ignore_for_file: unnecessary_null_comparison

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:wms_app/features/user/data/models/user_configuration_model.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/inventario/data/inventario_repository.dart';
import 'package:wms_app/src/presentation/views/inventario/models/request_sendProducr_model.dart';
import 'package:wms_app/src/presentation/views/inventario/models/response_products_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_lotes_product_model.dart';

part 'inventario_event.dart';
part 'inventario_state.dart';

class InventarioBloc extends Bloc<InventarioEvent, InventarioState> {
  TextEditingController searchControllerLocation = TextEditingController();
  TextEditingController searchControllerProducts = TextEditingController();
  TextEditingController searchControllerLote = TextEditingController();

  TextEditingController newLoteController = TextEditingController();
  TextEditingController dateLoteController = TextEditingController();

  TextEditingController controllerLocation = TextEditingController();
  TextEditingController controllerLote = TextEditingController();
  TextEditingController controllerProduct = TextEditingController();
  TextEditingController controllerQuantity = TextEditingController();
  TextEditingController cantidadController = TextEditingController();

  final InventarioRepository _inventarioRepository = InventarioRepository();

  String scannedValue1 = ''; //ubicacion origen
  String scannedValue2 = ''; //producto
  String scannedValue3 = ''; //cantidad
  String selectedAlmacen = '';
  String scannedValue4 = ''; //lote

  List<BarcodeInventario> barcodeInventario = [];
  List<BarcodeInventario> allBarcodeInventario = [];

  // //*validaciones de campos del estado de la vista
  //*variables para validar
  bool locationIsOk = false;
  bool loteIsOk = false;

  bool productIsOk = false;
  bool quantityIsOk = false;
  bool isLocationOk = true;
  bool isProductOk = true;
  bool isLoteOk = true;

  bool isQuantityOk = true;
  bool isKeyboardVisible = false;
  bool viewQuantity = false;

  bool ubicacionFija = false;

  dynamic quantitySelected = 0;

  bool isLoading = false;

  //*base de datos
  DataBaseSqlite db = DataBaseSqlite();

  //*lista de ubicaciones
  List<ResultUbicaciones> ubicaciones = [];
  List<ResultUbicaciones> ubicacionesFilters = [];

  //lista de productos
  List<Product> productos = [];
  List<Product> productosFilters = [];

  //lista de lotes de un producto
  List<LotesProduct> listLotesProduct = [];
  List<LotesProduct> listLotesProductFilters = [];

  //producto actual
  Product? currentProduct;
  ResultUbicaciones? currentUbication;
  LotesProduct? currentProductLote;

  //*configuracion del usuario //permisos
  UserConfigurationModel configurations = UserConfigurationModel();

  InventarioBloc() : super(InventarioInitial()) {
    on<InventarioEvent>((event, emit) {});

    //*metodo para cargar las ubicaciones
    on<GetLocationsEvent>(_onLoadLocations);
    //metodo para buscar una ubicacion
    on<SearchLocationEvent>(_onSearchLocationEvent);
    //metodo para buscar un lote
    on<SearchLotevent>(_onSearchLoteEvent);
    //*metodo para bucar un producto
    on<SearchProductEvent>(_onSearchProductEvent);

    //metodo para mostrar el teclado
    on<ShowKeyboardEvent>(_onShowKeyboardEvent);

    //*evento para actualizar el valor del scan
    on<UpdateScannedValueEvent>(_onUpdateScannedValueEvent);
    on<ClearScannedValueEvent>(_onClearScannedValueEvent);

    on<ValidateFieldsEvent>(_onValidateFields);

    //*cambiar el estado de las variables
    on<ChangeLocationIsOkEvent>(_onChangeLocationIsOkEvent);
    on<ChangeProductIsOkEvent>(_onChangeProductIsOkEvent);
    on<ChangeIsOkQuantity>(_onChangeQuantityIsOkEvent);
    //*traermos todos los productos del inventario
    on<GetProductsEvent>(_onGetProducts);
    on<GetProductsForDB>(_onGetProductsBD);

    //*limpiamos los campos y el estado
    on<CleanFieldsEent>(_onCleanFields);

    //*metodo para obtener todos los lotes de un producto
    on<GetLotesProduct>(_onGetLotesProduct);
    on<SelectecLoteEvent>(_onChangeLoteIsOkEvent);

    //*evento para ver la cantidad
    on<ShowQuantityEvent>(_onShowQuantityEvent);

    //*evento para obtener los barcodes de un producto por paquete
    on<FetchBarcodesProductEvent>(_onFetchBarcodesProductEvent);

    //*evento para cambiar la cantidad seleccionada
    on<ChangeQuantitySeparate>(_onChangeQuantitySelectedEvent);
    on<AddQuantitySeparate>(_onAddQuantitySeparateEvent);

    on<SendProductInventarioEnvet>(_onSendProductInventarioEvent);

    //*metodo para crear un lote a un producto
    on<CreateLoteProduct>(_onCreateLoteProduct);

    //metodo para cargar la oncfiguracion del usuario
    //*obtener las configuraciones y permisos del usuario desde la bd
    on<LoadConfigurationsUserInventory>(_onLoadConfigurationsUserEvent);
    on<FilterUbicacionesAlmacenEvent>(_onFilterUbicacionesEvent);

    //metodo para poner una ubicacion fija
    on<SetUbicacionFijaEvent>(_onSetUbicacionFijaEvent);

    //meotod para obtener todos los other barcodes y product_packing de inventario
    on<FetchAllBarcodesInventarioEvent>(_onFetchAllBarcodesInventarioEvent);
  }

  void _onFetchAllBarcodesInventarioEvent(FetchAllBarcodesInventarioEvent event,
      Emitter<InventarioState> emit) async {
    try {
      final response = await db.barcodesInventarioRepository.getAllBarcodes();
      allBarcodeInventario.clear();
      if (response.isNotEmpty) {
        allBarcodeInventario = response;
        print('Total de códigos de barras: ${allBarcodeInventario.length}');
        emit(FetchAllBarcodesSuccess(allBarcodeInventario));
      } else {
        emit(FetchAllBarcodesFailure('No se encontraron códigos de barras'));
      }
    } catch (e, s) {
      print("❌ Error en _onFetchAllBarcodesInventarioEvent: $e, $s");
      emit(FetchAllBarcodesFailure('Error al obtener los códigos de barras'));
    }
  }

  void _onSetUbicacionFijaEvent(
      SetUbicacionFijaEvent event, Emitter<InventarioState> emit) {
    try {
      ubicacionFija = event.ubicacionFija;
      emit(ChangeLocationIsOkState(locationIsOk));
    } catch (e, s) {
      print("❌ Error en SetUbicacionFijaEvent: $e, $s");
      emit(ChangeLocationIsOkState(false));
    }
  }

  void _onFilterUbicacionesEvent(
      FilterUbicacionesAlmacenEvent event, Emitter<InventarioState> emit) {
    try {
      emit(FilterUbicacionesLoading());
      selectedAlmacen = '';
      ubicacionesFilters = [];
      ubicacionesFilters = ubicaciones;
      final query = event.almacen.toLowerCase();
      if (query.isEmpty) {
        ubicacionesFilters = ubicaciones;
      } else {
        selectedAlmacen = event.almacen;
        ubicacionesFilters = ubicaciones.where((location) {
          return location.warehouseName?.toLowerCase().contains(query) ?? false;
        }).toList();
      }
      emit(FilterUbicacionesSuccess(ubicacionesFilters));
    } catch (e, s) {
      print('Error en el FilterUbicacionesEvent: $e, $s');
      emit(FilterUbicacionesFailure(e.toString()));
    }
  }

  //*metodo para cargar la configuracion del usuario
  void _onLoadConfigurationsUserEvent(LoadConfigurationsUserInventory event,
      Emitter<InventarioState> emit) async {
    try {
      int userId = await PrefUtils.getUserId();
      final response =
          await db.configurationsRepository.getConfiguration(userId);

      if (response != null) {
        configurations = response;
        emit(ConfigurationLoadedInventory(response));
      } else {
        emit(ConfigurationErrorInventory('Error al cargar configuraciones'));
      }
    } catch (e, s) {
      emit(ConfigurationErrorInventory(e.toString()));
      print('Error en LoadConfigurationsUserPack.dart: $e =>$s');
    }
  }

  //metodo pea crar un lote a un producto
  void _onCreateLoteProduct(
      CreateLoteProduct event, Emitter<InventarioState> emit) async {
    try {
      emit(CreateLoteProductLoading());
      final response = await _inventarioRepository.createLote(
        false,
        currentProduct?.productId ?? 0,
        event.nameLote,
        event.fechaCaducidad,
      );

      if (response.result?.code == 200) {
        // 1. Capturamos el nuevo lote de forma segura
        final newLote = response.result?.result ?? LotesProduct();

        // 2. Agregamos a la lista MAESTRA
        listLotesProduct.add(newLote);

        // 3. Reconstruimos la lista de FILTROS basada en la maestra
        // Esto rompe referencias y evita duplicados visuales
        listLotesProductFilters = List.from(listLotesProduct);

        // 4. Actualizamos el estado actual
        currentProductLote = newLote;
        loteIsOk = true;

        // 5. Limpieza
        dateLoteController.clear();
        newLoteController.clear();

        // Opcional: Limpiar buscador si quieres reiniciar la vista
        // searchControllerLote.clear();

        add(SelectecLoteEvent(currentProductLote!));
        emit(CreateLoteProductSuccess());
      } else {
        emit(CreateLoteProductFailure(response.result?.msg ??
            'Error al crear el lote contactarse con el administrador'));
      }
    } catch (e, s) {
      emit(CreateLoteProductFailure('Error al crear el lote'));
      print('Error en el _onCreateLoteProduct: $e, $s');
    }
  }

  void _onSendProductInventarioEvent(
      SendProductInventarioEnvet event, Emitter<InventarioState> emit) async {
    try {
      emit(SendProductLoading());

      int userId = await PrefUtils.getUserId();

      final response = await _inventarioRepository.sendProduct(
        SendProductInventario(
          locationId: currentUbication?.id ?? 0, //currentUbication?.id ?? 0,
          productId: currentProduct?.productId ?? 0,
          lotId: currentProductLote?.id ?? 0,
          quantity: event.cantidad,
          userId: userId,
        ),
        false,
      );

      if (response.result?.status == 'success') {
        clenanFields();
        cantidadController.clear();
        emit(SendProductSuccess());
      } else {
        emit(SendProductFailure(response.result?.message ?? ""));
      }
    } catch (e, s) {
      emit(SendProductFailure('Error al enviar el producto'));
      print('Error en el _onSendProductInventarioEvent: $e, $s');
    }
  }

  void clenanFields() {
    scannedValue1 = '';
    scannedValue2 = '';
    scannedValue3 = '';
    scannedValue4 = '';

    // Reset validation flags

    productIsOk = false;
    quantityIsOk = false;
    viewQuantity = false;
    loteIsOk = false;

    isProductOk = true;
    isQuantityOk = true;
    isLoteOk = true;

    // Reset quantity
    quantitySelected = 0;

    // Clear search controllers
    searchControllerLocation.clear();
    searchControllerProducts.clear();

    // Clear current product
    currentProduct = null;
    if (!ubicacionFija) {
      currentUbication = null;
      locationIsOk = false;
      isLocationOk = true;
    }
    currentProductLote = null;

    listLotesProduct.clear();
    barcodeInventario.clear();
  }

  //*metodo para cambiar la cantidad seleccionada
  void _onChangeQuantitySelectedEvent(
      ChangeQuantitySeparate event, Emitter<InventarioState> emit) async {
    try {
      if (event.quantity > 0) {
        quantitySelected = event.quantity;
      }
      emit(ChangeQuantitySeparateStateSuccess(quantitySelected));
    } catch (e, s) {
      emit(ChangeQuantitySeparateStateError('Error al separar cantidad'));
      print('❌ Error en ChangeQuantitySeparate: $e -> $s ');
    }
  }

  //*evento para aumentar la cantidad
  void _onAddQuantitySeparateEvent(
      AddQuantitySeparate event, Emitter<InventarioState> emit) async {
    try {
      quantitySelected = quantitySelected + event.quantity;
      emit(ChangeQuantitySeparateStateSuccess(quantitySelected));
    } catch (e, s) {
      emit(ChangeQuantitySeparateStateError('Error al aumentar cantidad'));
      print("❌ Error en el AddQuantitySeparate $e ->$s");
    }
  }

  //*evento para obtener los barcodes de un producto por paquete
  void _onFetchBarcodesProductEvent(
      FetchBarcodesProductEvent event, Emitter<InventarioState> emit) async {
    try {
      barcodeInventario.clear();

      final response = await db.barcodesInventarioRepository.getBarcodesProduct(
        currentProduct?.productId ?? 0,
      );

      if (response.isNotEmpty) {
        barcodeInventario = response;
        emit(BarcodesProductLoadedState(listOfBarcodes: barcodeInventario));
      } else {
        emit(BarcodesProductLoadedState(listOfBarcodes: []));
        return;
      }
    } catch (e, s) {
      print("❌ Error en _onFetchBarcodesProductEvent: $e, $s");
    }
    emit(BarcodesProductLoadedState(listOfBarcodes: barcodeInventario));
  }

  //*evento para ver la cantidad
  void _onShowQuantityEvent(
      ShowQuantityEvent event, Emitter<InventarioState> emit) {
    try {
      viewQuantity = !viewQuantity;
      emit(ShowQuantityState(viewQuantity));
    } catch (e, s) {
      print("❌ Error en _onShowQuantityEvent: $e, $s");
    }
  }

  void _onChangeQuantityIsOkEvent(
      ChangeIsOkQuantity event, Emitter<InventarioState> emit) async {
    try {
      print('activando la cantidad ------');
      if (event.isQuantity) {
        quantityIsOk = true;
      }
      emit(ChangeQuantityIsOkState(
        quantityIsOk,
      ));
    } catch (e, s) {
      print("❌ Error en el ChangeIsOkQuantity $e ->$s");
    }
  }

  void _onChangeLoteIsOkEvent(
      SelectecLoteEvent event, Emitter<InventarioState> emit) async {
    try {
      currentProductLote = event.lote;
      loteIsOk = true;
      isLoteOk = true;
      add(ChangeIsOkQuantity(true));
      emit(ChangeLoteIsOkState(
        loteIsOk,
      ));
    } catch (e, s) {
      print('Error en el SelectecLoteEvent de inventario $s ->$e');
    }
  }

  //*metodo para obtener todos los lotes de un producto
  void _onGetLotesProduct(
      GetLotesProduct event, Emitter<InventarioState> emit) async {
    try {
      emit(GetLotesProductLoading());

      // Siempre obtener los lotes frescos del servidor
      final response = await _inventarioRepository.fetchAllLotesProduct(
          false, currentProduct?.productId ?? 0);

      listLotesProduct = response;
      listLotesProductFilters = response;

      if (event.isManual) {
        // Búsqueda optimizada sin caché - versión eficiente
        LotesProduct? foundLote;
        for (final lote in response) {
          if (lote.id == event.idLote) {
            foundLote = lote;
            break; // Rompe el ciclo al encontrar el lote
          }
        }

        currentProductLote = foundLote ?? LotesProduct();
        loteIsOk = true;
        add(ChangeIsOkQuantity(true));
      }

      emit(GetLotesProductSuccess(response));
    } catch (e, s) {
      emit(GetLotesProductFailure('Error al obtener los lotes del producto'));
      debugPrint('Error en _onGetLotesProduct: $e\n$s');
    }
  }

  void _onCleanFields(CleanFieldsEent event, Emitter<InventarioState> emit) {
    try {
      // Reset scanned values
      clenanFields();

      // Emit clean fields state
      emit(CleanFieldsState());
    } catch (e, s) {
      print("❌ Error in _onCleanFields: $e -> $s");
    }
  }

//* metodo para validar el producto
  void _onChangeProductIsOkEvent(
      ChangeProductIsOkEvent event, Emitter<InventarioState> emit) async {
    try {
      if (isProductOk) {
        currentProduct = event.productSelect;
        add(FetchBarcodesProductEvent());

        if (currentProduct?.tracking == 'lot') {
          add(GetLotesProduct(
            isManual: event.isManual,
            idLote: currentProduct?.lotId ?? 0,
          ));
        } else {
          viewQuantity = false;
        }
        productIsOk = true;

        if (currentProduct?.tracking == "none" ||
            currentProduct?.tracking == null) {
          add(ChangeIsOkQuantity(true));
        }

        emit(ChangeProductIsOkState(
          productIsOk,
        ));
      }
    } catch (e, s) {
      print("❌ Error en el ChangeProductIsOkEvent $e ->$s");
    }
  }

  //*metodo para validar la ubicacion
  void _onChangeLocationIsOkEvent(
      ChangeLocationIsOkEvent event, Emitter<InventarioState> emit) async {
    try {
      if (isLocationOk) {
        currentUbication = event.locationSelect;
        locationIsOk = true;

        // separarProductosPorUbicacionActual(); // 🔥 aquí separamos

        emit(ChangeLocationIsOkState(locationIsOk));
      }
    } catch (e, s) {
      print("❌ Error en ChangeLocationIsOkEvent $e ->$s");
    }
  }

  void _onGetProducts(
      GetProductsEvent event, Emitter<InventarioState> emit) async {
    try {
      if (isLoading) return;
      emit(GetProductsLoadingInventory());
      await db.deleInventario();
      final response = await _inventarioRepository.fetAllProducts(
        event.isDialogLoading,
      );
      if (response.isNotEmpty) {
        await db.productoInventarioRepository
            .insertProductosInventario(response);

        final allBarcodes =
            _extractAllBarcodes(response).toList(growable: false);

        print('productos: ${response.length}');

        await db.barcodesInventarioRepository
            .insertOrUpdateBarcodes(allBarcodes);
        emit(GetProductsSuccess(response));
        add(GetProductsForDB());
      } else {
        emit(GetProductsFailureInventory('No se encontraron productos'));
      }
    } catch (e, s) {
      emit(GetProductsFailureInventory('Error al cargar los productos'));
      print('Error en el fetch de productos: $e=>$s');
    }
  }

  // Generador para todos los códigos de barras
  Iterable<BarcodeInventario> _extractAllBarcodes(
      List<Product> response) sync* {
    for (final product in response) {
      if (product.otherBarcodes != null) {
        yield* product.otherBarcodes!;
      }
      if (product.productPacking != null) {
        yield* product.productPacking!;
      }
    }
  }

  void getPordutsAllBD() async {
    final response = await db.productoInventarioRepository.getAllProducts();
    print('response: ${response.length}');
  }

  void _onGetProductsBD(
      GetProductsForDB event, Emitter<InventarioState> emit) async {
    try {
      emit(GetProductsLoadingBD());
      final response = await db.productoInventarioRepository.getAllProducts();
      productos.clear();
      productosFilters.clear();
      print('productos: ${response.length}');
      if (response.isNotEmpty) {
        productos = response;
        productosFilters = productos;

        isLoading = false;
        emit(GetProductsSuccessBD(response));
      } else {
        isLoading = false;
        emit(GetProductsFailureInventory('No se encontraron productos'));
      }
    } catch (e, s) {
      emit(GetProductsFailureInventory('Error al cargar los productos'));
      print('Error en el fetch de productos: $e=>$s');
    }
  }

  void _onValidateFields(
      ValidateFieldsEvent event, Emitter<InventarioState> emit) {
    try {
      switch (event.field) {
        case 'location':
          isLocationOk = event.isOk;
          break;
        case 'product':
          isProductOk = event.isOk;
          break;
        case 'quantity':
          isQuantityOk = event.isOk;
          break;
        case 'lote':
          isLoteOk = event.isOk;
          break;
      }
      emit(ValidateFieldsStateSuccess(event.isOk));
    } catch (e, s) {
      emit(ValidateFieldsStateError('Error al validar campos'));
      print("❌ Error en el ValidateFieldsEvent $e ->$s");
    }
  }

  //*evento para actualizar el valor del scan
  void _onUpdateScannedValueEvent(
      UpdateScannedValueEvent event, Emitter<InventarioState> emit) {
    try {
      switch (event.scan) {
        case 'location':
          // Acumulador de valores escaneados
          scannedValue1 += event.scannedValue.trim();
          print('scannedValue1: $scannedValue1');
          emit(UpdateScannedValueState(scannedValue1, event.scan));
          break;
        case 'product':
          scannedValue2 += event.scannedValue.trim();
          print('scannedValue2: $scannedValue2');
          emit(UpdateScannedValueState(scannedValue2, event.scan));
          break;
        case 'quantity':
          scannedValue3 += event.scannedValue.trim();
          print('scannedValue3: $scannedValue3');
          emit(UpdateScannedValueState(scannedValue3, event.scan));
          break;

        case 'lote':
          scannedValue4 += event.scannedValue.trim();
          print('scannedValue4: $scannedValue4');
          emit(UpdateScannedValueState(scannedValue4, event.scan));
          break;
        default:
          print('Scan type not recognized: ${event.scan}');
      }
    } catch (e, s) {
      print("❌ Error en _onUpdateScannedValueEvent: $e, $s");
    }
  }

//*evento para limpiar el valor del scan
  void _onClearScannedValueEvent(
      ClearScannedValueEvent event, Emitter<InventarioState> emit) {
    try {
      switch (event.scan) {
        case 'location':
          scannedValue1 = '';
          emit(ClearScannedValueState());
          break;
        case 'product':
          scannedValue2 = '';
          emit(ClearScannedValueState());
          break;
        case 'quantity':
          scannedValue3 = '';
          emit(ClearScannedValueState());
          break;
        case 'lote':
          scannedValue4 = '';
          emit(ClearScannedValueState());
          break;

        default:
          print('Scan type not recognized: ${event.scan}');
      }
      emit(ClearScannedValueState());
    } catch (e, s) {
      print("❌ Error en _onClearScannedValueEvent: $e, $s");
    }
  }

  void _onShowKeyboardEvent(
      ShowKeyboardEvent event, Emitter<InventarioState> emit) {
    isKeyboardVisible = event.showKeyboard;
    emit(ShowKeyboardState(showKeyboard: isKeyboardVisible));
  }

  void _onSearchLocationEvent(
      SearchLocationEvent event, Emitter<InventarioState> emit) async {
    try {
      emit(SearchLoading());
      ubicacionesFilters = [];
      ubicacionesFilters = ubicaciones;
      final query = event.query.toLowerCase();
      selectedAlmacen = '';
      if (query.isEmpty) {
        ubicacionesFilters = ubicaciones;
      } else {
        ubicacionesFilters = ubicaciones.where((location) {
          return location.name?.toLowerCase().contains(query) ?? false;
        }).toList();
      }
      emit(SearchLocationSuccess(ubicacionesFilters));
    } catch (e, s) {
      print('Error en el SearchLocationEvent: $e, $s');
      emit(SearchFailure(e.toString()));
    }
  }

  void _onSearchLoteEvent(
      SearchLotevent event, Emitter<InventarioState> emit) async {
    try {
      emit(SearchLoading());
      listLotesProductFilters = [];
      listLotesProductFilters = listLotesProduct;
      final query = event.query.toLowerCase();
      if (query.isEmpty) {
        listLotesProductFilters = listLotesProduct;
      } else {
        listLotesProductFilters = listLotesProduct.where((lotes) {
          return lotes.name?.toLowerCase().contains(query) ?? false;
        }).toList();
      }
      emit(SearchLoteSuccess(listLotesProductFilters));
    } catch (e, s) {
      print('Error en el SearchLocationEvent: $e, $s');
      emit(SearchFailure(e.toString()));
    }
  }

  void _onSearchProductEvent(
    SearchProductEvent event,
    Emitter<InventarioState> emit,
  ) async {
    try {
      print('🔍 Buscando productos con query: "${event.query}"');
      emit(SearchLoading());

      final query = event.query.trim();

      final List<Product> filtrados = productos.where((product) {
        final name = (product.name ?? '').toLowerCase();
        final code = (product.code ?? '').toString().trim();
        final barcode = (product.barcode ?? '').toString().trim();

        return name.contains(query.toLowerCase()) ||
            code.contains(query) ||
            barcode.contains(query);
      }).toList();

      productosFilters = filtrados;

      emit(SearchProductSuccess(filtrados));
    } catch (e, s) {
      print('❌ Error en SearchProductEvent: $e\n$s');
      emit(SearchFailure(e.toString()));
    }
  }

  void _onLoadLocations(
      GetLocationsEvent event, Emitter<InventarioState> emit) async {
    try {
      emit(LoadLocationsLoading());
      final response = await db.ubicacionesRepository.getAllUbicaciones();
      ubicaciones.clear();
      ubicacionesFilters.clear();
      print('ubicaciones: ${response.length}');
      if (response.isNotEmpty) {
        ubicaciones = response;
        ubicacionesFilters = ubicaciones;
        emit(LoadLocationsSuccess(ubicaciones));
      } else {
        emit(LoadLocationsFailure('No se encontraron ubicaciones'));
      }
    } catch (e, s) {
      emit(LoadLocationsFailure('Error al cargar las ubicaciones'));
      print('Error en el fetch de ubicaciones: $e=>$s');
    }
  }
}
