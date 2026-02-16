// ignore_for_file: unused_field, unnecessary_null_comparison, unnecessary_type_check, use_build_context_synchronously

import 'dart:io';

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
import 'package:wms_app/src/presentation/views/recepcion/models/recepcion_response_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/repcion_requets_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_image_send_novedad_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_lotes_product_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_temp_ia_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';

part 'recepcion_event.dart';
part 'recepcion_state.dart';

class RecepcionBloc extends Bloc<RecepcionEvent, RecepcionState> {
  //*listado de entradas
  List<ResultEntrada> listOrdenesCompra = [];
  List<ResultEntrada> listFiltersOrdenesCompra = [];

  //*listado de devoluciones
  List<ResultEntrada> listDevolutions = [];
  List<ResultEntrada> listFiltersDevolutions = [];

  //*listado de productos de una entrada
  List<LineasTransferencia> listProductsEntrada = [];

  //*lista de productos de un una entrada
  List<LineasTransferencia> listOfProductsName = [];

  //*lista de barcodes
  List<Barcodes> listOfBarcodes = [];
  List<Barcodes> listAllOfBarcodes = [];

  //*lista de novedades
  List<Novedad> novedades = [];

  //*producto acutal

  LineasTransferencia currentProduct = LineasTransferencia();

//*orden actual
  ResultEntrada resultEntrada = ResultEntrada();

  List<String> tiposRecepcion = [];

  //lista de lotes de un producto
  List<LotesProduct> listLotesProduct = [];
  List<LotesProduct> listLotesProductFilters = [];

  //*valores de scanvalue

  String scannedValue2 = ''; //producto
  String scannedValue3 = ''; //cantidad
  String scannedValue4 = ''; //lote
  String scannedValue5 = ''; //all product
  String scannedValue6 = ''; //ubicacion destino

  String selectLote = '';

  LotesProduct lotesProductCurrent = LotesProduct();

  TemperatureIa resultTemperature = TemperatureIa();

  //*repositorio
  final RecepcionRepository _recepcionRepository = RecepcionRepository();
  //*controller de busqueda
  TextEditingController searchControllerDev = TextEditingController();
  TextEditingController searchControllerOrderC = TextEditingController();
  TextEditingController newLoteController = TextEditingController();
  TextEditingController dateLoteController = TextEditingController();
  TextEditingController searchControllerLote = TextEditingController();
  TextEditingController locationDestController = TextEditingController();
  TextEditingController loteController = TextEditingController();
  TextEditingController controllerTemperature = TextEditingController();
  TextEditingController searchControllerLocationDest = TextEditingController();
  TextEditingController temperatureController = TextEditingController();

  //*variables para validar
  bool productIsOk = false;
  bool loteIsOk = false;
  bool quantityIsOk = false;
  bool locationsDestIsok = false;
  bool isKeyboardVisible = false;
  bool viewQuantity = false;

  String dateInicio = '';
  String dateFin = "";

  // //*validaciones de campos del estado de la vista
  bool isProductOk = true;
  bool isQuantityOk = true;
  bool isLoteOk = true;
  bool isLocationDestOk = true;
  dynamic quantitySelected = 0;
  bool isExpanded = false;

  String selectedAlmacen = '';
  //*lista de ubicaciones
  List<ResultUbicaciones> ubicaciones = [];
  List<ResultUbicaciones> ubicacionesFilters = [];

  ResultUbicaciones? currentUbicationDest;

//*base de datos
  DataBaseSqlite db = DataBaseSqlite();

  //*configuracion del usuario //permisos
  UserConfigurationModel configurations = UserConfigurationModel();

  //repositorio de inventario
  InventarioRepository inventarioRepository = InventarioRepository();

  RecepcionBloc() : super(RecepcionInitial()) {
    on<RecepcionEvent>((event, emit) {});
    //*obtener todas las ordenes de compra
    on<FetchOrdenesCompra>(_onFetchOrdenesCompra);
    //*activar el teclado
    on<ShowKeyboardEvent>(_onShowKeyboardEvent);
    //* buscar una orden de compra
    on<SearchOrdenCompraEvent>(_onSearchOrderEvent);
    //*obtener las ordenes de compra de la bd
    on<FetchOrdenesCompraOfBd>(_onFetchOrdenesCompraOfBd);

    on<CurrentOrdenesCompra>(_onCurrentOrdenesCompra);

    //*asignar un usuario a una orden de compra
    on<AssignUserToOrder>(_onAssignUserToOrder);
    //*obtener las configuraciones y permisos del usuario desde la bd
    on<LoadConfigurationsUserOrder>(_onLoadConfigurationsUserEvent);
    //*obtener todos los productos de una entrada
    on<GetPorductsToEntrada>(_onGetProductsToEntrada);

    //*evento para cargar la info del producto
    on<FetchPorductOrder>(_onFetchPorductOrder);

    //*evento para validar los campos de la vista
    on<ValidateFieldsOrderEvent>(_onValidateFieldsOrder);
    //*evento para limpiar el valor escaneado
    on<ClearScannedValueOrderEvent>(_onClearScannedValueEvent);

    //*evento para actualizar el valor del scan
    on<UpdateScannedValueOrderEvent>(_onUpdateScannedValueEvent);

    //*cambiar el estado de las variables
    on<ChangeProductIsOkEvent>(_onChangeProductIsOkEvent);
    on<SelectecLoteEvent>(_onChangeLoteIsOkEvent);

    //*cantidad
    on<ChangeIsOkQuantity>(_onChangeQuantityIsOkEvent);

    //*evento para cambiar la cantidad seleccionada
    on<ChangeQuantitySeparate>(_onChangeQuantitySelectedEvent);
    on<AddQuantitySeparate>(_onAddQuantitySeparateEvent);

    //*evento para ver la cantidad
    on<ShowQuantityOrderEvent>(_onShowQuantityEvent);

    //*cambiar el estado de las variables
    on<ChangeLocationDestIsOkEvent>(_onChangeLocationIsOkEvent);

    //*evento para obtener las novedades
    on<LoadAllNovedadesOrderEvent>(_onLoadAllNovedadesEvent);
    add(LoadAllNovedadesOrderEvent());

    //*finalizarRececpcionProducto
    on<FinalizarRecepcionProducto>(_onFinalizarRecepcionProducto);

    //*finalizarRececpcionProductoSplit
    on<FinalizarRecepcionProductoSplit>(_onFinalizarRecepcionProductoSplit);

    //*metodo para obtener todos los lotes de un producto
    on<GetLotesProduct>(_onGetLotesProduct);

    //*metodo para enviar el producto a wms
    on<SendProductToOrder>(_onSendProductToOrder);

    //*metodo para crear un lote a un producto
    on<CreateLoteProduct>(_onCreateLoteProduct);

    //*metodo para empezar o terminar timepo
    on<StartOrStopTimeOrder>(_onStartOrStopTimeOrder);

    //*metodo para crear barckorder o no
    on<CreateBackOrderOrNot>(_onCreateBackOrder);

    //metodo para buscar un lote
    on<SearchLotevent>(_onSearchLoteEvent);

    //*metodo para cargar las ubicaciones
    on<GetLocationsDestEvent>(_onLoadLocations);

    //metodo para buscar una ubicacion
    on<SearchLocationEvent>(_onSearchLocationEvent);

    ///filtrar transferenica por el type
    on<FilterReceptionByTypeEvent>(_onFilterTransferByTypeEvent);

    on<CleanFieldsEvent>(_onCleanFieldsEvent);

    on<FilterUbicacionesAlmacenEvent>(_onFilterUbicacionesEvent);

    //enviar temperatura
    on<SendTemperatureEvent>(_onSendTemperatureEvent);
    on<SendTemperatureManualEvent>(_onSendTemperatureManualEvent);
    on<GetTemperatureEvent>(_onGetTemperatureEvent);

    //evento para eliminar un producto ya enviado
    on<DelectedProductWmsEvent>(_onDelectedProductWmsEvent);

    on<SendImageNovedad>(_onSendImageNovedad);

    // ToggleProductExpansionEvent
    on<ToggleProductExpansionEvent>(_onToggleProductExpansionEvent);

    on<ViewProductImageEvent>(_onViewProductImageEvent);

    //todo devoluciones
    on<FetchDevoluciones>(_onFetchDevoluciones);
    on<FetchDevolucionesOfDB>(_onFetchDevolucionesOfDB);
    on<SearchDevolucionEvent>(_onSearchDevolucionEvent);
  }

  void _onViewProductImageEvent(
      ViewProductImageEvent event, Emitter<RecepcionState> emit) async {
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

  void _onToggleProductExpansionEvent(
      ToggleProductExpansionEvent event, Emitter<RecepcionState> emit) {
    print('isExpanded: $isExpanded');
    isExpanded = event.isExpanded;
    emit(ProductExpansionToggled(isExpanded));
  }

//metodo para enviar una imagen de novedad
  void _onSendImageNovedad(
      SendImageNovedad event, Emitter<RecepcionState> emit) async {
    try {
      emit(SendImageNovedadLoading());

      final response = await _recepcionRepository.sendImageNoved(
        event.moveLineId,
        event.file,
        true,
      );

      if (response.code == 200) {
        //actualizamos la imagen de novedad en la bd
        await db.productEntradaRepository.setFieldTableProductEntradaImg(
          currentProduct.idRecepcion ?? 0,
          int.parse(currentProduct.productId),
          'image_novedad',
          response.imageUrl ?? "",
          response.stockMoveLineId ?? 0,
        );
        emit(SendImageNovedadSuccess(response));
        add(GetPorductsToEntrada(event.idRecepcion,
            resultEntrada.type == 'dev' ? 'dev' : 'reception'));
      } else {
        emit(SendImageNovedadFailure(
            response.msg ?? 'Error al enviar la imagen'));
      }
    } catch (e, s) {
      print('Error en el _onSendImageNovedad: $e, $s');
      emit(SendImageNovedadFailure('Ocurrió un error al enviar la imagen'));
    }
  }

  //*metodo para eliminar un producto ya enviado
  void _onDelectedProductWmsEvent(
      DelectedProductWmsEvent event, Emitter<RecepcionState> emit) async {
    try {
      emit(DelectedProductWmsLoading());

      final response = await _recepcionRepository.deleteProductInWms(
          event.idRecepcion, event.listIdMove, false);

      if (response.result?.code == 200) {
        // Antes de eliminar, actualizamos la cantidad faltante
        await db.productEntradaRepository
            .updateCantidadAndDeleteProductsEntrada(
          idRecepcion: event.idRecepcion,
          products: response.result?.result ?? [],
        );

        ///pedimos nuevamente los productos de la entrada
        add(GetPorductsToEntrada(event.idRecepcion,
            resultEntrada.type == 'dev' ? 'dev' : 'reception'));

        emit(DelectedProductWmsSuccess('Línea eliminada correctamente'));
      } else {
        emit(DelectedProductWmsFailure(response.result?.mensaje ?? ""));
      }
    } catch (e, s) {
      emit(DelectedProductWmsFailure('Error al eliminar el producto'));
      print('Error en _onDelectedProductWmsEvent: $e, $s');
    }
  }

  //*metodo para buscar una devolucion

  void _onSearchDevolucionEvent(
      SearchDevolucionEvent event, Emitter<RecepcionState> emit) async {
    try {
      listFiltersDevolutions = [];
      listFiltersDevolutions = listDevolutions;
      final query = event.query.toLowerCase();
      if (query.isEmpty) {
        listFiltersDevolutions = listDevolutions;
      } else {
        listFiltersDevolutions = listFiltersDevolutions.where((element) {
          // Filtrar por nombre o proveedor (si el proveedor no es nulo o vacío)
          return element.name!.toLowerCase().contains(query) ||
              (element.proveedor != null &&
                  element.proveedor!.toLowerCase().contains(query)) ||
              (element.purchaseOrderName != null &&
                  element.purchaseOrderName!.toLowerCase().contains(query)) ||
              (element.backorderName != null &&
                  element.backorderName!.toLowerCase().contains(query));
        }).toList();
      }

      emit(SearchDevolucionSuccess(listFiltersDevolutions));
    } catch (e, s) {
      emit(SearchDevolucionFailure('Error al buscar la orden de compra'));
      print('Error en el _onSearchPedidoEvent: $e, $s');
    }
  }

  //*metodo para obtener las entradas desde la bd
  void _onFetchDevolucionesOfDB(
      FetchDevolucionesOfDB event, Emitter<RecepcionState> emit) async {
    try {
      emit(FetchDevolucionesLoadingDB());
      final listbd = await db.entradasRepository.getAllEntradas('dev');
      listDevolutions.clear();
      listFiltersDevolutions.clear();
      if (listbd != null && listbd.isNotEmpty) {
        listDevolutions = listbd;
        listFiltersDevolutions = listbd;
      } else {
        emit(FetchDevolucionesFailureDB(
            'No hay ordenes de compra en la base de datos'));
      }
      emit(FetchDevolucionesSuccessDB(listFiltersDevolutions));
    } catch (e, s) {
      emit(
          FetchDevolucionesFailureDB('Error al obtener las ordenes de compra'));
      print('Error en el _onFetchOrdenesCompraOfBd: $e, $s');
    }
  }

  void _onFetchDevoluciones(
      FetchDevoluciones event, Emitter<RecepcionState> emit) async {
    try {
      emit(FetchDevolucionesLoading());

      listFiltersDevolutions.clear();

      await db.deleRecepcion('dev');

      final response =
          await _recepcionRepository.fetchAllDevolutions(event.isLoadinDialog);

      if ((response.result?.updateVersion ?? false) == true) {
        emit(NeedUpdateVersionState());
      }

      if (response.result?.code == 200) {
        if (response.result?.result?.isNotEmpty == true) {
          final listRecepcion = response.result?.result;

          await db.entradasRepository
              .insertEntrada(response.result?.result ?? [], 'dev');

          final productsToInsert =
              _getAllProducts(listRecepcion!).toList(growable: false);
          final productsSedToInsert =
              _getAllSentProducts(listRecepcion).toList(growable: false);
          final allBarcodes =
              _getAllBarcodes(listRecepcion).toList(growable: false);

          // Enviar la lista agrupada a insertBatchProducts
          await db.productEntradaRepository
              .insertarProductoEntrada(productsToInsert, 'dev');

          await db.productEntradaRepository
              .insertarProductoEntrada(productsSedToInsert, 'dev');

          // Enviar la lista agrupada de barcodes de un producto para packing
          await db.barcodesPackagesRepository
              .insertOrUpdateBarcodes(allBarcodes, 'dev');

          print("listRecepcion: ${listRecepcion.length}");
          print("productsToInsert: ${productsToInsert.length}");
          print('productsSedToInsert : ${productsSedToInsert.length}');
          print("allBarcodes: ${allBarcodes.length}");

          add(FetchDevolucionesOfDB());
          emit(FetchDevolucionesSuccess(
            response.result?.result ?? [],
          ));
        } else {
          emit(FetchDevolucionesSuccess(
            response.result?.result ?? [],
          ));
        }
      } else {
        if (response.result?.code == 403) {
          emit(DeviceNotAuthorized());
          return;
        }

        emit(FetchDevolucionesFailure(response.result?.msg ?? ''));
      }
    } catch (e, s) {
      print('Error en RecepcionBloc: $e, $s');
    }
  }

  void _onGetTemperatureEvent(
    GetTemperatureEvent event,
    Emitter<RecepcionState> emit,
  ) async {
    try {
      emit(GetTemperatureLoading());
      // 1. Llamar al método que analiza la imagen y devuelve la temperatura
      final result =
          await _recepcionRepository.getTemperatureWithImage(event.file);

      resultTemperature = TemperatureIa();
      if (result.temperature != null) {
        resultTemperature = result;
        emit(GetTemperatureSuccess(resultTemperature));
      } else {
        emit(GetTemperatureFailure(
            result.detail ?? 'Error al obtener la temperatura'));
        return;
      }
    } catch (e, s) {
      print('Error en el _onSendTemperatureEvent: $e, $s');
      emit(GetTemperatureFailure(
          'Ocurrió un error al procesar la imagen y obtener la temperatura'));
    }
  }

  void _onSendTemperatureEvent(
    SendTemperatureEvent event,
    Emitter<RecepcionState> emit,
  ) async {
    try {
      emit(SendTemperatureLoading());

      //validamso que tengamos imagen y temperatura

      if (event.file.path == null || event.file.path.isEmpty) {
        emit(SendTemperatureFailure('No se ha seleccionado una imagen'));
        return;
      }

      print('currentProduct: ${currentProduct.toMap()}');

      //enviamos la temperatura con la imagen
      final response = await _recepcionRepository.sendTemperature(
        resultTemperature.temperature ?? 0.0,
        event.moveLineId,
        event.file,
        true,
      );

      //esperamos la repuesta y emitimos el estadp
      if (response.code == 200) {
        //actualizamos la temepratura por producto en la bd y la imagen
        await db.productEntradaRepository.setFieldTableProductEntradaImg(
          currentProduct.idRecepcion ?? 0,
          int.parse(currentProduct.productId),
          'temperatura',
          resultTemperature.temperature ?? 0.0,
          event.moveLineId,
        );
        //agregamos la imagen de temperatura del producto a la bd
        await db.productEntradaRepository.setFieldTableProductEntradaImg(
          currentProduct.idRecepcion ?? 0,
          int.parse(currentProduct.productId),
          'image',
          response.imageUrl ?? "",
          event.moveLineId,
        );

        //limpiamos el dato de temperatura
        resultTemperature = TemperatureIa();

        emit(SendTemperatureSuccess(
            response.result ?? 'Temperatura enviada correctamente'));
        add(GetPorductsToEntrada(currentProduct.idRecepcion ?? 0,
            resultEntrada.type == 'dev' ? 'dev' : 'reception'));
      } else {
        emit(SendTemperatureFailure(
            response.msg ?? 'Error al enviar la temperatura'));
        return;
      }
    } catch (e, s) {
      print('Error en el _onSendTemperatureEvent: $e, $s');
      emit(SendTemperatureFailure(
          'Ocurrió un error al procesar la imagen y obtener la temperatura'));
    }
  }

  void _onSendTemperatureManualEvent(
    SendTemperatureManualEvent event,
    Emitter<RecepcionState> emit,
  ) async {
    try {
      emit(SendTemperatureLoading());

      print('currentProduct: ${currentProduct.toMap()}');

      //enviamos la temperatura con la imagen
      final response = await _recepcionRepository.sendTemperatureManual(
        temperatureController.text.trim(),
        event.moveLineId,
        true,
      );

      //esperamos la repuesta y emitimos el estadp
      if (response.code == 200) {
        //actualizamos la temepratura por producto en la bd y la imagen
        await db.productEntradaRepository.setFieldTableProductEntradaImg(
          currentProduct.idRecepcion ?? 0,
          int.parse(currentProduct.productId),
          'temperatura',
          temperatureController.text.trim(),
          event.moveLineId,
        );
        //limpiamos el dato de temperatura
        temperatureController.clear();
        resultTemperature = TemperatureIa();

        emit(SendTemperatureSuccess(
            response.result ?? 'Temperatura enviada correctamente'));
        add(GetPorductsToEntrada(currentProduct.idRecepcion ?? 0,
            resultEntrada.type == 'dev' ? 'dev' : 'reception'));
      } else {
        emit(SendTemperatureFailure(
            response.msg ?? 'Error al enviar la temperatura'));
        return;
      }
    } catch (e, s) {
      print('Error en el _onSendTemperatureEvent: $e, $s');
      emit(SendTemperatureFailure(
          'Ocurrió un error al procesar la imagen y obtener la temperatura'));
    }
  }

  void _onFilterUbicacionesEvent(
      FilterUbicacionesAlmacenEvent event, Emitter<RecepcionState> emit) {
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

  void _onCleanFieldsEvent(
      CleanFieldsEvent event, Emitter<RecepcionState> emit) {
    scannedValue2 = '';
    scannedValue3 = '';
    scannedValue4 = '';
    scannedValue5 = '';
    scannedValue6 = '';
    selectLote = '';
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

  void _onFilterTransferByTypeEvent(
      FilterReceptionByTypeEvent event, Emitter<RecepcionState> emit) {
    try {
      emit(FilterReceptionByTypeLoading());

      if (event.type == 'todas') {
        listFiltersOrdenesCompra = listOrdenesCompra;
      } else {
        listFiltersOrdenesCompra = listOrdenesCompra.where((item) {
          final name = item.name;
          if (name != null) {
            final parts = name.split('/');
            return parts.length >= 2 && parts[1] == event.type;
          }
          return false;
        }).toList();
      }

      emit(FilterReceptionByTypeSuccess(listFiltersOrdenesCompra));
    } catch (e, s) {
      emit(FilterReceptionByTypeFailure('Error al filtrar las transferencias'));
      print('Error en el _onFilterTransferByTypeEvent: $e, $s');
    }
  }

  //*metodo para validar la ubicacion
  void _onChangeLocationIsOkEvent(
      ChangeLocationDestIsOkEvent event, Emitter<RecepcionState> emit) async {
    try {
      if (isLocationDestOk) {
        await db.productEntradaRepository.setFieldTableProductEntrada(
            event.idEntrada,
            event.productId,
            "locationdest_is_ok",
            1,
            event.idMove);

        currentUbicationDest = event.locationSelect;
        locationsDestIsok = true;

        add(ChangeIsOkQuantity(currentProduct.idRecepcion ?? 0, true,
            int.parse(currentProduct.productId), currentProduct.idMove ?? 0));

        emit(ChangeLocationDestIsOkState(
          locationsDestIsok,
        ));
      }
    } catch (e, s) {
      print("❌ Error en el ChangeLocationIsOkEvent $e ->$s");
    }
  }

  void _onSearchLocationEvent(
      SearchLocationEvent event, Emitter<RecepcionState> emit) async {
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
      GetLocationsDestEvent event, Emitter<RecepcionState> emit) async {
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

  void _onSearchLoteEvent(
      SearchLotevent event, Emitter<RecepcionState> emit) async {
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

  void _onCreateBackOrder(
      CreateBackOrderOrNot event, Emitter<RecepcionState> emit) async {
    try {
      emit(CreateBackOrderOrNotLoading());
      final response = await _recepcionRepository.validateRecepcion(
          event.idRecepcion, event.isBackOrder, false);

      if (response.result?.code == 200) {
        add(StartOrStopTimeOrder(
          event.idRecepcion,
          'end_time_reception',
        ));

        await db.entradasRepository.setFieldTableEntrada(
          event.idRecepcion,
          "is_finish",
          1,
        );
        emit(CreateBackOrderOrNotSuccess(
            event.isBackOrder, response.result?.msg ?? ""));

        if (event.type == 'dev') {
          add(FetchDevolucionesOfDB());
        } else {
          add(FetchOrdenesCompraOfBd());
        }
      } else {
        emit(CreateBackOrderOrNotFailure(response.result?.msg ?? ''));
      }
    } catch (e, s) {
      emit(CreateBackOrderOrNotFailure('Error al crear la backorder'));
      print('Error en el _onCreateBackOrder: $e, $s');
    }
  }

  void _onStartOrStopTimeOrder(
      StartOrStopTimeOrder event, Emitter<RecepcionState> emit) async {
    try {
      final time = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      print("time : $time");

      if (event.value == "start_time_reception") {
        await db.entradasRepository.setFieldTableEntrada(
          event.idRecepcion,
          "start_time_reception",
          time,
        );
      } else if (event.value == "end_time_reception") {
        await db.entradasRepository.setFieldTableEntrada(
          event.idRecepcion,
          "end_time_reception",
          time,
        );
      }

      await db.entradasRepository.setFieldTableEntrada(
        event.idRecepcion,
        "is_selected",
        1,
      );
      await db.entradasRepository.setFieldTableEntrada(
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

  void _onCurrentOrdenesCompra(
      CurrentOrdenesCompra event, Emitter<RecepcionState> emit) async {
    try {
      resultEntrada = ResultEntrada();
      //traemos la orden de compra de la bd
      final respnonseEntradaDb = await db.entradasRepository
          .getEntradaById(event.resultEntrada.id ?? 0);
      resultEntrada = respnonseEntradaDb ?? ResultEntrada();
      print("-----------------");
      print(resultEntrada.toMap());
      print("-----------------");

      emit(CurrentOrdenesCompraState(resultEntrada));
    } catch (e, s) {
      print('Error en _onCurrentOrdenesCompra: $e, $s');
    }
  }

  //metodo pea crar un lote a un producto
  void _onCreateLoteProduct(
      CreateLoteProduct event, Emitter<RecepcionState> emit) async {
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

        await db.productEntradaRepository.setFieldTableProductEntrada(
          currentProduct.idRecepcion,
          int.parse(currentProduct.productId),
          "lote_id",
          response.result?.result?.id ?? 0,
          currentProduct.idMove,
        );
        //actualizamos el lote name
        await db.productEntradaRepository.setFieldTableProductEntrada(
          currentProduct.idRecepcion,
          int.parse(currentProduct.productId),
          "lot_name",
          response.result?.result?.name ?? '',
          currentProduct.idMove,
        );
        await db.productEntradaRepository.setFieldTableProductEntrada(
          currentProduct.idRecepcion,
          int.parse(currentProduct.productId),
          "lote_date",
          response.result?.result?.expirationDate ?? '',
          currentProduct.idMove,
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

  //metodo para enviar el producto a wms
  void _onSendProductToOrder(
      SendProductToOrder event, Emitter<RecepcionState> emit) async {
    try {
      emit(SendProductToOrderLoading());

      final userid = await PrefUtils.getUserId();

      print("loteeeeeee: ${lotesProductCurrent.toMap()}");

      //calculamos la fecha de transaccion
      DateTime fechaTransaccion = DateTime.now();
      String fechaFormateada = formatoFecha(fechaTransaccion);
      //agregamos la fecha de transaccion
      await db.productEntradaRepository.setFieldTableProductEntrada(
        currentProduct.idRecepcion ?? 0,
        int.parse(currentProduct.productId),
        'date_transaction',
        fechaFormateada,
        currentProduct.idMove ?? 0,
      );

      final productBD = await db.productEntradaRepository.getProductById(
        int.parse(currentProduct.productId),
        currentProduct.idMove,
        currentProduct.idRecepcion,
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
      await db.productEntradaRepository.setFieldTableProductEntrada(
        currentProduct.idRecepcion ?? 0,
        int.parse(currentProduct.productId),
        'time',
        time,
        currentProduct.idMove ?? 0,
      );

      final responseSend = await _recepcionRepository.sendProductRecepcion(
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
              observacion: productBD?.observation == ""
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

      if (responseSend.result?.code == 200) {
        //AISGAMOS EL NOMBRE DE LA UBICACION DESTINO
        await db.productEntradaRepository.setFieldTableProductEntrada(
            currentProduct.idRecepcion ?? 0,
            int.parse(currentProduct.productId),
            "location_dest_name",
            configurations.result?.result?.scanDestinationLocationReception ==
                    true
                ? currentUbicationDest?.name ?? ''
                : productBD?.locationDestName ?? '',
            currentProduct.idMove ?? 0);
        // marcamos tiempo final de sepfaracion
        await db.productEntradaRepository.setFieldTableProductEntrada(
            currentProduct.idRecepcion ?? 0,
            int.parse(currentProduct.productId),
            "is_done_item",
            1,
            currentProduct.idMove ?? 0);

        if (event.isSplit) {
          print("Es un producto split");
          //calculamos la cantidad pendiente del producto
          var pendingQuantity =
              (currentProduct.cantidadFaltante - event.quantity);
          //creamos un nuevo producto (duplicado) con la cantidad separada
          await db.productEntradaRepository.insertDuplicateProducto(
              currentProduct, pendingQuantity, currentProduct.type ?? "");
        }

        await db.productEntradaRepository.setFieldTableProductSendEntrada(
            currentProduct.idRecepcion ?? 0,
            int.parse(currentProduct.productId),
            "quantity_done",
            event.quantity ?? 0,
            currentProduct.idMove);

        //actualizamos el idMove del producto que ya fue enviado
        await db.productEntradaRepository.setFieldTableProductSendEntrada(
            currentProduct.idRecepcion ?? 0,
            int.parse(currentProduct.productId),
            "id_move",
            responseSend.result?.result?.first.id ?? 0,
            currentProduct.idMove);

        //si el producto cuaenta con temperatura pedimos temperatura
        if (currentProduct.manejaTemperatura == 1 ||
            currentProduct.manejaTemperatura == true) {
          emit(GetTemperatureProduct(
            moveLineId: responseSend.result?.result?.first.id ?? 0,
          ));
          return;
        } else {
          add(GetPorductsToEntrada(currentProduct.idRecepcion ?? 0,
              resultEntrada.type == 'dev' ? 'dev' : 'reception'));
          lotesProductCurrent = LotesProduct();
          dateInicio = '';
          dateFin = '';
          emit(SendProductToOrderSuccess());
        }
      } else {
        // actualizamos estos datos si el producto no fue enviado correctamente

        await db.productEntradaRepository.setFieldTableProductEntrada(
            currentProduct.idRecepcion,
            int.parse(currentProduct.productId),
            "quantity_done",
            0,
            currentProduct.idMove);
        await db.productEntradaRepository.setFieldTableProductEntrada(
            currentProduct.idRecepcion,
            int.parse(currentProduct.productId),
            "is_selected",
            0,
            currentProduct.idMove);
        await db.productEntradaRepository.setFieldTableProductEntrada(
            currentProduct.idRecepcion,
            int.parse(currentProduct.productId),
            "quantity_separate",
            null,
            currentProduct.idMove);
        await db.productEntradaRepository.setFieldTableProductEntrada(
            currentProduct.idRecepcion,
            int.parse(currentProduct.productId),
            "date_end",
            "",
            currentProduct.idMove);
        await db.productEntradaRepository.setFieldTableProductEntrada(
            currentProduct.idRecepcion,
            int.parse(currentProduct.productId),
            "date_transaction",
            "",
            currentProduct.idMove);
        await db.productEntradaRepository.setFieldTableProductEntrada(
            currentProduct.idRecepcion,
            int.parse(currentProduct.productId),
            "is_separate",
            0,
            currentProduct.idMove);
        await db.productEntradaRepository.setFieldTableProductEntrada(
            currentProduct.idRecepcion,
            int.parse(currentProduct.productId),
            "is_product_split",
            0,
            currentProduct.idMove);
        await db.productEntradaRepository.setFieldTableProductEntrada(
            currentProduct.idRecepcion,
            int.parse(currentProduct.productId),
            "time",
            null,
            currentProduct.idMove);

        add(GetPorductsToEntrada(currentProduct.idRecepcion ?? 0,
            resultEntrada.type == 'dev' ? 'dev' : 'reception'));
        emit(SendProductToOrderFailure(responseSend.result?.msg ?? ""));
      }
    } catch (e, s) {
      emit(SendProductToOrderFailure('Error al enviar el producto'));
      print('Error en el _onSendProductToOrder: $e, $s');
    }
  }

  getProduct() async {
    final productBD = await db.productEntradaRepository.getProductById(
      int.parse(currentProduct.productId),
      currentProduct.idMove,
      currentProduct.idRecepcion,
    );
    print('productBD: ${productBD?.toMap()}');
  }

  //*metodo para obtener todos los lotes de un producto
  void _onGetLotesProduct(
      GetLotesProduct event, Emitter<RecepcionState> emit) async {
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

  //*Metodo para finalizar un producto Split
  void _onFinalizarRecepcionProductoSplit(FinalizarRecepcionProductoSplit event,
      Emitter<RecepcionState> emit) async {
    try {
      emit(FinalizarRecepcionProductoSplitLoading());

      dateFin = DateTime.now().toString();

      //marcamos tiempo final de separacion
      await db.productEntradaRepository.setFieldTableProductEntrada(
          currentProduct.idRecepcion,
          int.parse(currentProduct.productId),
          "date_end",
          dateFin,
          currentProduct.idMove);
      //actualizamso el estado del producto como separado
      await db.productEntradaRepository.setFieldTableProductEntrada(
          currentProduct.idRecepcion,
          int.parse(currentProduct.productId),
          "is_separate",
          1,
          currentProduct.idMove);

      //marcamos el producto como split
      await db.productEntradaRepository.setFieldTableProductEntrada(
          currentProduct.idRecepcion,
          int.parse(currentProduct.productId),
          "is_product_split",
          1,
          currentProduct.idMove);

      emit(FinalizarRecepcionProductoSplitSuccess());
    } catch (e, s) {
      print('Error al finalizar la recepcion del producto split: $e, $s');
    }
  }

  //*Metodo pra finalizar un producto de se recepcion
  void _onFinalizarRecepcionProducto(
      FinalizarRecepcionProducto event, Emitter<RecepcionState> emit) async {
    try {
      emit(FinalizarRecepcionProductoLoading());
      dateFin = DateTime.now().toString();
      //marcamos el producto como terminado
      await db.productEntradaRepository.setFieldTableProductEntrada(
          currentProduct.idRecepcion,
          int.parse(currentProduct.productId),
          "is_separate",
          1,
          currentProduct.idMove);

      //marcamos tiempo final de separacion
      await db.productEntradaRepository.setFieldTableProductEntrada(
          currentProduct.idRecepcion,
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

//*meotod para cargar todas las novedades
  void _onLoadAllNovedadesEvent(
      LoadAllNovedadesOrderEvent event, Emitter<RecepcionState> emit) async {
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

  //*evento para aumentar la cantidad
  void _onAddQuantitySeparateEvent(
      AddQuantitySeparate event, Emitter<RecepcionState> emit) async {
    try {
      if (quantitySelected > (currentProduct.cantidadFaltante ?? 0)) {
        return;
      } else {
        quantitySelected = quantitySelected + event.quantity;
        await db.productEntradaRepository.incremenQtytProductSeparatePacking(
            event.idRecepcion, event.productId, event.idMove, event.quantity);
        emit(ChangeQuantitySeparateState(quantitySelected));
      }
    } catch (e, s) {
      emit(ChangeQuantitySeparateErrorOrder('Error al aumentar cantidad'));
      print("❌ Error en el AddQuantitySeparate $e ->$s");
    }
  }

  //*evento para ver la cantidad
  void _onShowQuantityEvent(
      ShowQuantityOrderEvent event, Emitter<RecepcionState> emit) {
    try {
      viewQuantity = !viewQuantity;
      emit(ShowQuantityOrderState(viewQuantity));
    } catch (e, s) {
      print("❌ Error en _onShowQuantityEvent: $e, $s");
    }
  }

  void _onChangeQuantityIsOkEvent(
      ChangeIsOkQuantity event, Emitter<RecepcionState> emit) async {
    if (event.isOk) {
      await db.productEntradaRepository.setFieldTableProductEntrada(
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

  void _onChangeQuantitySelectedEvent(
      ChangeQuantitySeparate event, Emitter<RecepcionState> emit) async {
    try {
      if (event.quantity > 0.0) {
        quantitySelected = event.quantity;
        await db.productEntradaRepository.setFieldTableProductEntrada(
            event.idRecepcion,
            event.productId,
            "quantity_done",
            event.quantity,
            event.idMove);
      }
      emit(ChangeQuantitySeparateState(quantitySelected));
    } catch (e, s) {
      print('Error en _onChangeQuantitySelectedEvent: $e, $s');
    }
  }

  void _onChangeProductIsOkEvent(
      ChangeProductIsOkEvent event, Emitter<RecepcionState> emit) async {
    if (event.productIsOk) {
      dateInicio = DateTime.now().toString();
      //actualizmso valor de fecha inicio
      await db.productEntradaRepository.setFieldTableProductEntrada(
        event.idEntrada,
        event.productId,
        'date_start',
        dateInicio,
        event.idMove,
      );

      //actualizamos la entrada a true
      await db.entradasRepository.setFieldTableEntrada(
        event.idEntrada,
        "is_selected",
        1,
      );

      await db.productEntradaRepository.setFieldTableProductEntrada(
          event.idEntrada,
          event.productId,
          "is_selected",
          1,
          currentProduct.idMove ?? 0);

      //actualizamos el producto a true
      await db.productEntradaRepository.setFieldTableProductEntrada(
        event.idEntrada,
        event.productId,
        "product_is_ok",
        1,
        event.idMove,
      );
      //actualizamos la cantidad separada
      await db.productEntradaRepository.setFieldTableProductEntrada(
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

  void _onChangeLoteIsOkEvent(
      SelectecLoteEvent event, Emitter<RecepcionState> emit) async {
    //agregamos el lote al producto

    selectLote = event.lote.name ?? '';

    lotesProductCurrent = event.lote;

    //actualizamos el lote id
    await db.productEntradaRepository.setFieldTableProductEntrada(
      currentProduct.idRecepcion,
      int.parse(currentProduct.productId),
      "lote_id",
      event.lote.id,
      currentProduct.idMove,
    );
    //actualizamos el lote name
    await db.productEntradaRepository.setFieldTableProductEntrada(
      currentProduct.idRecepcion,
      int.parse(currentProduct.productId),
      "lot_name",
      event.lote.name,
      currentProduct.idMove,
    );

    await db.productEntradaRepository.setFieldTableProductEntrada(
      currentProduct.idRecepcion,
      int.parse(currentProduct.productId),
      "lote_date",
      event.lote.expirationDate ?? '',
      currentProduct.idMove,
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

//*evento para limpiar el valor del scan
  void _onClearScannedValueEvent(
      ClearScannedValueOrderEvent event, Emitter<RecepcionState> emit) {
    try {
      switch (event.scan) {
        case 'product':
          scannedValue2 = '';
          emit(ClearScannedValueOrderState());
          break;
        case 'quantity':
          scannedValue3 = '';
          emit(ClearScannedValueOrderState());
          break;
        case 'lote':
          scannedValue4 = '';
          emit(ClearScannedValueOrderState());
          break;
        case 'toDo':
          scannedValue5 = '';
          emit(ClearScannedValueOrderState());
          break;

        case 'locationDest':
          scannedValue6 = '';
          emit(ClearScannedValueOrderState());
          break;

        default:
          print('Scan type not recognized: ${event.scan}');
      }
      emit(ClearScannedValueOrderState());
    } catch (e, s) {
      print("❌ Error en _onClearScannedValueEvent: $e, $s");
    }
  }

  //*evento para actualizar el valor del scan
  void _onUpdateScannedValueEvent(
      UpdateScannedValueOrderEvent event, Emitter<RecepcionState> emit) {
    try {
      switch (event.scan) {
        case 'product':
          scannedValue2 += event.scannedValue.trim();
          print('scannedValue2: $scannedValue2');
          emit(UpdateScannedValueOrderState(scannedValue2, event.scan));
          break;
        case 'quantity':
          scannedValue3 += event.scannedValue.trim();
          print('scannedValue3: $scannedValue3');
          emit(UpdateScannedValueOrderState(scannedValue3, event.scan));
          break;
        case 'lote':
          print('scannedValue4: $scannedValue4');
          scannedValue4 += event.scannedValue.trim();
          emit(UpdateScannedValueOrderState(scannedValue4, event.scan));
          break;
        case 'toDo':
          print('scannedValue5: $scannedValue5');
          scannedValue5 += event.scannedValue.trim();
          emit(UpdateScannedValueOrderState(scannedValue5, event.scan));
          break;
        case 'locationDest':
          scannedValue6 += event.scannedValue.trim();
          emit(UpdateScannedValueOrderState(scannedValue6, event.scan));
          print('scannedValue6: $scannedValue6');

        default:
          print('Scan type not recognized: ${event.scan}');
      }
    } catch (e, s) {
      print("❌ Error en _onUpdateScannedValueEvent: $e, $s");
    }
  }

  //*metodo para validar los campos de la vista
  void _onValidateFieldsOrder(
      ValidateFieldsOrderEvent event, Emitter<RecepcionState> emit) {
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

  //*metodo para cargar la informacion del producto actual
  void _onFetchPorductOrder(
      FetchPorductOrder event, Emitter<RecepcionState> emit) async {
    try {
      isProductOk = true;
      isQuantityOk = true;
      isLocationDestOk = true;
      isLoteOk = true;
      viewQuantity = false;

      // final product = await db.productEntradaRepository.getProductById(
      //     int.parse(event.product.productId),
      //     event.product.idMove,
      //     event.product.idRecepcion);

      emit(FetchPorductOrderLoading());

      // traemos toda la lista de barcodes
      listOfBarcodes.clear();
      currentProduct = event.product;
      listOfBarcodes = await db.barcodesPackagesRepository.getBarcodesProduct(
          currentProduct.idRecepcion ?? 0,
          int.parse(currentProduct.productId),
          currentProduct.idMove ?? 0,
          'reception');

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

  //*metodo para obtener los productos de una entrada por id
  void _onGetProductsToEntrada(
      GetPorductsToEntrada event, Emitter<RecepcionState> emit) async {
    try {
      emit(GetProductsToEntradaLoading());
      final response = await db.productEntradaRepository
          .getProductsByRecepcionId(event.idEntrada);

      if (response != null && response is List) {
        listProductsEntrada = [];
        listProductsEntrada = response;

        //despues de obtener los productos, obtenemos todos los barcodes de esta entrada
        listAllOfBarcodes.clear();
        final responseBarcodes = await db.barcodesPackagesRepository
            .getBarcodesByBatchIdAndType(event.idEntrada, event.type);

        if (responseBarcodes != null && responseBarcodes is List) {
          listAllOfBarcodes = responseBarcodes;
        }

        print("listAllOfBarcodes : ${listAllOfBarcodes.length}");

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

//*metodo para obtener los permisos del usuario
  void _onAssignUserToOrder(
      AssignUserToOrder event, Emitter<RecepcionState> emit) async {
    try {
      int userId = await PrefUtils.getUserId();
      String nameUser = await PrefUtils.getUserName();
      emit(AssignUserToOrderLoading());
      final response = await _recepcionRepository.assignUserToOrder(
        true,
        userId,
        event.order.id ?? 0,
      );

      if (response) {
        //actualizamos la tabla entrada:
        await db.entradasRepository.setFieldTableEntrada(
          event.order.id ?? 0,
          "responsable_id",
          userId,
        );

        await db.entradasRepository.setFieldTableEntrada(
          event.order.id ?? 0,
          "responsable",
          nameUser,
        );
        await db.entradasRepository.setFieldTableEntrada(
          event.order.id ?? 0,
          "is_selected",
          1,
        );

        add(StartOrStopTimeOrder(
          event.order.id ?? 0,
          "start_time_reception",
        ));

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
      SearchOrdenCompraEvent event, Emitter<RecepcionState> emit) async {
    try {
      listFiltersOrdenesCompra = [];
      listFiltersOrdenesCompra = listOrdenesCompra;
      final query = event.query.toLowerCase();
      if (query.isEmpty) {
        listFiltersOrdenesCompra = listOrdenesCompra;
      } else {
        listFiltersOrdenesCompra = listFiltersOrdenesCompra.where((element) {
          // Filtrar por nombre o proveedor (si el proveedor no es nulo o vacío)
          return element.name!.toLowerCase().contains(query) ||
              (element.proveedor != null &&
                  element.proveedor!.toLowerCase().contains(query)) ||
              (element.purchaseOrderName != null &&
                  element.purchaseOrderName!.toLowerCase().contains(query)) ||
              (element.origin != null &&
                  element.origin!.toLowerCase().contains(query)) ||
              (element.backorderName != null &&
                  element.backorderName!.toLowerCase().contains(query));
        }).toList();
      }

      emit(SearchOrdenCompraSuccess(listFiltersOrdenesCompra));
    } catch (e, s) {
      emit(SearchOrdenCompraFailure('Error al buscar la orden de compra'));
      print('Error en el _onSearchPedidoEvent: $e, $s');
    }
  }

  //*metodo para obtener las entradas desde wms
  void _onFetchOrdenesCompra(
      FetchOrdenesCompra event, Emitter<RecepcionState> emit) async {
    try {
      emit(FetchOrdenesCompraLoading());

      listFiltersOrdenesCompra.clear();

      await db.deleRecepcion('reception');

      final response =
          await _recepcionRepository.fetchAllReceptions(event.isLoadinDialog);

      if ((response.result?.updateVersion ?? false) == true) {
        emit(NeedUpdateVersionState());
      }

      if (response.result?.code == 200) {
        if (response.result?.result?.isNotEmpty == true) {
          final listRecepcion = response.result?.result;

          await db.entradasRepository
              .insertEntrada(response.result?.result ?? [], 'reception');

          final productsToInsert =
              _getAllProducts(listRecepcion!).toList(growable: false);
          final productsSedToInsert =
              _getAllSentProducts(listRecepcion).toList(growable: false);
          final allBarcodes =
              _getAllBarcodes(listRecepcion).toList(growable: false);

          // Enviar la lista agrupada a insertBatchProducts
          await db.productEntradaRepository
              .insertarProductoEntrada(productsToInsert, 'reception');

          await db.productEntradaRepository
              .insertarProductoEntrada(productsSedToInsert, 'reception');

          // Enviar la lista agrupada de barcodes de un producto para packing
          await db.barcodesPackagesRepository
              .insertOrUpdateBarcodes(allBarcodes, 'reception');

          print("listRecepcion: ${listRecepcion.length}");
          print("productsToInsert: ${productsToInsert.length}");
          print('productsSedToInsert : ${productsSedToInsert.length}');
          print("allBarcodes: ${allBarcodes.length}");

          add(FetchOrdenesCompraOfBd());
          emit(FetchOrdenesCompraSuccess(
            response.result?.result ?? [],
          ));
        } else {
          emit(FetchOrdenesCompraSuccess(
            response.result?.result ?? [],
          ));
        }
      } else {
        if (response.result?.code == 403) {
          emit(DeviceNotAuthorized());
          return;
        }
        emit(FetchOrdenesCompraFailure(response.result?.msg ?? ''));
      }
    } catch (e, s) {
      print('Error en RecepcionBloc: $e, $s');
    }
  }

  Iterable<LineasTransferencia> _getAllProducts(
      List<ResultEntrada> batches) sync* {
    for (final batch in batches) {
      if (batch.lineasRecepcion != null) yield* batch.lineasRecepcion!;
    }
  }

  Iterable<LineasTransferencia> _getAllSentProducts(
      List<ResultEntrada> batches) sync* {
    for (final batch in batches) {
      if (batch.lineasRecepcionEnviadas != null) {
        yield* batch.lineasRecepcionEnviadas!;
      }
    }
  }

  Iterable<Barcodes> _getAllBarcodes(List<ResultEntrada> batches) sync* {
    for (final batch in batches) {
      if (batch.lineasRecepcion != null) {
        for (final product in batch.lineasRecepcion!) {
          if (product.otherBarcodes != null) yield* product.otherBarcodes!;
          if (product.productPacking != null) yield* product.productPacking!;
        }
      }
    }
  }

  //*metodo para obtener las entradas desde la bd
  void _onFetchOrdenesCompraOfBd(
      FetchOrdenesCompraOfBd event, Emitter<RecepcionState> emit) async {
    try {
      emit(FetchOrdenesCompraOfBdLoading());
      final listbd = await db.entradasRepository.getAllEntradas('reception');
      listOrdenesCompra.clear();
      listFiltersOrdenesCompra.clear();
      if (listbd != null && listbd.isNotEmpty) {
        listOrdenesCompra = listbd;
        listFiltersOrdenesCompra = listbd;

        tiposRecepcion = obtenerTiposReceptions(listFiltersOrdenesCompra);
      } else {
        emit(FetchOrdenesCompraOfBdFailure(
            'No hay ordenes de compra en la base de datos'));
      }

      emit(FetchOrdenesCompraOfBdSuccess(listFiltersOrdenesCompra));
    } catch (e, s) {
      emit(FetchOrdenesCompraOfBdFailure(
          'Error al obtener las ordenes de compra'));
      print('Error en el _onFetchOrdenesCompraOfBd: $e, $s');
    }
  }

  List<String> obtenerTiposReceptions(List<ResultEntrada> transferencias) {
    final Set<String> tipos = {};

    final RegExp regExp = RegExp(r'^.*?/([^/]+)/');

    for (final t in transferencias) {
      final name = t.name;
      if (name != null) {
        final match = regExp.firstMatch(name);
        if (match != null && match.groupCount >= 1) {
          tipos.add(match.group(1)!);
        }
      }
    }

    return tipos.toList();
  }

  //*metodo para ocultar y mostrar el teclado
  void _onShowKeyboardEvent(
      ShowKeyboardEvent event, Emitter<RecepcionState> emit) {
    isKeyboardVisible = event.showKeyboard;
    emit(ShowKeyboardState(showKeyboard: isKeyboardVisible));
  }

  //*metodo para cargar la configuracion del usuario
  void _onLoadConfigurationsUserEvent(
      LoadConfigurationsUserOrder event, Emitter<RecepcionState> emit) async {
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
}
