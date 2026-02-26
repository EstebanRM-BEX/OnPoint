// ignore_for_file: unnecessary_type_check

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:wms_app/features/user/data/models/user_configuration_model.dart';
import 'package:wms_app/core/utils/formats_utils.dart';
import 'package:wms_app/core/utils/interable_extension_utils.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/devoluciones/data/devoluciones_repository.dart';
import 'package:wms_app/src/presentation/views/devoluciones/models/product_devolucion_model.dart';
import 'package:wms_app/src/presentation/views/devoluciones/models/request_send_devolucion_model.dart';
import 'package:wms_app/src/presentation/views/devoluciones/models/response_devolucion_model.dart';
import 'package:wms_app/src/presentation/views/devoluciones/models/response_terceros_model.dart';
import 'package:wms_app/src/presentation/views/inventario/models/response_products_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_lotes_product_model.dart';

part 'devoluciones_event.dart';
part 'devoluciones_state.dart';

class DevolucionesBloc extends Bloc<DevolucionesEvent, DevolucionesState> {
  //controller
  TextEditingController searchControllerLocation = TextEditingController();
  TextEditingController searchControllerProducts = TextEditingController();
  TextEditingController searchControllerTerceros = TextEditingController();
  TextEditingController searchControllerLote = TextEditingController();
  TextEditingController newLoteController = TextEditingController();
  TextEditingController dateLoteController = TextEditingController();
  TextEditingController searchControllerLocationDest = TextEditingController();
  String scannedValue1 = ''; //foco
  String scannedValue2 = ''; //cantidad
  String scannedValue3 = ''; //location
  String scannedValue4 = ''; //contacto

  String selectedAlmacen = '';

  bool locationIsOk = false;
  bool contactoIsOk = false;
  bool productIsOk = false;

  //configuracion del usuario //permisos
  UserConfigurationModel configurations = UserConfigurationModel();

  //*lista de productos
  List<Product> productos = [];
  List<Product> productosFilters = [];

  List<ProductDevolucion> productosDevolucion = [];

  Product currentProduct = Product();
  Terceros currentTercero = Terceros();
  ResultUbicaciones currentLocation = ResultUbicaciones();

  LotesProduct lotesProductCurrent = LotesProduct();

  //*base de datos
  DataBaseSqlite db = DataBaseSqlite();

  dynamic quantitySelected = 0;

  bool viewQuantity = false;
  bool isDialogVisible = false;

  List<Terceros> terceros = [];
  List<Terceros> tercerosFilters = [];

  bool isKeyboardVisible = false;

  //*lista de ubicaciones
  List<ResultUbicaciones> ubicaciones = [];
  List<ResultUbicaciones> ubicacionesFilters = [];

  //lista de lotes de un producto
  List<LotesProduct> listLotesProduct = [];
  List<LotesProduct> listLotesProductFilters = [];

  List<BarcodeInventario> allBarcodeInventario = [];

  DevolucionesRepository devolucionesRepository = DevolucionesRepository();

  DevolucionesBloc() : super(DevolucionesInitial()) {
    on<DevolucionesEvent>((event, emit) {});

    on<GetProductEvent>(_onGetProductEvent);
    on<GetProductsList>(_onGetProductsBD);
    //evento para añadir un producto a la lista de devoluciones
    on<Addproduct>(_onAddProductEvent);
    //evento para eliminar un producto de la lista de devoluciones
    on<RemoveProduct>(_onRemoveProductEvent);
    //evento para pedir la cantidad del producto
    on<SetQuantityEvent>(_onSetQuantityEvent);

    ///evento para pedir el lote del producto
    on<SetLoteEvent>(_onSetLoteEvent);
    //*evento para ver la cantidad
    on<ShowQuantityEvent>(_onShowQuantityEvent);
    on<LoadCurrentProductEvent>(_onLoaadCurrentProductEvent);
    //evento para actualizar el producto
    on<UpdateProductInfoEvent>(_onUpdateProductInfoEvent);
    //evento para cargar todos los terceros
    on<LoadTercerosEvent>(_onLoadTercerosEvent);
    //*activar el teclado
    //evento para seleccionar un tercero
    on<SelectTerceroEvent>(_onSelectTerceroEvent);
    //evento para buscar un tercero
    on<SearchTerceroEvent>(_onSearchTerceroEvent);
    // evento para filtrar los terceros
    // on<FilterTercerosEvent>(_onFilterTercerosEvent);

    //*evento para cargar las ubicaciones
    on<LoadLocationsEvent>(_onLoadLocations);

    //*metodo para buscar una ubicacion
    on<SearchLocationEvent>(_onSearchLocationEvent);

    on<FilterUbicacionesEvent>(_onFilterUbicacionesEvent);

    //evento para seleccionar una ubicacion
    on<SelectLocationEvent>(_onSelectLocationEvent);

    on<SelectecLoteEvent>(_onChangeLoteIsOkEvent);
    //metodo para buscar un lote
    on<SearchLotevent>(_onSearchLoteEvent);

    //*metodo para crear un lote a un producto
    on<CreateLoteProduct>(_onCreateLoteProduct);

    //*metodo para obtener todos los lotes de un producto
    on<GetLotesProduct>(_onGetLotesProduct);

    //evento para limpiar los campos
    on<ClearValueEvent>(_onClearValueEvent);

    //*metodo para bucar un producto
    on<SearchProductEvent>(_onSearchProductEvent);

    //evento apra evniar la devolucion
    on<SendDevolucionEvent>(_onSendDevolucionEvent);

    on<ChangeStateIsDialogVisibleEvent>(_onChangeStateIsDialogVisibleEvent);

    on<LoadConfigurationsUser>(_onLoadConfigurationsUserEvent);

    //meotod para obtener todos los other barcodes y product_packing de inventario
    on<FetchAllBarcodesInventarioEvent>(_onFetchAllBarcodesInventarioEvent);
  }

  void _onFetchAllBarcodesInventarioEvent(FetchAllBarcodesInventarioEvent event,
      Emitter<DevolucionesState> emit) async {
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

  //* evento para cargar la configuracion del usuario
  void _onLoadConfigurationsUserEvent(
      LoadConfigurationsUser event, Emitter<DevolucionesState> emit) async {
    try {
      int userId = await PrefUtils.getUserId();
      final response =
          await db.configurationsRepository.getConfiguration(userId);

      if (response != null) {
        emit(ConfigurationDevLoaded(response));
        configurations = response;
      } else {
        emit(ConfigurationError('Error al cargar LoadConfigurationsUser'));
      }
    } catch (e, s) {
      print('❌ Error en LoadConfigurationsUser $e =>$s');
    }
  }

  void _onChangeStateIsDialogVisibleEvent(
      ChangeStateIsDialogVisibleEvent event, Emitter<DevolucionesState> emit) {
    isDialogVisible = event.isVisible;
    emit(ChangeStateIsDialogVisibleState(isDialogVisible));
  }

  void _onSendDevolucionEvent(
      SendDevolucionEvent event, Emitter<DevolucionesState> emit) async {
    try {
      emit(SendDevolucionLoading());

      final userid = await PrefUtils.getUserId();

      DateTime fechaTransaccion = DateTime.now();
      String fechaFormateada = formatoFecha(fechaTransaccion);

      final RequestSendDevolucionModel request = RequestSendDevolucionModel(
        idAlmacen: currentLocation.idWarehouse ?? 0,
        idProveedor: currentTercero.id ?? 0,
        idUbicacionDestino: currentLocation.id ?? 0,
        idResponsable: userid,
        fechaInicio: fechaFormateada,
        fechaFin: fechaFormateada,
        listItems: productosDevolucion.map((product) {
          return ProductRequest(
            idProducto: product.productId ?? 0,
            idLote: product.lotId == 0 || product.lotId == null
                ? ""
                : product.lotId,
            ubicacionDestino: currentLocation.id ?? 0,
            cantidadEnviada: product.quantity ?? 0,
            idOperario: userid,
            timeLine: 1, // Puedes ajustar este valor según tu lógica
            fechaTransaccion: fechaFormateada,
            observacion:
                'Sin novedad', // Puedes agregar una observación si es necesario
          );
        }).toList(),
      );

      //enviamos la devolucion
      final response = await devolucionesRepository.sendDevolucion(
        request,
        true,
      );

      if (response.result?.code == 200) {
        //limpiamos los campos
        add(ClearValueEvent());
        emit(SendDevolucionSuccess(response));
      } else {
        if (response.result?.code == 403) {
          //emitimos un error de autorizacion
          emit(DeviceNotAuthorized());
          return;
        }

        emit(SendDevolucionFailure(response.result?.msg ??
            'Error desconocido al enviar la devolución'));
      }
    } catch (e, s) {
      print("❌ Error en _onSendDevolucionEvent: $e, $s");
      emit(SendDevolucionFailure('Error al enviar la devolución'));
    }
  }

  void _onSearchProductEvent(
      SearchProductEvent event, Emitter<DevolucionesState> emit) async {
    try {
      emit(SearchLoading());
      productosFilters = [];
      productosFilters = productos;
      final query = event.query.toLowerCase();
      if (query.isEmpty) {
        productosFilters = productos;
      } else {
        productosFilters = productos.where((product) {
          return (product.name?.toLowerCase().contains(query) ?? false) ||
              (product.code?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
      emit(SearchProductSuccess(productosFilters));
    } catch (e, s) {
      print('Error en el SearchLocationEvent: $e, $s');
      emit(SearchFailure(e.toString()));
    }
  }

  //*metodo para limpiar los campos de busqueda
  void _onClearValueEvent(
      ClearValueEvent event, Emitter<DevolucionesState> emit) async {
    try {
      searchControllerLocation.clear();
      searchControllerProducts.clear();
      searchControllerTerceros.clear();
      searchControllerLote.clear();
      newLoteController.clear();
      dateLoteController.clear();
      searchControllerLocationDest.clear();
      scannedValue1 = '';
      scannedValue2 = '';
      viewQuantity = false;
      isKeyboardVisible = false;
      productIsOk = false;
      locationIsOk = false;
      contactoIsOk = false;
      currentProduct = Product();
      currentTercero = Terceros();
      currentLocation = ResultUbicaciones();
      lotesProductCurrent = LotesProduct();
      quantitySelected = 0;
      productosDevolucion.clear();
      productosFilters = productos;
      listLotesProductFilters = listLotesProduct;
      ubicacionesFilters = ubicaciones;
      tercerosFilters = terceros;
      isDialogVisible = false;

      //limpiamos la tbla de productos devoluciones
      await db.devolucionRepository.deleteAllProductosDevoluciones();
      emit(ClearValueState());
    } catch (e, s) {
      print("❌ Error en _onClearScannedValueEvent: $e, $s");
    }
  }

  //*metodo para obtener todos los lotes de un producto
  void _onGetLotesProduct(
      GetLotesProduct event, Emitter<DevolucionesState> emit) async {
    try {
      emit(GetLotesProductLoading());
      final response = await devolucionesRepository.fetchAllLotesProduct(
          false, currentProduct.productId ?? 0);

      if (response != null && response is List) {
        listLotesProduct = response;
        listLotesProductFilters = response;
        emit(GetLotesProductSuccess(response));
      } else {
        emit(GetLotesProductFailure('Error al obtener los lotes del producto'));
      }
    } catch (e, s) {
      emit(GetLotesProductFailure('Error al obtener los lotes del producto'));
      print('Error en el _onGetLotesProduct: $e, $s');
    }
  }

  //metodo pea crar un lote a un producto
  void _onCreateLoteProduct(
      CreateLoteProduct event, Emitter<DevolucionesState> emit) async {
    try {
      emit(CreateLoteProductLoading());

      final response = await devolucionesRepository.createLote(
        true,
        currentProduct.productId ?? 0,
        event.nameLote ?? "",
        event.fechaCaducidad ?? "",
      );

      if (response != null) {
        if (response.result?.code == 200) {
          // 1. Capturamos el nuevo lote de la respuesta
          final newLote = response.result?.result ?? LotesProduct();

          // 2. Agregamos el nuevo lote a la lista PRINCIPAL (Maestra)
          listLotesProduct.add(newLote);

          // 3. Actualizamos la lista de FILTROS creando una copia nueva de la principal
          // Esto garantiza que ambas listas tengan los mismos datos sin duplicar referencias
          listLotesProductFilters = List.from(listLotesProduct);

          // 4. Actualizamos el lote seleccionado actual
          lotesProductCurrent = newLote;

          // 5. Limpieza de controladores
          dateLoteController.clear();
          newLoteController.clear();

          // Recomendado: Limpiar el buscador para que coincida con la lista completa
          // searchControllerLote.clear();

          emit(CreateLoteProductSuccess(lotesProductCurrent));
        } else {
          emit(CreateLoteProductFailure(
              response.result?.msg ?? 'Error al crear el lote'));
        }
      } else {
        emit(CreateLoteProductFailure('Error al crear el lote'));
      }
    } catch (e, s) {
      emit(CreateLoteProductFailure('Error al crear el lote'));
      print('Error en el _onCreateLoteProduct: $e, $s');
    }
  }

  void _onSearchLoteEvent(
      SearchLotevent event, Emitter<DevolucionesState> emit) async {
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

  void _onChangeLoteIsOkEvent(
      SelectecLoteEvent event, Emitter<DevolucionesState> emit) async {
    //agregamos el lote al producto
    lotesProductCurrent = event.lote;
    dateLoteController.clear();
    newLoteController.clear();
    searchControllerLote.clear();

    print('Lote seleccionado: ${lotesProductCurrent.toMap()}');
    emit(SelectecLoteState(lotesProductCurrent));
  }

  //*metodo para seleccionar una ubicacion
  void _onSelectLocationEvent(
      SelectLocationEvent event, Emitter<DevolucionesState> emit) {
    try {
      currentLocation = event.location;
      searchControllerLocationDest.clear();
      scannedValue3 = '';
      locationIsOk = true;
      print('Ubicación seleccionada: ${currentLocation.toMap()}');
      emit(SelectLocationState(currentLocation));
    } catch (e, s) {
      print("❌ Error en _onSelectLocationEvent: $e, $s");
    }
  }

  //*metodo para filtrar las ubicaciones
  void _onFilterUbicacionesEvent(
      FilterUbicacionesEvent event, Emitter<DevolucionesState> emit) {
    try {
      print('Filtrando ubicaciones por almacen: ${event.almacen}');
      emit(FilterLocationsLoading());
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
      emit(FilterLocationsSuccess(ubicacionesFilters));
    } catch (e, s) {
      print('Error en el FilterUbicacionesEvent: $e, $s');
      emit(FilterLocationsFailure(e.toString()));
    }
  }

  void _onSearchLocationEvent(
      SearchLocationEvent event, Emitter<DevolucionesState> emit) async {
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

  void _onLoadLocations(
      LoadLocationsEvent event, Emitter<DevolucionesState> emit) async {
    try {
      emit(LoadingLocationsState());
      final response = await db.ubicacionesRepository.getAllUbicaciones();
      ubicaciones.clear();
      ubicacionesFilters.clear();
      if (response.isNotEmpty) {
        ubicaciones = response;
        ubicacionesFilters = response;
        print('ubicaciones length: ${ubicaciones.length}');
        emit(LoadLocationsSuccessState(ubicaciones));
      } else {
        emit(LoadLocationsFailureState('No se encontraron ubicaciones'));
      }
    } catch (e, s) {
      emit(LoadLocationsFailureState('Error al cargar las ubicaciones'));
      print('Error en el fetch de ubicaciones: $e=>$s');
    }
  }

  //*metodo para buscar un tercero
  void _onSearchTerceroEvent(
      SearchTerceroEvent event, Emitter<DevolucionesState> emit) {
    try {
      emit(SearchLoading());
      tercerosFilters = [];
      tercerosFilters = terceros;
      final query = event.query.toLowerCase();
      selectedAlmacen = '';
      if (query.isEmpty) {
        tercerosFilters = terceros;
      } else {
        tercerosFilters = terceros.where((tercero) {
          return (tercero.name?.toLowerCase().contains(query) ?? false) ||
              (tercero.document?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
      emit(SearchTerceroSuccess(tercerosFilters));
    } catch (e, s) {
      print('Error en el SearchLocationEvent: $e, $s');
      emit(SearchFailure(e.toString()));
    }
  }

  //*metodo para seleccionar un tercero
  void _onSelectTerceroEvent(
      SelectTerceroEvent event, Emitter<DevolucionesState> emit) {
    try {
      currentTercero = event.tercero;
      contactoIsOk = true;
      productIsOk = true;
      scannedValue4 = '';
      print('Tercero seleccionado: ${currentTercero.toMap()}');
      emit(SelectTerceroState(currentTercero));
    } catch (e, s) {
      print("❌ Error en _onSelectTerceroEvent: $e, $s");
    }
  }

  void _onLoadTercerosEvent(
      LoadTercerosEvent event, Emitter<DevolucionesState> emit) async {
    try {
      final response = await devolucionesRepository.fetAllTerceros(true);
      if (response.isNotEmpty) {
        terceros.clear();
        terceros = response;
        tercerosFilters.clear();
        tercerosFilters = terceros;
        emit(LoadTercerosSuccess(response));
      } else {
        emit(LoadTercerosFailure('No se encontraron terceros'));
      }
    } catch (e, s) {
      print("❌ Error en _onLoadTercerosEvent: $e, $s");
      emit(LoadTercerosFailure('Error al cargar los terceros'));
    }
  }

  void _onUpdateProductInfoEvent(
      UpdateProductInfoEvent event, Emitter<DevolucionesState> emit) async {
    try {
      //actualizamso el producto actual en la bd
      await db.devolucionRepository.updateProductoDevolucion(
        ProductDevolucion(
          productId: currentProduct.productId,
          barcode: currentProduct.barcode,
          name: currentProduct.name,
          quantity:

              //validamos si la cantidad es para incrementar o es para remplazar
              event.isIncrement
                  ? (currentProduct.quantity ?? 0) + (event.quantityManual ?? 0)
                  : quantitySelected,
          code: currentProduct.code,
          category: currentProduct.category,
          lotId: lotesProductCurrent.id ?? 0,
          lotName: lotesProductCurrent.name ?? "",
          otherBarcodes: currentProduct.otherBarcodes,
          productPacking: currentProduct.productPacking,
          tracking: currentProduct.tracking,
          useExpirationDate: currentProduct.useExpirationDate,
          expirationTime: currentProduct.expirationTime,
          weight: currentProduct.weight,
          weightUomName: currentProduct.weightUomName,
          volume: currentProduct.volume,
          volumeUomName: currentProduct.volumeUomName,
          uom: currentProduct.uom,
          locationId: currentProduct.locationId,
          locationName: currentProduct.locationName,
        ),
      );
      //acutalizamos el producto actual en la lista de devoluciones
      final index = productosDevolucion
          .indexWhere((p) => p.productId == currentProduct.productId);
      if (index != -1) {
        productosDevolucion[index] = ProductDevolucion(
          productId: currentProduct.productId,
          barcode: currentProduct.barcode,
          name: currentProduct.name,
          quantity: event.isIncrement
              ? (currentProduct.quantity ?? 0) + (event.quantityManual ?? 0)
              : quantitySelected,
          code: currentProduct.code,
          category: currentProduct.category,
          lotId: lotesProductCurrent.id ?? 0,
          lotName: lotesProductCurrent.name ?? "",
          otherBarcodes: currentProduct.otherBarcodes,
          productPacking: currentProduct.productPacking,
          tracking: currentProduct.tracking,
          useExpirationDate: currentProduct.useExpirationDate,
          expirationTime: currentProduct.expirationTime,
          weight: currentProduct.weight,
          weightUomName: currentProduct.weightUomName,
          volume: currentProduct.volume,
          volumeUomName: currentProduct.volumeUomName,
          uom: currentProduct.uom,
          locationId: currentProduct.locationId,
          locationName: currentProduct.locationName,
        );
      }
      add(GetProductsList());

      emit(UpdateProductInfoState());
    } catch (e, s) {
      print("❌ Error en _onUpdateProductInfoEvent: $e, $s");
    }
  }

  void _onLoaadCurrentProductEvent(
      LoadCurrentProductEvent event, Emitter<DevolucionesState> emit) {
    try {
      currentProduct = event.product;
      quantitySelected = event.product.quantity ?? 0;
      if (event.product.tracking == 'lot') {
        lotesProductCurrent = LotesProduct(
          id: event.product.lotId,
          name: event.product.lotName,
          productId: event.product.productId,
          productName: event.product.name,
        );
        add(GetLotesProduct());
      }
      print('Producto actual cargado: ${currentProduct.toMap()}');
      emit(LoadCurrentProductState(currentProduct));
    } catch (e, s) {
      print("❌ Error en _onLoaadCurrentProductEvent: $e, $s");
    }
  }

  //*evento para ver la cantidad
  void _onShowQuantityEvent(
      ShowQuantityEvent event, Emitter<DevolucionesState> emit) {
    try {
      viewQuantity = !viewQuantity;
      emit(ShowQuantityState(viewQuantity));
    } catch (e, s) {
      print("❌ Error en _onShowQuantityEvent: $e, $s");
    }
  }

  void _onSetQuantityEvent(
      SetQuantityEvent event, Emitter<DevolucionesState> emit) {
    quantitySelected += 1;
    print('Cantidad seleccionada: $quantitySelected');
    emit(SetQuantityState());
  }

  void _onSetLoteEvent(SetLoteEvent event, Emitter<DevolucionesState> emit) {}

  void _onAddProductEvent(
      Addproduct event, Emitter<DevolucionesState> emit) async {
//validamos que este producto no este ya en la lista de devoluciones

    if (productosDevolucion.any((p) =>
        p.productId == event.product.productId &&
        p.lotId == event.product.lotId)) {
      print('❌ El producto ya está en la lista de devoluciones');
      emit(AddProductFailure(
          'El producto ${event.product.name} ${event.product.tracking == 'lot' ? ' con lote ${event.product.lotName}' : ''} ya está en la lista de devoluciones. Para agregar el mismo producto con el mismo lote  debe realizarlo desde la opción de editar'));
      return;
    } else {
      //insertamos el producto en la base de datos

      await db.devolucionRepository.insertProductoDevolucion(event.product);
      productosDevolucion.add(event.product);
      print('Producto añadido: ${event.product.toMap()}');
      emit(AddProductSuccess(event.product));
    }
  }

  void _onRemoveProductEvent(
      RemoveProduct event, Emitter<DevolucionesState> emit) async {
    try {
      await db.devolucionRepository.deleteProductoDevolucion(
          event.product.productId ?? 0, event.product.lotId ?? 0);
      productosDevolucion.removeWhere((p) =>
          p.productId == event.product.productId &&
          p.lotId == event.product.lotId);
      //eliminamos el producto de la base de datos
      print('Producto eliminado: ${event.product.toMap()}');
      emit(RemoveProductSuccess());
    } catch (e, s) {
      print("❌ Error en _onRemoveProductEvent: $e, $s");
    }
  }

  void _onGetProductEvent(
      GetProductEvent event, Emitter<DevolucionesState> emit) {
    if (isDialogVisible) {
      print('Dialogo ya visible, no se puede buscar otro producto');
      return;
    }

    emit(GetProductLoading());

    lotesProductCurrent = LotesProduct();
    if (event.isManual) {
      // Buscar el producto por código de barras
      final product =
          productos.firstWhereOrNull((p) => p.productId == event.idProduct);

      if (product == null) {
        emit(GetProductFailure('Producto no encontrado'));
        scannedValue1 = '';
        return;
      }

      print('Producto encontrado: ${product.toMap()}');

      // Obtener todos los productos en devolución con el mismo productId
      final productosRelacionados = productosDevolucion
          .where((p) => p.productId == product.productId)
          .toList();
      if (productosRelacionados.isNotEmpty) {
        emit(GetProductExists(
          productosRelacionados.first,
          productosRelacionados,
        ));
        return;
      }

      // Verificar si requiere lotes
      if (product.tracking == 'lot') {
        add(GetLotesProduct());
      }

      // Actualizar el producto actual
      currentProduct = product;
      viewQuantity = false;
      quantitySelected = 0;
    } else {
      // Buscar coincidencia directa por barcode o code
      final matchedProduct = productos.firstWhere(
        (p) =>
            p.barcode?.toLowerCase() == event.barcode ||
            p.code?.toLowerCase() == event.barcode,
        orElse: () => Product(),
      );

      print('Producto encontrado:: ${matchedProduct.toMap()}');

      if (matchedProduct.barcode == null) {
        print('❌ Producto no encontrado por codigo principal');
        // Buscar en barcodes adicionales
        final matchedBarcode = allBarcodeInventario.firstWhere(
          (b) => b.barcode?.toLowerCase() == event.barcode,
          orElse: () => BarcodeInventario(),
        );

        if (matchedBarcode.barcode == null) {
          print('❌ Producto no encontrado en barcodes');
          emit(GetProductFailure('Producto no encontrado'));
          return;
        }
        print('✅ Producto encontrado en barcodes: ${matchedBarcode.toMap()}');
        //se encontro un producto con los demas barcodes
        // Buscar producto por id relacionado al barcode encontrado
        final matchedById = productos.firstWhere(
          (p) => p.productId == matchedBarcode.idProduct,
          orElse: () => Product(),
        );

        if (matchedById.productId != null) {
          print('✅ Producto encontrado por ID: ${matchedById.name}');

          final productosRelacionados = productosDevolucion
              .where((p) => p.productId == matchedById.productId)
              .toList();

          if (productosRelacionados.isNotEmpty) {
            emit(GetProductExists(
              productosRelacionados.first,
              productosRelacionados,
            ));
            return;
          }
          if (matchedById.tracking == 'lot') {
            add(GetLotesProduct());
          }
          // Actualizar el producto actual
          currentProduct = matchedById;
          viewQuantity = false;
          quantitySelected = 0;
          emit(GetProductSuccess(currentProduct, true));
          return;
        } else {
          print('❌ Producto no encontrado por ID');
          print('❌ Producto no encontrado en barcodes');
          emit(GetProductFailure('Producto no encontrado'));
          return;
        }
      }

      print('Producto encontrado: ${matchedProduct.toMap()}');
      // Obtener todos los productos en devolución con el mismo productId
      final productosRelacionados = productosDevolucion
          .where((p) => p.productId == matchedProduct.productId)
          .toList();

      if (productosRelacionados.isNotEmpty) {
        emit(GetProductExists(
          productosRelacionados.first,
          productosRelacionados,
        ));
        return;
      }
      if (matchedProduct.tracking == 'lot') {
        add(GetLotesProduct());
      }
      // Actualizar el producto actual
      currentProduct = matchedProduct;
      viewQuantity = false;
      quantitySelected = 0;
    }

    emit(GetProductSuccess(currentProduct, true));
  }

  void _onGetProductsBD(
      GetProductsList event, Emitter<DevolucionesState> emit) async {
    try {
      emit(GetProductsLoading());
      final response =
          await db.productoInventarioRepository.getAllUniqueProducts();
      productos.clear();
      productosFilters.clear();
      print('productos: ${response.length}');
      if (response.isNotEmpty) {
        productos = response;
        productosFilters = productos;
        //mandamos a traer los producto que tenemos listo para la devolucion guardados en la base de datos
        productosDevolucion =
            await db.devolucionRepository.getAllProductosDevoluciones();

        print('productosDevolucion: ${productosDevolucion.length}');

        emit(GetProductsSuccess(response));
      } else {
        emit(GetProductsFailure('No se encontraron productos'));
      }
    } catch (e, s) {
      emit(GetProductsFailure('Error al cargar los productos'));
      print('Error en el fetch de productos: $e=>$s');
    }
  }
}
