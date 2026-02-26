// ignore_for_file: unnecessary_type_check

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/features/user/data/models/user_configuration_model.dart';
import 'package:wms_app/core/utils/formats_utils.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/src/presentation/models/novedades_response_model.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/inventario/data/inventario_repository.dart';
import 'package:wms_app/src/presentation/views/recepcion/data/recepcion_repository.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/recepcion_response_batch_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/repcion_requets_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_lotes_product_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';

part 'recepcion_batch_event.dart';
part 'recepcion_batch_state.dart';

class RecepcionBatchBloc
    extends Bloc<RecepcionBatchEvent, RecepcionBatchState> {
  //*base de datos
  DataBaseSqlite db = DataBaseSqlite();
  //*configuracion del usuario //permisos
  UserConfigurationModel configurations = UserConfigurationModel();
  //*repository
  final RecepcionRepository _recepcionRepository = RecepcionRepository();

  List<ReceptionBatch> listReceptionBatch = [];
  List<ReceptionBatch> listReceptionBatchFilter = [];

  List<LineasRecepcionBatch> listProductsEntrada = [];
  List<LineasRecepcionBatch> listOfProductsName = [];
  //*lista de barcodes
  List<Barcodes> listOfBarcodes = [];
  List<Barcodes> listAllOfBarcodes = [];

  ReceptionBatch resultEntrada = ReceptionBatch();

  LineasRecepcionBatch currentProduct = LineasRecepcionBatch();

  //*variables para validar
  bool productIsOk = false;
  bool loteIsOk = false;
  bool quantityIsOk = false;
  bool locationsDestIsok = false;
  bool isKeyboardVisible = false;
  bool viewQuantity = false;

  // //*validaciones de campos del estado de la vista
  bool isProductOk = true;
  bool isQuantityOk = true;
  bool isLoteOk = true;
  bool isLocationDestOk = true;
  dynamic quantitySelected = 0;

  //*lista de novedades
  List<Novedad> novedades = [];

  //*valores de scanvalue

  String scannedValue2 = ''; //producto
  String scannedValue3 = ''; //cantidad
  String scannedValue4 = ''; //lote
  String scannedValue5 = ''; //all product
  String scannedValue6 = ''; //ubicacion destino
  String selectLote = '';
  String selectedAlmacen = '';
  String dateInicio = '';
  String dateFin = "";

  //*lista de ubicaciones
  List<ResultUbicaciones> ubicaciones = [];
  List<ResultUbicaciones> ubicacionesFilters = [];

  //lista de lotes de un producto
  List<LotesProduct> listLotesProduct = [];
  List<LotesProduct> listLotesProductFilters = [];

  ResultUbicaciones? currentUbicationDest;
  LotesProduct lotesProductCurrent = LotesProduct();

  //controller
  final TextEditingController searchControllerRecepcionBatch =
      TextEditingController();
  TextEditingController newLoteController = TextEditingController();
  TextEditingController dateLoteController = TextEditingController();
  TextEditingController searchControllerLote = TextEditingController();
  TextEditingController locationDestController = TextEditingController();
  TextEditingController loteController = TextEditingController();

  TextEditingController searchControllerLocationDest = TextEditingController();
  //repositorio de inventario
  InventarioRepository inventarioRepository = InventarioRepository();
  RecepcionBatchBloc() : super(RecepcionBatchInitial()) {
    on<RecepcionBatchEvent>((event, emit) {});

    //* obtener todas las repeciones por batch
    on<FetchRecepcionBatchEvent>(_onFetchRecepcionBatchEvent);
    //*cargar toddas las recepciones por batch desde la bd
    on<FetchRecepcionBatchEventFromBD>(_onFetchRecepcionBatchEventFromBD);

    //* buscar una orden de compra
    on<SearchReceptionEvent>(_onSearchOrderEvent);

    //*asignar un usuario a una orden de compra
    on<AssignUserToReception>(_onAssignUserToOrder);

    //*metodo para empezar o terminar timepo
    on<StartOrStopTimeOrder>(_onStartOrStopTimeOrder);

    //*obtener todos los productos de una entrada
    on<GetPorductsToEntradaBatch>(_onGetProductsToEntrada);

    on<CurrentOrdenesCompraBatch>(_onCurrentOrdenesCompra);

    //*evento para validar los campos de la vista
    on<ValidateFieldsOrderEvent>(_onValidateFieldsOrder);

    //*evento para cambiar la cantidad seleccionada
    on<ChangeQuantitySeparate>(_onChangeQuantitySelectedEvent);
    on<AddQuantitySeparate>(_onAddQuantitySeparateEvent);

    //*cambiar el estado de las variables
    on<ChangeProductIsOkEvent>(_onChangeProductIsOkEvent);

    //*cantidad
    on<ChangeIsOkQuantity>(_onChangeQuantityIsOkEvent);

    //*cambiar el estado de las variables
    on<ChangeLocationDestIsOkEvent>(_onChangeLocationIsOkEvent);
    //*evento para ver la cantidad
    on<ShowQuantityOrderEvent>(_onShowQuantityEvent);

    //*evento para obtener las novedades
    on<LoadAllNovedadesReceptionEvent>(_onLoadAllNovedadesEvent);
    add(LoadAllNovedadesReceptionEvent());

    //*evento para cargar la info del producto
    on<FetchPorductOrder>(_onFetchPorductOrder);

    //*metodo para obtener todos los lotes de un producto
    on<GetLotesProduct>(_onGetLotesProduct);

    on<FilterUbicacionesAlmacenEvent>(_onFilterUbicacionesEvent);

    //metodo para buscar una ubicacion
    on<SearchLocationEvent>(_onSearchLocationEvent);

    //*metodo para cargar las ubicaciones
    on<GetLocationsDestReceptionBatchEvent>(_onLoadLocations);

    //*obtener las configuraciones y permisos del usuario desde la bd
    on<LoadConfigurationsUserReception>(_onLoadConfigurationsUserEvent);

    on<CleanFieldsEvent>(_onCleanFieldsEvent);

    //*metodo para enviar el producto a wms
    on<SendProductToOrder>(_onSendProductToOrder);

    //*finalizarRececpcionProducto
    on<FinalizarRecepcionProducto>(_onFinalizarRecepcionProducto);

    //*finalizarRececpcionProductoSplit
    on<FinalizarRecepcionProductoSplit>(_onFinalizarRecepcionProductoSplit);

    //*metodo para crear un lote a un producto
    on<CreateLoteProduct>(_onCreateLoteProduct);

    //metodo para buscar un lote
    on<SearchLotevent>(_onSearchLoteEvent);

    on<SelectecLoteEvent>(_onChangeLoteIsOkEvent);
    on<ViewProductImageEvent>(_onViewProductImageEvent);
  }

  void _onViewProductImageEvent(
      ViewProductImageEvent event, Emitter<RecepcionBatchState> emit) async {
    try {
      print('Obteniendo imagen del producto con ID: ${event.idProduct}');
      emit(ViewProductImageLoading());

      final response =
          await inventarioRepository.viewUrlImageProduct(event.idProduct, true);

      if (response.result?.code == 200) {
        if (response.result?.result == null ||
            response.result?.result?.url == null ||
            response.result?.result?.url == '') {
          emit(ViewProductImageFailure('Imagen no disponible'));
          return;
        }
        emit(ViewProductImageSuccess(response.result?.result?.url ?? ''));
      } else {
        emit(ViewProductImageFailure('Imagen no disponible'));
      }
    } catch (e, s) {
      print('Error en el ViewProductImageEvent: $e, $s');
      emit(ViewProductImageFailure(e.toString()));
    }
  }

  void _onChangeLoteIsOkEvent(
      SelectecLoteEvent event, Emitter<RecepcionBatchState> emit) async {
    //agregamos el lote al producto

    selectLote = event.lote.name ?? '';

    lotesProductCurrent = event.lote;

    //actualizamos el lote id
    await db.productsEntradaBatchRepository.setFieldTableProductEntradaBatch(
      currentProduct.idRecepcion ?? 0,
      int.parse(currentProduct.productId),
      "lot_id",
      event.lote.id,
      currentProduct.idMove ?? 0,
    );
    //actualizamos el lote name
    await db.productsEntradaBatchRepository.setFieldTableProductEntradaBatch(
      currentProduct.idRecepcion ?? 0,
      int.parse(currentProduct.productId),
      "lot_name",
      event.lote.name,
      currentProduct.idMove ?? 0,
    );

    await db.productsEntradaBatchRepository.setFieldTableProductEntradaBatch(
      currentProduct.idRecepcion ?? 0,
      int.parse(currentProduct.productId),
      "lote_date",
      event.lote.expirationDate ?? '',
      currentProduct.idMove ?? 0,
    );

    loteIsOk = true;
    isLoteOk = true;

    if (configurations.result?.result?.scanDestinationLocationReception ==
        false) {
      add(ChangeIsOkQuantity(
        currentProduct.idRecepcion ?? 0,
        true,
        int.parse(currentProduct.productId),
        currentProduct.idMove ?? 0,
      ));
    }
    emit(ChangeLoteOrderIsOkState(
      loteIsOk,
    ));
  }

  void _onSearchLoteEvent(
      SearchLotevent event, Emitter<RecepcionBatchState> emit) async {
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

  //metodo pea crar un lote a un producto
  void _onCreateLoteProduct(
      CreateLoteProduct event, Emitter<RecepcionBatchState> emit) async {
    try {
      emit(CreateLoteProductLoading());
      final response = await _recepcionRepository.createLote(
        false,
        int.parse(currentProduct.productId),
        event.nameLote,
        event.fechaCaducidad,
      );

      if (response.result?.code == 200) {
        //agregamos el nuevo lote a la lista de lotes
        listLotesProductFilters.add(response.result?.result ?? LotesProduct());
        selectLote = response.result?.result?.name ?? '';
        lotesProductCurrent = response.result?.result ?? LotesProduct();

        await db.productsEntradaBatchRepository
            .setFieldTableProductEntradaBatch(
          currentProduct.idRecepcion ?? 0,
          int.parse(currentProduct.productId),
          "lot_id",
          response.result?.result?.id ?? 0,
          currentProduct.idMove ?? 0,
        );
        //actualizamos el lote name

        await db.productsEntradaBatchRepository
            .setFieldTableProductEntradaBatch(
          currentProduct.idRecepcion ?? 0,
          int.parse(currentProduct.productId),
          "lot_name",
          response.result?.result?.name ?? '',
          currentProduct.idMove ?? 0,
        );

        await db.productsEntradaBatchRepository
            .setFieldTableProductEntradaBatch(
          currentProduct.idRecepcion ?? 0,
          int.parse(currentProduct.productId),
          "lote_date",
          response.result?.result?.expirationDate ?? '',
          currentProduct.idMove ?? 0,
        );

        loteIsOk = true;

        dateLoteController.clear();
        newLoteController.clear();

        emit(CreateLoteProductSuccess());
      } else {
        emit(CreateLoteProductFailure(response.result?.msg ??
            'Error al crear el lote concactarse con el administrador'));
      }
    } catch (e, s) {
      emit(CreateLoteProductFailure('Error al crear el lote'));
      print('Error en el _onCreateLoteProduct: $e, $s');
    }
  }

  //*Metodo para finalizar un producto Split
  void _onFinalizarRecepcionProductoSplit(FinalizarRecepcionProductoSplit event,
      Emitter<RecepcionBatchState> emit) async {
    try {
      emit(FinalizarRecepcionProductoSplitLoading());

      dateFin = DateTime.now().toString();

      //marcamos tiempo final de separacion
      await db.productsEntradaBatchRepository.setFieldTableProductEntradaBatch(
          currentProduct.idRecepcion ?? 0,
          int.parse(currentProduct.productId),
          "date_end",
          dateFin,
          currentProduct.idMove ?? 0);
      //actualizamso el estado del producto como separado
      await db.productsEntradaBatchRepository.setFieldTableProductEntradaBatch(
          currentProduct.idRecepcion ?? 0,
          int.parse(currentProduct.productId),
          "is_separate",
          1,
          currentProduct.idMove ?? 0);

      //marcamos el producto como split
      await db.productsEntradaBatchRepository.setFieldTableProductEntradaBatch(
          currentProduct.idRecepcion ?? 0,
          int.parse(currentProduct.productId),
          "is_product_split",
          1,
          currentProduct.idMove ?? 0);

      emit(FinalizarRecepcionProductoSplitSuccess());
    } catch (e, s) {
      print('Error al finalizar la recepcion del producto split: $e, $s');
    }
  }

  //*Metodo pra finalizar un producto de se recepcion
  void _onFinalizarRecepcionProducto(FinalizarRecepcionProducto event,
      Emitter<RecepcionBatchState> emit) async {
    try {
      emit(FinalizarRecepcionProductoLoading());
      dateFin = DateTime.now().toString();
      //marcamos el producto como terminado
      await db.productsEntradaBatchRepository.setFieldTableProductEntradaBatch(
          currentProduct.idRecepcion ?? 0,
          int.parse(currentProduct.productId),
          "is_separate",
          1,
          currentProduct.idMove ?? 0);

      //marcamos tiempo final de separacion
      await db.productsEntradaBatchRepository.setFieldTableProductEntradaBatch(
          currentProduct.idRecepcion ?? 0,
          int.parse(currentProduct.productId),
          "date_end",
          dateFin,
          currentProduct.idMove ?? 0);
    } catch (e, s) {
      emit(FinalizarRecepcionProductoFailure(
          'Error al finalizar la recepcion del producto'));
      print('Error en el _onFinalizarRecepcionProducto: $e, $s');
    }
  }

  //metodo para enviar el producto a wms
  void _onSendProductToOrder(
      SendProductToOrder event, Emitter<RecepcionBatchState> emit) async {
    try {
      emit(SendProductToOrderLoading());

      final userid = await PrefUtils.getUserId();

      print("loteeeeeee: ${lotesProductCurrent.toMap()}");

      //calculamos la fecha de transaccion
      DateTime fechaTransaccion = DateTime.now();
      String fechaFormateada = formatoFecha(fechaTransaccion);
      //agregamos la fecha de transaccion
      await db.productsEntradaBatchRepository.setFieldTableProductEntradaBatch(
        currentProduct.idRecepcion ?? 0,
        int.parse(currentProduct.productId),
        'date_transaction',
        fechaFormateada,
        currentProduct.idMove ?? 0,
      );

      final productBD = await db.productsEntradaBatchRepository.getProductById(
        int.parse(currentProduct.productId),
        currentProduct.idMove ?? 0,
        currentProduct.idRecepcion ?? 0,
      );

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

      //lo convertimos en entero
      //actualizamos el tiempo del producto
      await db.productsEntradaBatchRepository.setFieldTableProductEntradaBatch(
        currentProduct.idRecepcion ?? 0,
        int.parse(currentProduct.productId),
        'time',
        time,
        currentProduct.idMove ?? 0,
      );

      final responseSend = await _recepcionRepository.sendProductRecepcionBatch(
        RecepcionRequest(
          idRecepcion: productBD?.idRecepcion ?? 0,
          listItems: [
            ListItem(
              idProducto: int.parse(productBD?.productId),
              idMove: productBD?.idMove ?? 0,
              loteProducto: lotesProductCurrent.id ?? 0,
              //validamos permiso
              ubicacionDestino: configurations
                          .result?.result?.scanDestinationLocationReception ==
                      true
                  ? currentUbicationDest?.id ?? 0
                  : productBD?.locationDestId ?? 0,
              cantidadSeparada: event.quantity,
              observacion: event.isSplit
                  ? 'Cantidad dividida'
                  : productBD?.observation == ""
                      ? "Sin novedad"
                      : productBD?.observation ?? "Sin novedad",
              idOperario: userid,
              timeLine: time,
              fechaTransaccion: fechaFormateada, // Formato de la fecha
            )
          ],
        ),
        false,
      );

      print("loteeeeeee: ${lotesProductCurrent.toMap()}");

      if (responseSend.result?.code == 200) {
        // marcamos tiempo final de sepfaracion
        await db.productsEntradaBatchRepository
            .setFieldTableProductEntradaBatch(
                currentProduct.idRecepcion ?? 0,
                int.parse(currentProduct.productId),
                "is_done_item",
                1,
                currentProduct.idMove ?? 0);
        if (event.isSplit) {
          //calculamos la cantidad pendiente del producto
          var pendingQuantity =
              (currentProduct.cantidadFaltante - event.quantity);
          //creamos un nuevo producto (duplicado) con la cantidad separada
          await db.productsEntradaBatchRepository
              .insertDuplicateProducto(currentProduct, pendingQuantity);
        }
        add(GetPorductsToEntradaBatch(currentProduct.idRecepcion ?? 0));
        lotesProductCurrent = LotesProduct();
        dateInicio = '';
        dateFin = '';
        emit(SendProductToOrderSuccess());
      } else {
        // marcamos tiempo final de sepfaracion

        await db.productsEntradaBatchRepository
            .setFieldTableProductEntradaBatch(
          currentProduct.idRecepcion ?? 0,
          int.parse(currentProduct.productId),
          "is_separate",
          0,
          currentProduct.idMove ?? 0,
        );

        add(GetPorductsToEntradaBatch(currentProduct.idRecepcion ?? 0));
        emit(SendProductToOrderFailure(responseSend.result?.msg ?? ""));
      }
    } catch (e, s) {
      emit(SendProductToOrderFailure('Error al enviar el producto'));
      print('Error en el _onSendProductToOrder: $e, $s');
    }
  }

  void _onCleanFieldsEvent(
      CleanFieldsEvent event, Emitter<RecepcionBatchState> emit) {
    scannedValue2 = '';
    scannedValue3 = '';
    scannedValue4 = '';
    scannedValue5 = '';
    scannedValue6 = '';
    selectLote = '';
    // currentUbicationDest = null;
    listLotesProduct.clear();
    productIsOk = false;
    loteIsOk = false;
    quantityIsOk = false;
    locationsDestIsok = false;
    isKeyboardVisible = false;
    viewQuantity = false;
    isProductOk = true;
    isQuantityOk = true;
    isLoteOk = true;
    isLocationDestOk = true;
  }

  //*metodo para cargar la configuracion del usuario
  void _onLoadConfigurationsUserEvent(LoadConfigurationsUserReception event,
      Emitter<RecepcionBatchState> emit) async {
    try {
      int userId = await PrefUtils.getUserId();
      final response =
          await db.configurationsRepository.getConfiguration(userId);

      if (response != null) {
        configurations = response;
        emit(ConfigurationLoadedOrder(response));
      } else {
        emit(ConfigurationErrorOrder('Error al cargar configuraciones'));
      }
    } catch (e, s) {
      emit(ConfigurationErrorOrder(e.toString()));
      print('Error en LoadConfigurationsUserPack.dart: $e =>$s');
    }
  }

  void _onLoadLocations(GetLocationsDestReceptionBatchEvent event,
      Emitter<RecepcionBatchState> emit) async {
    try {
      emit(LoadLocationsLoading());
      final response = await db.ubicacionesRepository.getAllUbicaciones();
      ubicaciones.clear();
      ubicacionesFilters.clear();
      if (response.isNotEmpty) {
        ubicaciones = response;
        ubicacionesFilters = ubicaciones;
        print('ubicaciones length: ${ubicaciones.length}');
        emit(LoadLocationsSuccess(ubicaciones));
      } else {
        print('No se encontraron ubicaciones');
        emit(LoadLocationsFailure('No se encontraron ubicaciones'));
      }
    } catch (e, s) {
      emit(LoadLocationsFailure('Error al cargar las ubicaciones'));
      print('Error en el fetch de ubicaciones: $e=>$s');
    }
  }

  void _onSearchLocationEvent(
      SearchLocationEvent event, Emitter<RecepcionBatchState> emit) async {
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

  void _onFilterUbicacionesEvent(
      FilterUbicacionesAlmacenEvent event, Emitter<RecepcionBatchState> emit) {
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

  //*metodo para obtener todos los lotes de un producto
  void _onGetLotesProduct(
      GetLotesProduct event, Emitter<RecepcionBatchState> emit) async {
    try {
      emit(GetLotesProductLoading());
      final response = await _recepcionRepository.fetchAllLotesProduct(
          false, int.parse(currentProduct.productId));

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

  //*metodo para cargar la informacion del producto actual
  void _onFetchPorductOrder(
      FetchPorductOrder event, Emitter<RecepcionBatchState> emit) async {
    try {
      isProductOk = true;
      isQuantityOk = true;
      isLocationDestOk = true;
      isLoteOk = true;
      viewQuantity = false;

      emit(FetchPorductOrderLoading());

      // traemos toda la lista de barcodes
      listOfBarcodes.clear();
      currentProduct = event.product;
      listOfBarcodes = await db.barcodesPackagesRepository.getBarcodesProduct(
          currentProduct.idRecepcion ?? 0,
          int.parse(currentProduct.productId),
          currentProduct.idMove ?? 0,
          'reception-batch');

      //validamos si el prodcuto tiene lote, si es asi llamamos los lotes de ese producto
      if (currentProduct.productTracking == 'lot') {
        add(GetLotesProduct());
      }

      //cargamos la informacion de las variables de validacion
      // productIsOk = currentProduct.productIsOk == 1 ? true : false;
      if (configurations.result?.result?.scanDestinationLocationReception ==
          true) {
        quantityIsOk = false;
      }
      // else {
      //   quantityIsOk = productIsOk ;
      // }

      quantitySelected = 0;
      currentUbicationDest = ResultUbicaciones();
      // locationsDestIsok = false;
      lotesProductCurrent = LotesProduct();
      //llamamos los productos de esa entrada
      products();
      //cargamos la configuracion del usuario
      if (currentProduct.dateStart != "") {
        dateInicio = currentProduct.dateStart ?? '';
      }

      if (currentProduct.dateEnd != "") {
        dateFin = currentProduct.dateEnd ?? '';
      }

      emit(FetchPorductOrderSuccess(currentProduct));
    } catch (e, s) {
      emit(FetchPorductOrderFailure('Error al obtener el producto'));
      print('Error en el _onFetchPorductOrder: $e, $s');
    }
  }

  //*meotod para cargar todas las novedades
  void _onLoadAllNovedadesEvent(LoadAllNovedadesReceptionEvent event,
      Emitter<RecepcionBatchState> emit) async {
    try {
      emit(NovedadesOrderLoadingState());
      final response = await db.novedadesRepository.getAllNovedades();
      if (response != null) {
        novedades.clear();
        novedades = response;
        print("novedades: ${novedades.length}");
        emit(NovedadesOrderLoadedState(listOfNovedades: novedades));
      }
    } catch (e, s) {
      print("Error en __onLoadAllNovedadesEvent: $e, $s");
      emit(NovedadesOrderErrorState(e.toString()));
    }
  }

  //*evento para ver la cantidad
  void _onShowQuantityEvent(
      ShowQuantityOrderEvent event, Emitter<RecepcionBatchState> emit) {
    try {
      viewQuantity = !viewQuantity;
      emit(ShowQuantityOrderState(viewQuantity));
    } catch (e, s) {
      print("❌ Error en _onShowQuantityEvent: $e, $s");
    }
  }

  //*metodo para validar la ubicacion
  void _onChangeLocationIsOkEvent(ChangeLocationDestIsOkEvent event,
      Emitter<RecepcionBatchState> emit) async {
    try {
      if (isLocationDestOk) {
        await db.productsEntradaBatchRepository
            .setFieldTableProductEntradaBatch(event.idEntrada, event.productId,
                "locationdest_is_ok", 1, event.idMove);

        currentUbicationDest = event.locationSelect;
        locationsDestIsok = true;

        emit(ChangeLocationDestIsOkState(
          locationsDestIsok,
        ));
      }
    } catch (e, s) {
      print("❌ Error en el ChangeLocationIsOkEvent $e ->$s");
    }
  }

  void _onChangeQuantityIsOkEvent(
      ChangeIsOkQuantity event, Emitter<RecepcionBatchState> emit) async {
    if (event.isOk) {
      await db.productsEntradaBatchRepository.setFieldTableProductEntradaBatch(
          event.idEntrada,
          event.productId,
          "is_quantity_is_ok",
          1,
          event.idMove);
    }
    quantityIsOk = event.isOk;
    emit(ChangeIsOkState(
      event.isOk,
    ));
  }

  void _onChangeProductIsOkEvent(
      ChangeProductIsOkEvent event, Emitter<RecepcionBatchState> emit) async {
    if (event.productIsOk) {
      dateInicio = DateTime.now().toString();
      //actualizmso valor de fecha inicio
      await db.productsEntradaBatchRepository.setFieldTableProductEntradaBatch(
        event.idEntrada,
        event.productId,
        'date_start',
        dateInicio,
        event.idMove,
      );
      //actualizamos la entrada a true
      await db.entradaBatchRepository.setFieldTableEntradaBatch(
        event.idEntrada,
        "is_selected",
        1,
      );
      await db.productsEntradaBatchRepository.setFieldTableProductEntradaBatch(
          event.idEntrada,
          event.productId,
          "is_selected",
          1,
          currentProduct.idMove ?? 0);

      //actualizamos el producto a true
      await db.productsEntradaBatchRepository.setFieldTableProductEntradaBatch(
        event.idEntrada,
        event.productId,
        "product_is_ok",
        1,
        event.idMove,
      );
      //actualizamos la cantidad separada
      await db.productsEntradaBatchRepository.setFieldTableProductEntradaBatch(
        event.idEntrada,
        event.productId,
        "quantity_done",
        event.quantity,
        event.idMove,
      );
      //validamos si el producto tiene lote
      if (currentProduct.productTracking != "lot") {
        if (configurations.result?.result?.scanDestinationLocationReception ==
            false) {
          add(ChangeIsOkQuantity(
            currentProduct.idRecepcion ?? 0,
            true,
            int.parse(currentProduct.productId),
            currentProduct.idMove ?? 0,
          ));
        }
      }
    }

    productIsOk = event.productIsOk;
    emit(ChangeProductOrderIsOkState(
      productIsOk,
    ));
  }

  //*evento para aumentar la cantidad
  void _onAddQuantitySeparateEvent(
      AddQuantitySeparate event, Emitter<RecepcionBatchState> emit) async {
    try {
      if (quantitySelected > (currentProduct.cantidadFaltante ?? 0)) {
        return;
      } else {
        quantitySelected = quantitySelected + event.quantity;
        await db.productsEntradaBatchRepository
            .incremenQtytProductSeparatePacking(event.idRecepcion,
                event.productId, event.idMove, event.quantity);
        emit(ChangeQuantitySeparateState(quantitySelected));
      }
    } catch (e, s) {
      emit(ChangeQuantitySeparateErrorOrder('Error al aumentar cantidad'));
      print("❌ Error en el AddQuantitySeparate $e ->$s");
    }
  }

  void _onChangeQuantitySelectedEvent(
      ChangeQuantitySeparate event, Emitter<RecepcionBatchState> emit) async {
    try {
      if (event.quantity > 0.0) {
        quantitySelected = event.quantity;
        await db.productsEntradaBatchRepository
            .setFieldTableProductEntradaBatch(event.idRecepcion,
                event.productId, "quantity_done", event.quantity, event.idMove);
      }
      emit(ChangeQuantitySeparateState(quantitySelected));
    } catch (e, s) {
      print('Error en _onChangeQuantitySelectedEvent: $e, $s');
    }
  }

  //*metodo para validar los campos de la vista
  void _onValidateFieldsOrder(
      ValidateFieldsOrderEvent event, Emitter<RecepcionBatchState> emit) {
    switch (event.field) {
      case 'product':
        isProductOk = event.isOk;
        break;
      case 'lote':
        isLoteOk = event.isOk;
        break;
      case 'quantity':
        isQuantityOk = event.isOk;
        break;

      case 'locationDest':
        isLocationDestOk = event.isOk;
        break;
    }
    print(' Product: $isProductOk, lote: $isLoteOk, Quantity: $isQuantityOk');
    emit(ValidateFieldsOrderState(isOk: event.isOk));
  }

  void _onCurrentOrdenesCompra(CurrentOrdenesCompraBatch event,
      Emitter<RecepcionBatchState> emit) async {
    try {
      resultEntrada = ReceptionBatch();
      //traemos la orden de compra de la bd
      final respnonseEntradaDb = await db.entradaBatchRepository
          .getEntradaById(event.resultEntrada.id ?? 0);
      resultEntrada = respnonseEntradaDb ?? ReceptionBatch();

      emit(CurrentOrdenesCompraState(resultEntrada));
    } catch (e, s) {
      print('Error en _onCurrentOrdenesCompra: $e, $s');
    }
  }

  //*metodo para obtener los productos de una entrada por id
  void _onGetProductsToEntrada(GetPorductsToEntradaBatch event,
      Emitter<RecepcionBatchState> emit) async {
    try {
      emit(GetProductsToEntradaLoading());
      final response = await db.productsEntradaBatchRepository
          .getProductsByRecepcionBatchId(event.idEntrada);

      final response2 =
          await db.productsEntradaBatchRepository.getAllProductsEntradaBatch();
      print('response2: ${response2.length}');

      if (response != null && response is List) {
        listProductsEntrada = [];
        listProductsEntrada = response;
        //despues de obtener los productos, obtenemos todos los barcodes de esta entrada
        listAllOfBarcodes.clear();
        final responseBarcodes = await db.barcodesPackagesRepository
            .getBarcodesByBatchIdAndType(event.idEntrada, 'reception-batch');

        if (responseBarcodes != null && responseBarcodes is List) {
          listAllOfBarcodes = responseBarcodes;
        }

        print("List all barcodes: ${listAllOfBarcodes.length}");

        emit(GetProductsToEntradaSuccess(response));
      } else {
        emit(GetProductsToEntradaFailure(
            'Error al obtener los productos de la entrada'));
      }
    } catch (e, s) {
      emit(GetProductsToEntradaFailure(
          'Error al obtener los productos de la entrada'));
      print('Error en el _onGetProductsToEntrada: $e, $s');
    }
  }

  ///*metodo para asignar tiempo de inicio o fin
  ///
  void _onStartOrStopTimeOrder(
      StartOrStopTimeOrder event, Emitter<RecepcionBatchState> emit) async {
    try {
      final time = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      if (event.value == "start_time_reception") {
        await db.entradaBatchRepository.setFieldTableEntradaBatch(
          event.idRecepcion,
          "start_time_reception",
          time,
        );
      } else if (event.value == "end_time_reception") {
        await db.entradaBatchRepository.setFieldTableEntradaBatch(
          event.idRecepcion,
          "end_time_reception",
          time,
        );
      }
      await db.entradaBatchRepository.setFieldTableEntradaBatch(
        event.idRecepcion,
        "is_selected",
        1,
      );
      await db.entradaBatchRepository.setFieldTableEntradaBatch(
        event.idRecepcion,
        "is_started",
        1,
      );

      //hacemos la peticion de mandar el tiempo
      final response = await _recepcionRepository.sendTime(
        event.idRecepcion,
        event.value,
        time,
        false,
      );

      if (response) {
        emit(StartOrStopTimeOrderSuccess(event.value));
      } else {
        emit(StartOrStopTimeOrderFailure('Error al enviar el tiempo'));
      }
    } catch (e, s) {
      print('Error en el _onStartOrStopTimeOrder: $e, $s');
    }
  }

  //*metodo para asignar un usuario a una orden de compra
  void _onAssignUserToOrder(
      AssignUserToReception event, Emitter<RecepcionBatchState> emit) async {
    try {
      int userId = await PrefUtils.getUserId();
      String nameUser = await PrefUtils.getUserName();
      emit(AssignUserToOrderLoading());
      final response = await _recepcionRepository.assignUserToReceptionBatch(
        true,
        userId,
        event.order.id ?? 0,
      );

      if (response) {
        //actualizamos la tabla entrada:
        await db.entradaBatchRepository.setFieldTableEntradaBatch(
          event.order.id ?? 0,
          "responsable_id",
          userId,
        );

        await db.entradaBatchRepository.setFieldTableEntradaBatch(
          event.order.id ?? 0,
          "responsable",
          nameUser,
        );
        await db.entradaBatchRepository.setFieldTableEntradaBatch(
          event.order.id ?? 0,
          "is_selected",
          1,
        );

        // add(StartOrStopTimeOrder(
        //   event.order.id ?? 0,
        //   "start_time_reception",
        // ));

        emit(AssignUserToOrderSuccess(event.order));
      } else {
        emit(AssignUserToOrderFailure(
            "La recepción ya tiene un responsable asignado"));
      }
    } catch (e, s) {
      emit(AssignUserToOrderFailure('Error al asignar el usuario'));
      print('Error en el _onAssignUserToOrder: $e, $s');
    }
  }

  //*metodo para buscar una entrada

  void _onSearchOrderEvent(
      SearchReceptionEvent event, Emitter<RecepcionBatchState> emit) async {
    try {
      listReceptionBatchFilter = [];
      listReceptionBatchFilter = listReceptionBatch;
      final query = event.query.toLowerCase();
      if (query.isEmpty) {
        listReceptionBatchFilter = listReceptionBatch;
      } else {
        listReceptionBatchFilter = listReceptionBatchFilter.where((element) {
          // Filtrar por nombre o proveedor (si el proveedor no es nulo o vacío)
          return element.name!.toLowerCase().contains(query) ||
              (element.proveedor != null &&
                  element.proveedor!.toLowerCase().contains(query)) ||
              (element.purchaseOrderName != null &&
                  element.purchaseOrderName!.toLowerCase().contains(query));
        }).toList();
      }

      emit(SearchOrdenCompraSuccess(listReceptionBatchFilter));
    } catch (e, s) {
      emit(SearchOrdenCompraFailure('Error al buscar la orden de compra'));
      print('Error en el _onSearchPedidoEvent: $e, $s');
    }
  }

  //*metodo para obtener todas las recepciones por batch
  void _onFetchRecepcionBatchEvent(
      FetchRecepcionBatchEvent event, Emitter<RecepcionBatchState> emit) async {
    emit(FetchRecepcionBatchLoading());

    try {
      //limpiamos la tabla de recepcion por batch
      await db.deleReceptionBatch();
      listReceptionBatch.clear();

      final response = await _recepcionRepository
          .fetchAllBatchReceptions(event.isLoadinDialog);

      if (response.result?.code == 200) {
        if ((response.result?.updateVersion ?? false) == true) {
          emit(NeedUpdateVersionState());
        }

        if (response.result?.result?.isNotEmpty == true) {
          final listReceptionBatch = response.result?.result;
          print('cantidad de recepciones: ${listReceptionBatch?.length}');
          //insertamos en la base de datos

          await db.deleRecepcion('reception-batch');

          await db.entradaBatchRepository.insertEntradaBatch(
            listReceptionBatch!,
          );

          //obtenemos los productos de todas las recepciones para guardarlos en la bd:
          final productsToInsert =
              _getAllProducts(listReceptionBatch).toList(growable: false);

          final productsSedToInsert =
              _getAllSentProducts(listReceptionBatch).toList(growable: false);
          final allBarcodes =
              _getAllBarcodes(listReceptionBatch).toList(growable: false);

          await db.productsEntradaBatchRepository.insertarProductoEntrada(
            productsToInsert,
          );

          await db.productsEntradaBatchRepository.insertarProductoEntrada(
            productsSedToInsert,
          );

          await db.barcodesPackagesRepository
              .insertOrUpdateBarcodes(allBarcodes, 'reception-batch');

          print(
              'cantidad de productos: ${productsToInsert.length} y ${productsSedToInsert.length}');
          print('cantidad de codigos de barras: ${allBarcodes.length}');

          add(FetchRecepcionBatchEventFromBD());
          emit(FetchRecepcionBatchSuccess(
              listReceptionBatch: listReceptionBatch));
        } else {
          emit(FetchRecepcionBatchSuccessFromBD(listReceptionBatch: []));
        }
      } else {
        if (response.result?.code == 403) {
          emit(DeviceNotAuthorized());
          return;
        }

        emit(FetchRecepcionBatchFailure(response.result?.msg ?? ""));
      }
    } catch (e) {
      emit(FetchRecepcionBatchFailure(e.toString()));
    }
  }

  Iterable<LineasRecepcionBatch> _getAllProducts(
      List<ReceptionBatch> batches) sync* {
    for (final batch in batches) {
      if (batch.lineasRecepcion != null) yield* batch.lineasRecepcion!;
    }
  }

  Iterable<LineasRecepcionBatch> _getAllSentProducts(
      List<ReceptionBatch> batches) sync* {
    for (final batch in batches) {
      if (batch.lineasRecepcionEnviadas != null) {
        yield* batch.lineasRecepcionEnviadas!;
      }
    }
  }
// Generador para todos los códigos de barras

  Iterable<Barcodes> _getAllBarcodes(List<ReceptionBatch> batches) sync* {
    for (final batch in batches) {
      if (batch.lineasRecepcion != null) {
        for (final product in batch.lineasRecepcion!) {
          if (product.otherBarcodes != null) yield* product.otherBarcodes!;
          if (product.productPacking != null) yield* product.productPacking!;
        }
      }
    }
  }

//*metodo para cargar todas las recepciones por batch desde la bd
  void _onFetchRecepcionBatchEventFromBD(FetchRecepcionBatchEventFromBD event,
      Emitter<RecepcionBatchState> emit) async {
    emit(FetchRecepcionBatchLoadingFromBD());
    try {
      listReceptionBatch.clear();
      listReceptionBatchFilter.clear();
      print('listReceptionBatch: ${listReceptionBatch.length}');

      final response = await db.entradaBatchRepository.getAllEntradaBatch();

      print('response: ${response.length}');
      if (response.isNotEmpty) {
        listReceptionBatch = response;
        listReceptionBatchFilter = response;
        emit(FetchRecepcionBatchSuccessFromBD(listReceptionBatch: response));
      } else {
        emit(FetchRecepcionBatchFailureFromBD("No hay recepciones por batch"));
      }
    } catch (e, s) {
      emit(FetchRecepcionBatchFailureFromBD(e.toString()));
    }
  }

  void products() {
    listOfProductsName.clear();

    // filtramos la lista a productos que no esten separados
    listProductsEntrada = listProductsEntrada
        .where((element) => element.isDoneItem == 0)
        .toList();

    // Recorremos los productos del batch
    for (var i = 0; i < listProductsEntrada.length; i++) {
      var product = listProductsEntrada[i];

      // Aseguramos que productId no sea nulo antes de intentar agregarlo
      if (product != null && product != null) {
        // Validamos si el productId ya existe en la lista 'positions'
        if (!listOfProductsName.contains(product.idMove)) {
          listOfProductsName.add(
              product); // Agregamos el productId a la lista 'listOfProductsName'
        }
      }
    }
  }
}
