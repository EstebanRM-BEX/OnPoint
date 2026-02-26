import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/features/user/data/models/user_configuration_model.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/inventario/data/inventario_repository.dart';
import 'package:wms_app/src/presentation/views/inventario/models/response_products_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_lotes_product_model.dart';
import 'package:wms_app/src/presentation/views/transferencias/data/transferencias_repository.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/models/request_create_trasnfer_model.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/models/response_create_transfer_mode.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/models/response_validate_stock_model.dart';

part 'crate_transfer_event.dart';
part 'crate_transfer_state.dart';

class CreateTransferBloc
    extends Bloc<CreateTransferEvent, CreateTransferState> {
  // //*validaciones de campos del estado de la vista
  bool loteIsOk = false;
  bool isLocationOk = true;
  bool isProductOk = true;
  bool isLocationDestOk = true;
  bool isQuantityOk = true;
  bool isLoteOk = true;

  //*variables para validar
  bool locationIsOk = false;
  bool productIsOk = false;
  bool locationDestIsOk = false;
  bool quantityIsOk = false;
  bool viewQuantity = false;
  //*valores de scanvalueS

  String scannedValue1 = '';
  String scannedValue2 = '';
  String scannedValue3 = '';
  String scannedValue4 = '';
  String scannedValue7 = '';

  String oldLocation = '';
  //date de inicio y fin del producto
  String dateInicio = '';
  String dateFin = '';

  //date de inicio y fin de la transferencia
  String dateTransferInicio = '';

  //*lista de ubicaciones
  List<ResultUbicaciones> ubicaciones = [];
  List<ResultUbicaciones> ubicacionesFilters = [];

  //*lista de productos
  List<Product> productos = [];
  List<Product> productosFilters = [];

  //lista de prodcutos ya agregados a la transferencia
  List<Product> productosCreateTransfer = [];

  List<BarcodeInventario> listOfBarcodes = [];

  List<BarcodeInventario> allBarcodeInventario = [];

  //lista de lotes de un producto
  List<LotesProduct> listLotesProduct = [];
  List<LotesProduct> listLotesProductFilters = [];

  TextEditingController newLoteController = TextEditingController();
  TextEditingController searchControllerLote = TextEditingController();
  TextEditingController dateLoteController = TextEditingController();
  TextEditingController searchControllerLocation = TextEditingController();
  TextEditingController searchControllerProducts = TextEditingController();

  dynamic quantitySelected = 0;

  //*configuracion del usuario //permisos
  UserConfigurationModel configurations = UserConfigurationModel();

  //*variables de modelos actuales
  ResultUbicaciones? currentUbication;
  ResultUbicaciones? currentUbicationDest;

  Product? currentProduct;
  LotesProduct? currentProductLote;

  //*base de datos
  DataBaseSqlite db = DataBaseSqlite();

  //repositorios
  final InventarioRepository _inventarioRepository = InventarioRepository();

  //*repositorio
  final TransferenciasRepository _transferenciasRepository =
      TransferenciasRepository();

  CreateTransferBloc() : super(CrateTransferInitial()) {
    on<LoadConfigurationsUserCreateTransferEvent>(
        _onLoadConfigurationsUserEvent);

    on<ValidateFieldsEvent>(_onValidateFields);

    //*metodo para cargar las ubicaciones
    on<GetLocationsEvent>(_onLoadLocations);
    //*metodo para obtener los productos de la bd
    on<GetProductsFromDBEvent>(_onGetProductsFromDBEvent);

    //metodo para buscar una ubicacion
    on<SearchLocationEvent>(_onSearchLocationEvent);
    //*metodo para bucar un producto
    on<SearchProductEvent>(_onSearchProductEvent);
    //*metodo para validar la ubicacion
    on<ChangeLocationIsOkEvent>(_onChangeLocationIsOkEvent);
    //*metodo para validar el producto
    on<ChangeProductIsOkEvent>(_onChangeProductIsOkEvent);

    //*metodo para crear un lote a un producto
    on<CreateLoteProduct>(_onCreateLoteProduct);
    on<SearchLotevent>(_onSearchLoteEvent);
    //*metodo para obtener todos los lotes de un producto
    on<GetLotesProduct>(_onGetLotesProduct);
    on<SelectecLoteEvent>(_onChangeLoteIsOkEvent);

    //*cantidad
    on<ChangeIsOkQuantity>(_onChangeQuantityIsOkEvent);
    //*evento para ver la cantidad
    on<ShowQuantityEvent>(_onShowQuantityEvent);
    on<ChangeQuantitySeparate>(_onChangeQuantitySelectedEvent);

    //*evento para  limpiar los datos de la transferencia y construccion del producto acutal
    on<ClearDataCreateTransferEvent>(_onClearDataCreateTransferEvent);

//*evento para aumentar la cantidad
    on<AddQuantitySeparate>(_onAddQuantitySeparateEvent);

    //*evento para obtener los barcodes de un producto por paquete
    on<FetchBarcodesProductEvent>(_onFetchBarcodesProductEvent);
    //meotod para obtener todos los other barcodes y product_packing de inventario
    on<FetchAllBarcodesInventarioEvent>(_onFetchAllBarcodesInventarioEvent);

    //*evento para agregar los productos a la lista de transferencia
    on<AddProductCreateTransferEvent>(_onAddProductCreateTransferEvent);

    //*evento para eliminar un producto ya agregado de la transferencia
    on<RemoveProductFromTransferEvent>(_onRemoveProductFromTransferEvent);

    //*evento para obtener los productos de la bd local de crear transferencia
    on<GetProductsCreateTransferEvent>(_onGetProductsCreateTransferEvent);

    //*evento para enviar y crear la transferencia
    on<CreateNewTransferEvent>(_onCreateTransferEvent);

    //evento para validar el stock de un producto antes de agregar a la transferencia
    on<ValidateStockProductEvent>(_onValidateStockProductEvent);
  }

  void _onValidateStockProductEvent(ValidateStockProductEvent event,
      Emitter<CreateTransferState> emit) async {
    try {
      emit(ValidateStockLoading());

      // Lógica para validar el stock del producto
      final response = await _transferenciasRepository.validateStockTransfer(
        currentProduct?.productId ?? 0,
        currentUbication?.id ?? 0,
        currentProduct?.tracking == "lot" ? currentProductLote?.id ?? 0 : 0,
        event.quantity,
        true,
      );

      if (response.result?.code == 200 &&
          response.result?.resumenStock?.esSuficiente == true) {
        emit(ValidateStockSuccess(response));
        add(AddProductCreateTransferEvent(
          event.quantity,
          currentProduct ?? Product(),
        ));
      } else {
        emit(ValidateStockFailure(response.result?.msg ?? ""));
      }
    } catch (e, s) {
      print("❌ Error en el ValidateStockProductEvent $e ->$s");
      emit(ValidateStockFailure('Error al validar el stock del producto'));
    }
  }

  void _onCreateTransferEvent(
      CreateTransferEvent event, Emitter<CreateTransferState> emit) async {
    try {
      emit(CreateTransferLoading());

      //obtenemos el id del operario
      final userid = await PrefUtils.getUserId();

      final request = CreateTransferRequest(
        dateStart: dateTransferInicio,
        dateEnd: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        idAlmacen: currentUbication?.idWarehouse ?? 0,
        idUbicacionOrigen: currentUbication?.id ?? 0,
        idUbicacionDestino: currentUbicationDest?.id ?? 0,
        idOperario: userid,
        fechaTransaccion:
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        listItems: productosCreateTransfer
            .map((product) => ListItem(
                  idProducto: product.productId ?? 0,
                  cantidadEnviada: product.quantityDone ?? 0,
                  idLote: product.tracking == "lot" ? product.lotId ?? 0 : 0,
                  timeLine: product.time ?? 0,
                ))
            .toList(),
      );

      final response =
          await _transferenciasRepository.createTransfer(request, true);
      if (response.result?.code == 200) {
        //borramos todos los productos de la bd local de crear transferencia
        await db.productCreateTransferRepository
            .deleteAllProductsCreateTransfer();
        //limpiamos la lista temporal
        productosCreateTransfer.clear();

        emit(CreateTransferSuccess(response));
        add(ClearDataCreateTransferEvent(isClearProduct: false));
        dateTransferInicio = '';
      } else {
        emit(CreateTransferFailure(response.result?.msg ?? ""));
      }
    } catch (e, s) {
      print("❌ Error en el CreateTransferEvent $e ->$s");
      emit(CreateTransferFailure(e.toString()));
    }
  }

  void _onGetProductsCreateTransferEvent(GetProductsCreateTransferEvent event,
      Emitter<CreateTransferState> emit) async {
    try {
      emit(GetProductsLoadingBD());
      final response = await db.productCreateTransferRepository
          .getAllProductsCreateTransfer();
      productosCreateTransfer.clear();
      if (response.isNotEmpty) {
        productosCreateTransfer = response;
        print(
            'productos de la bd de crear transferencia::::: ${productosCreateTransfer.length}');
        emit(GetProductsSuccessBD(response));
      } else {
        emit(GetProductsFailure('No se encontraron productos'));
      }
    } catch (e, s) {
      emit(GetProductsFailure('Error al cargar los productos'));
      print('Error en el fetch de productos: $e=>$s');
    }
  }

  void _onRemoveProductFromTransferEvent(RemoveProductFromTransferEvent event,
      Emitter<CreateTransferState> emit) async {
    try {
      emit(ProductRemovingFromTransferLoadingState());
      await db.productCreateTransferRepository
          .deleteProductById(event.product.productId ?? 0);
      //elimimamos el producto de la lista temporal
      productosCreateTransfer
          .removeWhere((prod) => prod.productId == event.product.productId);
      emit(ProductRemovedFromTransferState());
    } catch (e, s) {
      print("❌ Error en _onRemoveProductFromTransferEvent: $e, $s");
      emit(ProductRemoveFromTransferErrorState(
          'Error al eliminar el producto de la transferencia'));
    }
  }

  void _onAddProductCreateTransferEvent(AddProductCreateTransferEvent event,
      Emitter<CreateTransferState> emit) async {
    try {
      //emitimos estado de carga
      emit(ProductAddingToTransferLoadingState());
      //todo procedemos a calcular el tiempo de separacion del producto

      DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
      String formattedDate = formatter.format(DateTime.now());

      if (dateTransferInicio.isEmpty) {
        dateTransferInicio =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      }

      //mostramos el tiempo de inicio y fin
      print('Fecha de inicio: $dateInicio');
      dateFin = DateTime.now().toString();
      print('Fecha de fin: $dateFin');

      //calculamos la diferencia de tiempo
      if (dateInicio == "" || dateInicio == null) {
        dateInicio = DateTime.now().toString();
      }
      if (dateFin == "" || dateFin == null) {
        dateFin = DateTime.now().toString();
      }
      DateTime dateStart = DateTime.parse(dateInicio);
      DateTime dateEnd = DateTime.parse(dateFin);

      var difference = dateEnd.difference(dateStart);
      int time = difference.inSeconds;

      //todo agregamos el producto a la lista de transferencia en la bd local

      final productAdd = Product(
        productId: event.product.productId,
        name: event.product.name,
        barcode: event.product.barcode,
        tracking: event.product.tracking,
        weight: event.product.weight,
        volume: event.product.volume,
        volumeUomName: event.product.volumeUomName,
        weightUomName: event.product.weightUomName,
        useExpirationDate: event.product.useExpirationDate,
        code: event.product.code,
        time: time,
        dateStart: dateInicio,
        dateEnd: DateTime.now().toString(),
        quantityDone: event.quantity,
        dateTransaction: formattedDate,
        uom: event.product.uom,
        lotId: event.product.tracking == "lot" ? currentProductLote?.id : 0,
        lotName:
            event.product.tracking == "lot" ? currentProductLote?.name : '',
        expirationDateLote: event.product.tracking == "lot"
            ? currentProductLote?.expirationDate
            : null,
      );

      await db.productCreateTransferRepository.insertSingleProduct(productAdd);

      //agregamos el producto a la lista temporal
      productosCreateTransfer.add(productAdd);
      emit(ProductAddedToTransferState());
      //todo limpiamos las variables
      add(ClearDataCreateTransferEvent(isClearProduct: true));
    } catch (e, s) {
      print("❌ Error en _onAddProductCreateTransferEvent: $e, $s");
      emit(ProductAddToTransferErrorState(
          'Error al agregar el producto a la transferencia'));
    }
  }

  void _onFetchAllBarcodesInventarioEvent(FetchAllBarcodesInventarioEvent event,
      Emitter<CreateTransferState> emit) async {
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

  //*evento para obtener los barcodes de un producto por paquete
  void _onFetchBarcodesProductEvent(FetchBarcodesProductEvent event,
      Emitter<CreateTransferState> emit) async {
    try {
      listOfBarcodes.clear();

      final response = await db.barcodesInventarioRepository.getBarcodesProduct(
        currentProduct?.productId ?? 0,
      );

      if (response.isNotEmpty) {
        listOfBarcodes = response;
        emit(BarcodesProductLoadedState(listOfBarcodes: listOfBarcodes));
      } else {
        emit(BarcodesProductLoadedState(listOfBarcodes: []));
        return;
      }
    } catch (e, s) {
      print("❌ Error en _onFetchBarcodesProductEvent: $e, $s");
    }
    emit(BarcodesProductLoadedState(listOfBarcodes: listOfBarcodes));
  }

  void _onClearDataCreateTransferEvent(
    ClearDataCreateTransferEvent event,
    Emitter<CreateTransferState> emit,
  ) {
    try {
      emit(ClearDataCreateTransferLoadingState());

      if (event.isClearProduct) {
        // Limpiar solo las variables relacionadas con las ubicaciones
        loteIsOk = false;
        isProductOk = true;
        isQuantityOk = true;
        isLoteOk = true;

        //*variables para validar
        productIsOk = false;
        quantityIsOk = false;
        viewQuantity = false;
        //*valores de scanvalueS

        scannedValue1 = '';
        scannedValue2 = '';
        scannedValue3 = '';
        scannedValue4 = '';
        scannedValue7 = '';

        listOfBarcodes.clear();

        listLotesProduct.clear();
        listLotesProductFilters.clear();

        quantitySelected = 0;
        currentProduct = null;
        currentProductLote = null;

        dateInicio = '';
        dateFin = '';
      } else {
        //limpiamos todo, producto, ubicacion y cantidad
        currentUbication = null;
        currentUbicationDest = null;
        isLocationOk = true;
        isLocationDestOk = true;
        locationIsOk = false;
        locationDestIsOk = false;

        loteIsOk = false;
        isProductOk = true;
        isQuantityOk = true;
        isLoteOk = true;

        //*variables para validar
        productIsOk = false;
        quantityIsOk = false;
        viewQuantity = false;
        //*valores de scanvalueS

        scannedValue1 = '';
        scannedValue2 = '';
        scannedValue3 = '';
        scannedValue4 = '';
        scannedValue7 = '';

        listOfBarcodes.clear();

        listLotesProduct.clear();
        listLotesProductFilters.clear();

        quantitySelected = 0;
        currentProduct = null;
        currentProductLote = null;

        dateInicio = '';
        dateFin = '';
      }

      emit(ClearDataCreateTransferState());
    } catch (e, s) {
      print("❌ Error en _onClearDataCreateTransferEvent: $e, $s");
    }
  }

  // //*evento para aumentar la cantidad
  void _onAddQuantitySeparateEvent(
      AddQuantitySeparate event, Emitter<CreateTransferState> emit) async {
    try {
      quantitySelected = quantitySelected + event.quantity;

      emit(ChangeQuantitySeparateStateSuccess(quantitySelected));
    } catch (e, s) {
      emit(ChangeQuantitySeparateStateError('Error al aumentar cantidad'));
      print("❌ Error en el AddQuantitySeparate $e ->$s");
    }
  }

  void _onChangeQuantitySelectedEvent(
      ChangeQuantitySeparate event, Emitter<CreateTransferState> emit) async {
    try {
      if (event.quantity > 0.0) {
        quantitySelected = event.quantity;
      }
      emit(ChangeQuantitySeparateState(quantitySelected));
    } catch (e, s) {
      print('Error en _onChangeQuantitySelectedEvent: $e, $s');
    }
  }

  //*evento para ver la cantidad
  void _onShowQuantityEvent(
      ShowQuantityEvent event, Emitter<CreateTransferState> emit) {
    try {
      viewQuantity = !viewQuantity;
      emit(ShowQuantityState(viewQuantity));
    } catch (e, s) {
      print("❌ Error en _onShowQuantityEvent: $e, $s");
    }
  }

  void _onChangeQuantityIsOkEvent(
      ChangeIsOkQuantity event, Emitter<CreateTransferState> emit) async {
    if (event.isOk) {
      quantityIsOk = true;
    }
    emit(ChangeQuantityIsOkState(
      quantityIsOk,
    ));
  }

  void _onChangeLoteIsOkEvent(
      SelectecLoteEvent event, Emitter<CreateTransferState> emit) async {
    try {
      currentProductLote = event.lote;
      loteIsOk = true;
      isLoteOk = true;
      add(ChangeIsOkQuantity(true, currentProduct?.productId ?? 0));
      quantityIsOk = true;

      emit(ChangeLoteIsOkState(
        loteIsOk,
      ));
    } catch (e, s) {
      print('Error en el SelectecLoteEvent de inventario $s ->$e');
    }
  }

  //*metodo para obtener todos los lotes de un producto
  void _onGetLotesProduct(
      GetLotesProduct event, Emitter<CreateTransferState> emit) async {
    try {
      emit(GetLotesProductLoading());

      // Siempre obtener los lotes frescos del servidor
      final response = await _inventarioRepository.fetchAllLotesProduct(
          false, currentProduct?.productId ?? 0);

      listLotesProduct = response;
      listLotesProductFilters = response;
      emit(GetLotesProductSuccess(response));
    } catch (e, s) {
      emit(GetLotesProductFailure('Error al obtener los lotes del producto'));
      print('Error en _onGetLotesProduct: $e\n$s');
    }
  }

  void _onCreateLoteProduct(
      CreateLoteProduct event, Emitter<CreateTransferState> emit) async {
    try {
      emit(CreateLoteProductLoading());
      final response = await _inventarioRepository.createLote(
        false,
        currentProduct?.productId ?? 0,
        event.nameLote,
        event.fechaCaducidad,
      );

      if (response.result?.code == 200) {
        // 1. Capturamos el objeto del nuevo lote
        final newLote = response.result?.result ?? LotesProduct();

        // 2. Agregamos el nuevo lote a la lista PRINCIPAL
        listLotesProduct.add(newLote);

        // 3. Actualizamos la lista de FILTROS creando una copia fresca de la principal
        // Esto evita que se agregue dos veces si las listas compartían referencia en memoria
        listLotesProductFilters = List.from(listLotesProduct);

        // 4. Actualizamos variables de estado y UI
        currentProductLote = newLote;
        loteIsOk = true;

        dateLoteController.clear();
        newLoteController.clear();

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

  void _onSearchLoteEvent(
      SearchLotevent event, Emitter<CreateTransferState> emit) async {
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

  void _onChangeProductIsOkEvent(
      ChangeProductIsOkEvent event, Emitter<CreateTransferState> emit) async {
    if (event.productIsOk) {
      currentProduct = event.productSelect;
      //*traemos todos los codigos de barras por paquete del producto
      add(FetchBarcodesProductEvent());
      dateInicio = DateTime.now().toString();

      productIsOk = event.productIsOk;
      if (currentProduct?.tracking == "lot") {
        add(GetLotesProduct(
          isManual: true,
          idLote: currentProduct?.lotId ?? 0,
        ));
      } else {
        // si el producto no tiene lote pasamos directo a la cantidad
        add(ChangeIsOkQuantity(
          true,
          event.productSelect.productId ?? 0,
        ));
      }
      // emitimos el estado
      emit(ChangeProductOrderIsOkState(
        productIsOk,
      ));
    }
  }

  void _onChangeLocationIsOkEvent(
      ChangeLocationIsOkEvent event, Emitter<CreateTransferState> emit) async {
    try {
      if (isLocationOk) {
        //valdiamos si es la ubicacion de destino
        if (event.isLocationDest) {
          currentUbicationDest = event.locationSelect;
          locationDestIsOk = true;
          add(SearchLocationEvent(''));
          searchControllerLocation.clear();
          emit(ChangeLocationIsOkState(
            locationIsOk,
            true,
          ));
        } else {
          //validamos si dateTransferInicio esta vacio para asignarle la fecha de inicio
          if (dateTransferInicio.isEmpty) {
            dateTransferInicio =
                DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
          }
          //*cambiamos la variable de la ubicacion actual
          currentUbication = event.locationSelect;
          locationIsOk = true;
          add(SearchLocationEvent(''));
          searchControllerLocation.clear();
          emit(ChangeLocationIsOkState(locationIsOk, false));
        }
      }
    } catch (e, s) {
      print("❌ Error en el ChangeLocationIsOkEvent $e ->$s");
    }
  }

  void _onSearchLocationEvent(
      SearchLocationEvent event, Emitter<CreateTransferState> emit) async {
    try {
      emit(SearchLoading());
      ubicacionesFilters = [];
      ubicacionesFilters = ubicaciones;
      final query = event.query.toLowerCase();
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

  void _onSearchProductEvent(
    SearchProductEvent event,
    Emitter<CreateTransferState> emit,
  ) async {
    try {
      print('🔍 Buscando productos con query: "${event.query}"');
      emit(SearchLoading());

      productosFilters = [];
      productosFilters = productos;
      final query = event.query.toLowerCase();
      if (query.isEmpty) {
        productosFilters = productos;
      } else {
        final List<Product> filtrados = productos.where((product) {
          final name = (product.name ?? '').toLowerCase();
          final code = (product.code ?? '').toString().trim();
          final barcode = (product.barcode ?? '').toString().trim();

          return name.contains(query.toLowerCase()) ||
              code.contains(query) ||
              barcode.contains(query);
        }).toList();
        productosFilters = filtrados;
      }
      emit(SearchProductSuccess(productosFilters));
    } catch (e, s) {
      print('❌ Error en SearchProductEvent: $e\n$s');
      emit(SearchFailure(e.toString()));
    }
  }

  void _onGetProductsFromDBEvent(
      GetProductsFromDBEvent event, Emitter<CreateTransferState> emit) async {
    try {
      emit(GetProductsLoadingBD());
      final response = await db.productoInventarioRepository.getAllProducts();
      productos.clear();
      productosFilters.clear();
      if (response.isNotEmpty) {
        productos = response;
        productosFilters = response;
        print('productos de la bd::::: ${productos.length}');
        emit(GetProductsSuccessBD(response));
      } else {
        emit(GetProductsFailure('No se encontraron productos'));
      }
    } catch (e, s) {
      emit(GetProductsFailure('Error al cargar los productos'));
      print('Error en el fetch de productos: $e=>$s');
    }
  }

  void _onLoadLocations(
      GetLocationsEvent event, Emitter<CreateTransferState> emit) async {
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

  void _onValidateFields(
      ValidateFieldsEvent event, Emitter<CreateTransferState> emit) {
    try {
      switch (event.field) {
        case 'location':
          isLocationOk = event.isOk;
          break;
        case 'product':
          isProductOk = event.isOk;
          break;
        case 'locationDest':
          isLocationDestOk = event.isOk;
          break;
        case 'quantity':
          isQuantityOk = event.isOk;
          break;
        case 'lote':
          scannedValue4 = '';
          isLoteOk = event.isOk;
          break;
      }
      emit(ValidateFieldsStateSuccess(event.isOk));
    } catch (e, s) {
      emit(ValidateFieldsStateError('Error al validar campos'));
      print("❌ Error en el ValidateFieldsEvent $e ->$s");
    }
  }

  //* evento para cargar la configuracion del usuario
  void _onLoadConfigurationsUserEvent(
      LoadConfigurationsUserCreateTransferEvent event,
      Emitter<CreateTransferState> emit) async {
    try {
      int userId = await PrefUtils.getUserId();
      final response =
          await db.configurationsRepository.getConfiguration(userId);

      if (response != null) {
        emit(ConfigurationLoaded(response));
        configurations = response;
      } else {
        emit(ConfigurationError('Error al cargar LoadConfigurationsUser'));
      }
    } catch (e, s) {
      print('❌ Error en LoadConfigurationsUser $e =>$s');
    }
  }
}
