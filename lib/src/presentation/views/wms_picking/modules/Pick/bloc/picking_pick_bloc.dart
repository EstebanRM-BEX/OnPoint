// ignore_for_file: prefer_is_empty

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/src/core/utils/formats_utils.dart';
import 'package:wms_app/src/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/src/presentation/models/novedades_response_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/inventario/data/inventario_repository.dart';
import 'package:wms_app/src/presentation/views/transferencias/data/transferencias_repository.dart';
import 'package:wms_app/src/presentation/views/transferencias/models/requets_transfer_model.dart';

import 'package:wms_app/src/presentation/views/user/models/configuration.dart';
import 'package:wms_app/src/presentation/views/wms_picking/data/wms_picking_repository.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/submeuelle_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/data/picking_pick_repository.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/PickhWithProducts_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/response_pick_done_id_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/response_pick_model.dart';

part 'picking_pick_event.dart';
part 'picking_pick_state.dart';

class PickingPickBloc extends Bloc<PickingPickEvent, PickingPickState> {
  PickingPickRepository pickingPickRepository = PickingPickRepository();

  List<ResultPick> listOfPick = [];
  List<ResultPick> listOfPickFiltered = [];

  List<ResultPick> historyPicks = [];
  List<ResultPick> filtersHistoryPicks = [];

  RespondePickDoneId historyPickId = RespondePickDoneId();

  ///listado de pickos por componenetes
  List<ResultPick> listOfPickCompo = [];
  List<ResultPick> listOfPickCompoFiltered = [];

  //*lista de productos
  List<ProductsBatch> filteredProducts = [];
  List<ProductsBatch> listProducts = [];
  List<String> listOfProductsName = [];
  List<Barcodes> listOfBarcodes = [];

  //*lista de muelles
  List<String> muelles = [];
  List<Muelles> submuelles = [];

  Muelles subMuelleSelected = Muelles();

  DataBaseSqlite db = DataBaseSqlite();

  PickWithProducts pickWithProducts = PickWithProducts();
  //*producto en posicion actual
  ProductsBatch currentProduct = ProductsBatch();

  //*controller para la busqueda
  TextEditingController searchController = TextEditingController();
  TextEditingController searchPickController = TextEditingController();
  //*controller para editarProducto
  TextEditingController editProductController = TextEditingController();

  //*lista de novedades
  List<Novedad> novedades = [];
  //*lista de todas las pocisiones de los productos del batchs
  List<String> positionsOrigen = [];
  String oldLocation = ''; //variable para guardar la ultima ubicacion usada
  //*variables para validar
  bool locationIsOk = false;
  bool productIsOk = false;
  bool locationDestIsOk = false;
  bool quantityIsOk = false;

  //variable de apoyo
  bool isSearch = true;
  //*valores de scanvalue

  String scannedValue1 = '';
  String scannedValue2 = '';
  String scannedValue3 = '';
  String scannedValue4 = '';
  String scannedValue5 = '';

  String selectedNovedad = '';

  // //*validaciones de campos del estado de la vista
  bool isLocationOk = true;
  bool isProductOk = true;
  bool isLocationDestOk = true;
  bool isQuantityOk = true;

  //configuracion del usuario //permisos
  Configurations configurations = Configurations();

  TransferenciasRepository repository = TransferenciasRepository();
  WmsPickingRepository repositoryBatch = WmsPickingRepository();

  dynamic quantitySelected = 0;

  //*indice del producto actual
  int index = 0;

  //*indice del producto actual
  bool _isProcessing = false; // Bandera para controlar el estado del proceso
  bool isProcessing = false; // Bandera para controlar el estado del proceso
  bool isKeyboardVisible = false;
  bool viewQuantity = false;

  //repositorio de inventario
  InventarioRepository inventarioRepository = InventarioRepository();

  PickingPickBloc() : super(PickingPickInitial()) {
    on<PickingPickEvent>((event, emit) {});
    on<FetchPickingPickEvent>(_onFetchPickingPickEvent);
    on<FetchPickingPickFromDBEvent>(_onFetchPickingPickFromDBEvent);
    //*evento para obtener todas las novedades
    on<LoadAllNovedadesPickEvent>(_onLoadAllNovedadesEvent);
    // //* Cargar los productos de un pick desde SQLite
    on<FetchPickWithProductsEvent>(_onFetchPickWithProductsEvent);
    //*evento para obtener los barcodes de un producto por paquete
    on<FetchBarcodesProductEvent>(_onFetchBarcodesProductEvent);
    //*evento para cargaar la informacion del pick
    on<LoadDataInfoEvent>(_onLoadDataInfoEvent);
    //*evento para obtener la configuracion del usuario
    on<LoadConfigurationsUser>(_onLoadConfigurationsUserEvent);
    //*evento para mostrar el teclado
    on<ShowKeyboard>(_onShowKeyboardEvent);

    //*obtener todos los pick desde el historial de odoo
    on<LoadHistoryPickEvent>(_onLoadHistoryPickEvent);

    //todo escanear producto
    //*cambiar el estado de las variables
    on<ChangeLocationIsOkEvent>(_onChangeLocationIsOkEvent);
    on<ChangeLocationDestIsOkEvent>(_onChangeLocationDestIsOkEvent);
    on<ChangeProductIsOkEvent>(_onChangeProductIsOkEvent);
    on<ChangeIsOkQuantity>(_onChangeQuantityIsOkEvent);
    //*cambiar el producto actual
    on<ChangeCurrentProduct>(_onChangeCurrentProduct);

    on<SelectNovedadEvent>(_onSelectNovedadEvent);

    on<ValidateFieldsEvent>(_onValidateFields);

    //*evento para actualizar el valor del scan
    on<UpdateScannedValueEvent>(_onUpdateScannedValueEvent);
    on<ClearScannedValueEvent>(_onClearScannedValueEvent);
    //*evento para cambiar la cantidad seleccionada
    on<ChangeQuantitySeparate>(_onChangeQuantitySelectedEvent);
    on<AddQuantitySeparate>(_onAddQuantitySeparateEvent);

    //*evento para ver la cantidad
    on<ShowQuantityEvent>(_onShowQuantityEvent);

    //*evento para seleccionar un submuelle
    on<SelectedSubMuelleEvent>(_onSelectecSubMuelle);
    //*evento para asignar el submuelle
    on<AssignSubmuelleEvent>(_onAssignSubmuelleEvent);
    //*metodo para establecer un proceso en ejecucion
    on<SetIsProcessingEvent>(_onSetIsProcessingEvent);

    //*evento para dejar pendiente la separacion
    on<ProductPendingEvent>(_onPickingPendingEvent);
    // //* Buscar un producto en un lote en SQLite
    on<SearchProductsPickEvent>(_onSearchBacthEvent);
    // //* Limpiar la búsqueda
    on<ClearSearchProudctsPickEvent>(_onClearSearchEvent);

    //*evento para enviar un producto a odoo
    on<SendProductOdooPickEvent>(_onSendProductOdooEvent);
    //*evento para enviar un producto a odoo editado
    on<SendProductEditOdooEvent>(_onSendProductEditOdooEvent);
    //*evento para finalizar la separacion
    on<PickingOkEvent>(_onPickingOkEvent);
    //*evento para editar un producto
    on<LoadProductEditEvent>(_onEditProductEvent);

    //*asignar un usuario a una orden de compra
    on<AssignUserToTransfer>(_onAssignUserToTransfer);

    //* evento para empezar o terminar el tiempo
    on<StartOrStopTimeTransfer>(_onStartOrStopTimeTransfer);

    //*buscar un batch
    on<SearchPickEvent>(_onSearchPickEvent);

    //*metodo para crear barckorder o no
    on<CreateBackOrderOrNot>(_onCreateBackOrder);
    //*metodo para cerrar el pick sin validarlo
    on<PickOkEvent>(_onPickOkEvent);

    //*metodo para validar la confirmacion
    on<ValidateConfirmEvent>(_onValidateConfirmEvent);
    //evento par aobtener todos los muelles disponibles
    on<FetchMuellesEvent>(_onFetchMuellesEvent);

    //*evento para cargar un producto seleccionado
    on<LoadSelectedProductEvent>(_onLoadSelectedProductEvent);

    //*obtener un batch por id del hisorial
    on<LoadHistoryPickIdEvent>(_onLoadHistoryBatchIdEvent);

    //todo picking para componentes
    on<FetchPickingComponentesEvent>(_onFetchPickingComponentesEvent);

    on<FetchPickingComponentesFromDBEvent>(
        _onFetchPickingComponentesFromDBEvent);

    //*obtener todos los pick de componentes desde el historial de odoo
    on<LoadHistoryPickComponentEvent>(_onLoadHistoryPickComponentEvent);
    //*ver imagen del producto
    on<ViewProductImageEvent>(_onViewProductImageEvent);

    on<SortPickListEvent>((event, emit) {
      // Creamos una copia de la lista actual para no mutar el estado directamente
      List<ResultPick> sortedList = List.from(listOfPickFiltered);
      // O usa `this.listOfPickFiltered` si lo manejas como variable de clase
      sortedList.sort((a, b) {
        int result = 0;
        switch (event.field) {
          case 'priority':
            // Asumiendo que priority '1' es Alta y '0' es Normal
            final pA = a.priority ?? '0';
            final pB = b.priority ?? '0';
            result = pA.compareTo(pB);
            break;
          case 'date':
            // Parsear fechas
            final dateA =
                DateTime.tryParse(a.fechaCreacion ?? '') ?? DateTime(1900);
            final dateB =
                DateTime.tryParse(b.fechaCreacion ?? '') ?? DateTime(1900);
            result = dateA.compareTo(dateB);
            break;
          case 'name':
            final nameA = a.name ?? '';
            final nameB = b.name ?? '';
            result = nameA.toLowerCase().compareTo(nameB.toLowerCase());
            break;
        }
        return event.ascending ? result : -result; // Invertir si es descendente
      });
      // Actualiza la lista en el Bloc y emite el estado
      this.listOfPickFiltered = sortedList;
      // Asegúrate de emitir un estado que refresque la lista, ej:
      emit(PickingPickSuccess(sortedList));
    });
  }

  void _onViewProductImageEvent(
      ViewProductImageEvent event, Emitter<PickingPickState> emit) async {
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

  void _onLoadHistoryPickComponentEvent(LoadHistoryPickComponentEvent event,
      Emitter<PickingPickState> emit) async {
    try {
      print('date: ${event.date}');
      emit(PickingLoadingState());

      final response = await pickingPickRepository.resPicksComponentsDone(
        event.isLoadinDialog,
        event.date,
      );

      if (response != null && response is List) {
        historyPicks = [];
        filtersHistoryPicks = [];
        historyPicks.addAll(response);
        filtersHistoryPicks.addAll(response);

        emit(LoadHistoryPicksState(listOfBatchs: filtersHistoryPicks));
      } else {
        print('Error resHistoryBatchs: response is null');
      }
    } catch (e, s) {
      print('Error LoadHistoryBatchsEvent: $e, $s');
      emit(PickingErrorState(e.toString()));
    }
  }

  void _onLoadHistoryPickEvent(
      LoadHistoryPickEvent event, Emitter<PickingPickState> emit) async {
    try {
      print('date: ${event.date}');
      emit(PickingLoadingState());

      final response = await pickingPickRepository.resPicksDone(
        event.isLoadinDialog,
        event.date,
      );

      if (response != null && response is List) {
        historyPicks = [];
        filtersHistoryPicks = [];
        historyPicks.addAll(response);
        filtersHistoryPicks.addAll(response);

        emit(LoadHistoryPicksState(listOfBatchs: filtersHistoryPicks));
      } else {
        print('Error resHistoryBatchs: response is null');
      }
    } catch (e, s) {
      print('Error LoadHistoryBatchsEvent: $e, $s');
      emit(PickingErrorState(e.toString()));
    }
  }

  void _onLoadHistoryBatchIdEvent(
      LoadHistoryPickIdEvent event, Emitter<PickingPickState> emit) async {
    try {
      emit(PickingLoadingState());

      final response = await pickingPickRepository.getPicksDoneId(
        event.isLoadinDialog,
        event.idPicking,
      );

      if (response != null && response is RespondePickDoneId) {
        historyPickId = RespondePickDoneId();
        historyPickId = response;
        emit(BatchHistoryLoadedState(historyPickId));
      } else {
        print('Error resHistoryBatchs: response is null');
      }
    } catch (e, s) {
      print('Error LoadHistoryBatchsEvent: $e, $s');
      emit(BatchsPickingErrorState(e.toString()));
    }
  }

  //metodo para cargar un producto seleccionado
  void _onLoadSelectedProductEvent(
      LoadSelectedProductEvent event, Emitter<PickingPickState> emit) async {
    try {
      //limpiamos la busqueda
      add(ClearSearchProudctsPickEvent());
      currentProduct = event.selectedProduct;
      listOfBarcodes.clear();
      print("🔍 Lista de barcodes limpiada");

      listOfBarcodes = await db.barcodesPackagesRepository.getBarcodesProduct(
        pickWithProducts.pick?.id ?? 0,
        currentProduct.idProduct ?? 0,
        currentProduct.idMove ?? 0,
        "pick",
      );

      emit(LoadSelectedProductState(currentProduct));
    } catch (e, s) {
      print("❌ Error en _onLoadSelectedProductEvent: $e -> $s");
    }
  }

  //*evento para obtener todos los muelles disponibles
  void _onFetchMuellesEvent(
      FetchMuellesEvent event, Emitter<PickingPickState> emit) async {
    try {
      emit(MuellesLoadingState());
      submuelles.clear();
      final response = await repositoryBatch.getmuelles(false);
      if (response != null) {
        // Filtramos los muelles
        submuelles = response
            .where((muelle) =>
                muelle.locationId == pickWithProducts.pick?.muelleId)
            .toList();

        print("submuelles: ${submuelles.length}");
        emit(MuellesLoadedState(listOfMuelles: submuelles));
      } else {
        emit(MuellesErrorState('No se encontraron muelles'));
      }
    } catch (e, s) {
      emit(MuellesErrorState('Error al cargar los muelles'));
      print("❌ Error en __onLoadAllNovedadesEvent: $e, $s");
    }
  }

  void _onValidateConfirmEvent(
      ValidateConfirmEvent event, Emitter<PickingPickState> emit) async {
    try {
      emit(ValidateConfirmLoading());
      final response = await repository.confirmationValidate(
          event.idPick, event.isBackOrder, event.isLoadinDialog);

      if (response.result?.code == 200) {
        add(PickingOkEvent(
            pickWithProducts.pick?.id ?? 0, currentProduct.idProduct ?? 0));
        add(FetchPickingPickEvent(false));
        emit(ValidateConfirmSuccess(
            event.isBackOrder, response.result?.msg ?? ""));
      } else {
        emit(ValidateConfirmFailure(response.result?.msg ?? ''));
      }
    } catch (e, s) {
      emit(ValidateConfirmFailure('Error al validar la confirmacion'));
      print('Error en el _onValidateConfirmEvent: $e, $s');
    }
  }

  void _onFetchPickingComponentesEvent(FetchPickingComponentesEvent event,
      Emitter<PickingPickState> emit) async {
    emit(PickingPickCompoLoading());
    try {
      // Aquí llamas a tu repositorio para obtener los datos
      final result = await pickingPickRepository
          .resPickingComponentes(event.isLoadinDialog);

      listOfPickCompo = [];
      listOfPickCompoFiltered = [];

      if ((result.updateVersion ?? false) == true) {
        emit(NeedUpdateVersionState());
      }

      if (result.result?.isNotEmpty == true) {
        await db.pickRepository
            .insertAllPickingPicks(result.result!, 'pick-componentes');

        // Convertir el mapa en una lista de productos únicos con cantidades sumadas
        final productsIterable =
            _extractAllProducts(result.result!).toList(growable: false);

        final sentProductsIterable =
            _getAllSentProducts(result.result!).toList(growable: false);

        final allBarcodes =
            _extractAllBarcodes(result.result!).toList(growable: false);

        print('productsToInsert: ${productsIterable.length}');
        print('sentProductsIterable: ${sentProductsIterable.length}');
        print('allBarcodes: ${allBarcodes.length}');

        // Enviar la lista agrupada a insertBatchProducts
        await db.pickProductsRepository
            .insertPickProducts(productsIterable, 'pick-componentes');
        await db.pickProductsRepository
            .insertPickProducts(sentProductsIterable, 'pick-componentes');

        if (allBarcodes.isNotEmpty) {
          // Enviar la lista agrupada a insertBarcodesPackageProduct
          await DataBaseSqlite()
              .barcodesPackagesRepository
              .insertOrUpdateBarcodes(
                allBarcodes,
                'pick-componentes',
              );
        }

        add(FetchPickingComponentesFromDBEvent(true));
        emit(PickingPickCompoLoaded(result.result!));
        return;
      } else {
        emit(PickingPickCompoLoaded([]));
        return;
      }
    } catch (e) {
      emit(PickingPickCompoError(e.toString()));
    }
  }

  void _onFetchPickingComponentesFromDBEvent(
      FetchPickingComponentesFromDBEvent event,
      Emitter<PickingPickState> emit) async {
    emit(PickingPickCompoBDLoading());
    try {
      // Aquí llamas a tu repositorio para obtener los datos
      final result = await db.pickRepository.getAllPickingPicks(
        'pick-componentes',
      );
      listOfPickCompo = [];

      if (result.isNotEmpty) {
        listOfPickCompo = result;
        listOfPickCompoFiltered = result;
        emit(PickingPickCompoLoadedBD(listOfPickCompoFiltered));
        return;
      }
      emit(PickingPickCompoLoadedBD([]));
    } catch (e) {
      emit(PickingPickCompoError(e.toString()));
    }
  }

  void _onCreateBackOrder(
      CreateBackOrderOrNot event, Emitter<PickingPickState> emit) async {
    try {
      emit(CreateBackOrderOrNotLoading());

      print('Crear backorder: ${event.isBackOrder}');
      print('idPick: ${event.idPick}');

      final response = await repository.validateTransfer(
          event.idPick, event.isBackOrder, false);

      if (response.result?.code == 200) {
        add(StartOrStopTimeTransfer(
          event.idPick,
          'end_time_transfer',
        ));

        if (event.isExternalProduct == true) {
          add(LoadHistoryPickIdEvent(false, event.idPick));
        } else {
          add(ValidateFieldsEvent(field: "locationDest", isOk: true));
          add(ChangeLocationDestIsOkEvent(true, currentProduct.idProduct ?? 0,
              pickWithProducts.pick?.id ?? 0, currentProduct.idMove ?? 0));
          isSearch = true;
          add(PickingOkEvent(
              pickWithProducts.pick?.id ?? 0, currentProduct.idProduct ?? 0));
          //eliminamos el pick de la lista actual
          await db.pickRepository.deletePickById(event.idPick);
          //eliminamos de la lista en memoria
          listOfPick.removeWhere((pick) => pick.id == event.idPick);
          listOfPickFiltered.removeWhere((pick) => pick.id == event.idPick);
          //pedimos los nuevos picks
          add(FetchPickingPickEvent(false));
        }
        emit(CreateBackOrderOrNotSuccess(
            event.isBackOrder, response.result?.msg ?? ""));
      } else {
        emit(CreateBackOrderOrNotFailure(
          response.result?.msg ?? '',
          event.isBackOrder,
        ));
      }
    } catch (e, s) {
      emit(CreateBackOrderOrNotFailure(
        'Error al crear la backorder',
        event.isBackOrder,
      ));
      print('Error en el _onCreateBackOrder: $e, $s');
    }
  }

  void _onPickOkEvent(PickOkEvent event, Emitter<PickingPickState> emit) async {
    try {
      emit(CreateBackOrderOrNotLoading());

      add(StartOrStopTimeTransfer(
        event.idPick,
        'end_time_transfer',
      ));

      add(ValidateFieldsEvent(field: "locationDest", isOk: true));
      add(ChangeLocationDestIsOkEvent(true, currentProduct.idProduct ?? 0,
          pickWithProducts.pick?.id ?? 0, currentProduct.idMove ?? 0));
      isSearch = true;

      add(PickingOkEvent(
          pickWithProducts.pick?.id ?? 0, currentProduct.idProduct ?? 0));
      //pedimos los nuevos picks
      add(FetchPickingPickEvent(false));

      emit(PickOkEventSuccess('Pick cerrado correctamente'));
    } catch (e, s) {
      emit(CreateBackOrderOrNotFailure(
        'Error al crear la backorder',
        false,
      ));
      print('Error en el _onCreateBackOrder: $e, $s');
    }
  }

  void _onSearchPickEvent(
      SearchPickEvent event, Emitter<PickingPickState> emit) async {
    try {
      final query = event.query.toLowerCase();

      if (query.isEmpty) {
        if (event.isComponentes) {
          // ✅ Cuando el query está vacío y es de componentes, se muestra todo el listado de componentes
          listOfPickCompoFiltered = [];
          listOfPickCompoFiltered = listOfPickCompo;
        } else {
          // ✅ Cuando el query está vacío y NO es de componentes, se muestra todo el listado de pick
          filtersHistoryPicks = [];
          filtersHistoryPicks = historyPicks;
          listOfPickFiltered = [];
          listOfPickFiltered = listOfPick;
        }
      } else {
        if (event.isComponentes) {
          // Lógica de búsqueda para la lista de componentes
          listOfPickCompoFiltered = listOfPickCompo.where((batch) {
            final name = batch.name?.toLowerCase() ?? '';
            final origin = batch.origin?.toLowerCase() ?? '';
            final proveedor = batch.proveedor?.toLowerCase() ?? '';
            final backorder = batch.backorderName?.toLowerCase() ?? '';
            return name.contains(query) ||
                origin.contains(query) ||
                proveedor.contains(query) ||
                backorder.contains(query);
          }).toList();
        } else {
          // Lógica de búsqueda para la lista de pick
          listOfPickFiltered = listOfPick.where((batch) {
            final name = batch.name?.toLowerCase() ?? '';
            final origin = batch.origin?.toLowerCase() ?? '';
            final proveedor = batch.proveedor?.toLowerCase() ?? '';
            final backorder = batch.backorderName?.toLowerCase() ?? '';
            final zona = batch.zonaEntrega?.toLowerCase() ?? '';
            return name.contains(query) ||
                origin.contains(query) ||
                proveedor.contains(query) ||
                backorder.contains(query) ||
                zona.contains(query);
          }).toList();

          filtersHistoryPicks = historyPicks.where((batch) {
            final name = batch.name?.toLowerCase() ?? '';
            final origin = batch.referencia?.toLowerCase() ?? '';
            final proveedor = batch.proveedor?.toLowerCase() ?? '';
            final backorder = batch.backorderName?.toLowerCase() ?? '';
            final zona = batch.zonaEntrega?.toLowerCase() ?? '';
            return name.contains(query) ||
                origin.contains(query) ||
                proveedor.contains(query) ||
                backorder.contains(query) ||
                zona.contains(query);
          }).toList();
        }
      }

      emit(LoadSearchPickingState());
    } catch (e, s) {
      print('Error en _onSearchPickEvent: $e, $s');
    }
  }

  //metodo para empezar o terminar el tiempo
  void _onStartOrStopTimeTransfer(
      StartOrStopTimeTransfer event, Emitter<PickingPickState> emit) async {
    try {
      final time = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      print("time : $time");
      if (event.value == "start_time_transfer") {
        await db.pickRepository.setFieldTablePick(
          event.id,
          "start_time_transfer",
          time,
        );
        await db.pickRepository.setFieldTablePick(
          event.id,
          "is_selected",
          1,
        );
      } else if (event.value == "end_time_transfer") {
        await db.pickRepository.setFieldTablePick(
          event.id,
          "end_time_transfer",
          time,
        );
      }
      //hacemos la peticion de mandar el tiempo
      final response = await repository.sendTime(
        event.id,
        event.value,
        time,
        false,
      );

      if (response) {
        emit(StartOrStopTimeTransferSuccess(event.value));
      } else {
        emit(StartOrStopTimeTransferFailure('Error al enviar el tiempo'));
      }
    } catch (e, s) {
      print('Error en el _onStartOrStopTimeOrder: $e, $s');
    }
  }

  //*metodo para obtener los permisos del usuario
  void _onAssignUserToTransfer(
      AssignUserToTransfer event, Emitter<PickingPickState> emit) async {
    try {
      int userId = await PrefUtils.getUserId();
      String nameUser = await PrefUtils.getUserName();

      emit(AssignUserToPickLoading());
      final response = await repository.assignUserToTransfer(
        false,
        userId,
        event.id,
      );

      if (response) {
        //actualizamos la tabla entrada:
        await db.pickRepository.setFieldTablePick(
          event.id,
          "responsable_id",
          userId,
        );

        await db.pickRepository.setFieldTablePick(
          event.id,
          "responsable",
          nameUser,
        );
        await db.pickRepository.setFieldTablePick(
          event.id,
          "is_selected",
          1,
        );

        add(StartOrStopTimeTransfer(
          event.id,
          "start_time_transfer",
        ));

        emit(AssignUserToPickSuccess(
          event.id,
        ));
      } else {
        emit(AssignUserToPickError(
            "La recepción ya tiene un responsable asignado"));
      }
    } catch (e, s) {
      emit(AssignUserToPickError('Error al asignar el usuario'));
      print('Error en el _onAssignUserToOrder: $e, $s');
    }
  }

  //*evento para editar un producto
  void _onEditProductEvent(
      LoadProductEditEvent event, Emitter<PickingPickState> emit) async {
    try {
      final response = await db.pickProductsRepository
          .getPickWithProducts(pickWithProducts.pick?.id ?? 0);
      if (response?.products?.isEmpty == true) {
        emit(ProductEditError());
        return;
      }
      final List<ProductsBatch> products = response!.products!
          .where((product) =>
              product.quantitySeparate != product.quantity ||
              product.isSendOdoo == 0)
          .toList();
      filteredProducts.clear();
      filteredProducts.addAll(products);
      emit(LoadProductsBatchSuccesStateBD(
          listOfProductsBatch: filteredProducts));
    } catch (e, s) {
      print("❌ Error en el _onEditProductEvent: $e -> $s");
    }
  }

  ///* evento para finalizar la separacion
  void _onPickingOkEvent(
      PickingOkEvent event, Emitter<PickingPickState> emit) async {
    try {
      emit(PickingOkLoading());
      await db.pickRepository
          .setFieldTablePick(event.batchId, 'is_separate', 1);

      emit(PickingOkState());
    } catch (e, s) {
      emit(PickingOkError());
      print("❌ Error en PickingOkEvent $e -> $s");
    }
  }

  //*evento para enviar un producto a odoo editado
  void _onSendProductEditOdooEvent(
      SendProductEditOdooEvent event, Emitter<PickingPickState> emit) async {
    try {
      emit(LoadingSendProductEdit());
      bool responseEdit = await sendProuctEditOdoo(
        event.product,
        event.cantidad,
      );
      if (responseEdit) {
        final response = await db.pickProductsRepository
            .getPickWithProducts(pickWithProducts.pick?.id ?? 0);
        final List<ProductsBatch> products = response!.products!
            .where((product) => product.quantitySeparate != product.quantity)
            .toList();
        pickWithProducts.products = response.products;
        filteredProducts.clear();
        filteredProducts.addAll(products);
        emit(ProductEditOk());
      } else {
        emit(ProductEditError());
      }
    } catch (e, s) {
      print("❌ Error en el SendProductEditOdooEvent :$e->$s");
    }
  }

  Future<bool> sendProuctEditOdoo(
    ProductsBatch productEdit,
    dynamic cantidad,
  ) async {
    //traemos un producto de la base de datos  ya anteriormente guardado
    final product = await db.pickProductsRepository.getProductPick(
        productEdit.batchId ?? 0,
        productEdit.idProduct ?? 0,
        productEdit.idMove ?? 0);

    //todo: tiempor por batch
    // Calcular la diferencia
    // Obtener la diferencia en segundos
    final userid = await PrefUtils.getUserId();

    //asignamos timepo total si esta en null
    if (product?.timeSeparate == null) {
      await db.setFieldTableBatchProducts(
          productEdit.batchId ?? 0,
          productEdit.idProduct ?? 0,
          'time_separate',
          30,
          productEdit.idMove ?? 0,
          'pick');
    }

    DateTime fechaTransaccion = DateTime.now();
    String fechaFormateada = formatoFecha(fechaTransaccion);

    final response = await repository.sendProductTransferPick(
      TransferRequest(
        idTransferencia: currentProduct.batchId ?? 0,
        listItems: [
          ListItem(
            idMove: product?.idMove ?? 0,
            idProducto: product?.idProduct ?? 0,
            // idLote: product?.loteId ?? 0,
            idLote: 0,
            idUbicacionDestino: product?.muelleId ?? 0,
            cantidadEnviada: cantidad,
            idOperario: userid,
            timeLine: product?.timeSeparate == null
                ? 30.0
                : product?.timeSeparate.toDouble(),
            fechaTransaccion: product?.fechaTransaccion ?? fechaFormateada,
            observacion: (cantidad == product?.quantity)
                ? 'Sin novedad'
                : product?.observation == ""
                    ? 'Sin novedad'
                    : product?.observation ?? '',
            dividida: false,
          ),
        ],
      ),
      false,
    );

    if (response.result?.code == 200) {
      //recorremos todos los resultados de la respuesta
      for (var resultProduct in response.result!.result!) {
        await db.pickProductsRepository.setFieldTablePickProducts(
          resultProduct.idTransferencia ?? 0,
          resultProduct.idProduct ?? 0,
          'is_send_odoo',
          1,
          resultProduct.idMove ?? 0,
        );
      }

      return true;
    } else {
      //elementos que no se pudieron enviar a odoo
      await db.setFieldTableBatchProducts(
        product?.batchId ?? 0,
        product?.idProduct ?? 0,
        'is_send_odoo',
        0,
        product?.idMove ?? 0,
        'pick',
      );
      return false;
    }
  }

  void _onSendProductOdooEvent(
      SendProductOdooPickEvent event, Emitter<PickingPickState> emit) async {
    if (_isProcessing) {
      // Si ya está en proceso, no ejecutamos nada
      return;
    }
    final userid = await PrefUtils.getUserId();

    try {
      _isProcessing = true; // Activar la bandera para evitar duplicados
      emit(SendProductPickOdooLoading());

      DateTime dateTimeActuality = DateTime.parse(DateTime.now().toString());
      double secondsDifference = 0.0;

      try {
        // Calcular la diferencia en segundos
        Duration difference = dateTimeActuality.difference(DateTime.now());
        secondsDifference = difference.inMilliseconds / 1000.0;
        print("Diferencia en segundos: $secondsDifference");
      } catch (e) {
        print("❌ Error al parsear la fecha: $e");
      }

      DateTime fechaTransaccion = DateTime.now();
      String fechaFormateada = formatoFecha(fechaTransaccion);

      print('Enviando producto a Odoo: ${event.product.toMap()}');

      final response = await repository.sendProductTransferPick(
        TransferRequest(
          idTransferencia: currentProduct.batchId ?? 0,
          listItems: [
            ListItem(
              idMove: event.product.idMove ?? 0,
              idProducto: event.product.idProduct ?? 0,
              idLote: event.product.loteId ?? 0,
              idUbicacionDestino: event.product.muelleId ?? 0,
              cantidadEnviada: event.product.quantitySeparate ?? 0,
              idOperario: userid,
              timeLine: event.product.timeSeparate == null
                  ? 30.0
                  : event.product.timeSeparate.toDouble(),
              fechaTransaccion: event.product.fechaTransaccion == "" ||
                      event.product.fechaTransaccion == null
                  ? fechaFormateada
                  : event.product.fechaTransaccion ?? "",
              observacion: event.product.observation == ""
                  ? 'Sin novedad'
                  : event.product.observation ?? "",
              dividida: false,
            ),
          ],
        ),
        false,
      );

      if (response.result?.code == 200) {
        // Recorrer todos los resultados de la respuesta
        await db.pickProductsRepository.setFieldTablePickProducts(
          event.product.batchId ?? 0,
          event.product.idProduct ?? 0,
          'is_send_odoo',
          1,
          event.product.idMove ?? 0,
        );

        final response = await db.pickProductsRepository
            .getPickWithProducts(pickWithProducts.pick?.id ?? 0);

        print('isEdit: ${event.isEdit}');

        final List<ProductsBatch> products = event.isEdit
            ? response!.products!
                .where((product) =>
                    product.quantitySeparate != product.quantity ||
                    product.isSendOdoo == 0)
                .toList()
            : response!.products!;

        pickWithProducts.products = response.products;
        filteredProducts.clear();
        filteredProducts.addAll(products);

        emit(SendProductPickOdooSuccess());
      } else {
        //validamos si es el error que dice que la linea ya fue enviada entonces pasamos todo como enviado

        if (response.result?.msg?.contains('ya fue procesada anteriormente') ??
            false) {
          // Si la línea ya fue procesada, la marcamos como enviada
          await db.setFieldTableBatchProducts(
            event.product.batchId ?? 0,
            event.product.idProduct ?? 0,
            'is_send_odoo',
            1,
            event.product.idMove ?? 0,
            'pick',
          );

//actualizamos la lista de productos

          add(FetchPickWithProductsEvent(pickWithProducts.pick?.id ?? 0));
          emit(SendProductPickOdooSuccess());
          return;
        }

        // Elementos que no se pudieron enviar a Odoo
        await db.setFieldTableBatchProducts(
          event.product.batchId ?? 0,
          event.product.idProduct ?? 0,
          'is_send_odoo',
          0,
          event.product.idMove ?? 0,
          'pick',
        );

        DateTime fechaTransaccion = DateTime.now();
        String fechaFormateada = formatoFecha(fechaTransaccion);

        emit(SendProductPickOdooError(
          response.result?.msg ?? 'Error al enviar el producto',
          // TransferRequest(
          //   idTransferencia: currentProduct.batchId ?? 0,
          //   listItems: [
          //     ListItem(
          //       idMove: event.product.idMove ?? 0,
          //       idProducto: event.product.idProduct ?? 0,
          //       idLote: event.product.loteId ?? 0,
          //       idUbicacionDestino: event.product.muelleId ?? 0,
          //       cantidadEnviada: event.product.quantitySeparate ?? 0,
          //       idOperario: userid,
          //       timeLine: event.product.timeSeparate == null
          //           ? 30.0
          //           : event.product.timeSeparate.toDouble(),
          //       fechaTransaccion: event.product.fechaTransaccion == "" ||
          //               event.product.fechaTransaccion == null
          //           ? fechaFormateada
          //           : event.product.fechaTransaccion ?? "",
          //       observacion: event.product.observation ?? 'Sin novedad',
          //       dividida: false,
          //     ),
          //   ],
          // ),
        ));
      }
    } catch (e, s) {
      DateTime fechaTransaccion = DateTime.now();
      String fechaFormateada = formatoFecha(fechaTransaccion);
      emit(SendProductPickOdooError(
        s.toString(),
        // TransferRequest(
        //   idTransferencia: currentProduct.batchId ?? 0,
        //   listItems: [
        //     ListItem(
        //       idMove: event.product.idMove ?? 0,
        //       idProducto: event.product.idProduct ?? 0,
        //       idLote: event.product.loteId ?? 0,
        //       idUbicacionDestino: event.product.muelleId ?? 0,
        //       cantidadEnviada: event.product.quantitySeparate ?? 0,
        //       idOperario: userid,
        //       timeLine: event.product.timeSeparate == null
        //           ? 30.0
        //           : event.product.timeSeparate.toDouble(),
        //       fechaTransaccion: event.product.fechaTransaccion == "" ||
        //               event.product.fechaTransaccion == null
        //           ? fechaFormateada
        //           : event.product.fechaTransaccion ?? "",
        //       observacion: event.product.observation ?? 'Sin novedad',
        //       dividida: false,
        //     ),
        //   ],
        // ),
      ));
      print("❌ Error en el SendProductOdooEvent: $e ->$s");
    } finally {
      _isProcessing =
          false; // Resetear la bandera una vez que el proceso termine
    }
  }

  void _onClearSearchEvent(ClearSearchProudctsPickEvent event,
      Emitter<PickingPickState> emit) async {
    try {
      searchController.clear();
      filteredProducts.clear();
      filteredProducts.addAll(pickWithProducts.products!);
      await sortProductsByLocationId();
      emit(LoadProductsPickSuccesState(listOfProductsBatch: filteredProducts));
    } catch (e, s) {
      print("❌ Error en el ClearSearchProudctsBatchEvent $e ->$s");
    }
  }

  void _onSearchBacthEvent(
      SearchProductsPickEvent event, Emitter<PickingPickState> emit) async {
    final query = event.query.toLowerCase();

    if (query.isEmpty) {
      filteredProducts.clear();
      filteredProducts = pickWithProducts
          .products!; // Si la búsqueda está vacía, mostrar todos los productos
      await sortProductsByLocationId();
    } else {
      filteredProducts = pickWithProducts.products!.where((batch) {
        final queryLower =
            query.toLowerCase(); // Normalizar el query una sola vez
        // Se normalizan todos los campos a buscar
        final productId = batch.productId?.toLowerCase() ?? '';
        final barcode = batch.barcode?.toLowerCase() ?? '';
        final productCode = batch.productCode?.toLowerCase() ?? '';
        final location = batch.locationId?.toLowerCase() ?? '';
        final origin = batch.origin?.toLowerCase() ??
            ''; // Se obtiene el valor del campo origin

        // 🔎 ¡Depura aquí!
        // Imprime el valor de origin para verificar su contenido
        print('🔎 Verificando producto con origen: "$origin"');
        print('🔎 El filtro busca: "$queryLower"');

        // Realizar la búsqueda usando el operador OR
        return productId.contains(queryLower) ||
            barcode.contains(queryLower) ||
            location.contains(queryLower) ||
            productCode.contains(queryLower) ||
            origin.contains(queryLower); // El filtro para origin
      }).toList();
    }
    emit(LoadProductsPickSuccesState(
        listOfProductsBatch: filteredProducts)); // Emitir la lista filtrada
  }

  //*evento para dejar pendiente la separacion
  void _onPickingPendingEvent(
      ProductPendingEvent event, Emitter<PickingPickState> emit) async {
    try {
      emit(ProductPendingLoading());
      if (filteredProducts.isEmpty) {
        return;
      }
      //cambiamos el estado del producto a pendiente
      await db.pickProductsRepository.setFieldTablePickProducts(
          pickWithProducts.pick?.id ?? 0,
          event.product.idProduct ?? 0,
          'is_pending',
          1,
          event.product.idMove ?? 0);

      //deseleccionamos el producto actual
      if (event.product.productIsOk == 1) {
        await db.pickProductsRepository.setFieldTablePickProducts(
            pickWithProducts.pick?.id ?? 0,
            event.product.idProduct ?? 0,
            'product_is_ok',
            0,
            event.product.idMove ?? 0);
      }

      //marcamos el producto con la ubicacion no leida
      await db.pickProductsRepository.setFieldTablePickProducts(
          pickWithProducts.pick?.id ?? 0,
          event.product.idProduct ?? 0,
          'is_location_is_ok',
          0,
          event.product.idMove ?? 0);

      //marcamos el producto como no leido
      await db.pickProductsRepository.setFieldTablePickProducts(
          pickWithProducts.pick?.id ?? 0,
          event.product.idProduct ?? 0,
          'is_quantity_is_ok',
          0,
          event.product.idMove ?? 0);
      //product_is_ok
      await db.pickProductsRepository.setFieldTablePickProducts(
          pickWithProducts.pick?.id ?? 0,
          event.product.idProduct ?? 0,
          'product_is_ok',
          0,
          event.product.idMove ?? 0);

      //ordenamos los productos por ubicacion
      await sortProductsByLocationId();
      add(FetchPickWithProductsEvent(pickWithProducts.pick?.id ?? 0));
      emit(ProductPendingSuccess());
    } catch (e, s) {
      emit(ProductPendingError());
      print('❌ Error _onPickingPendingEvent: $e, $s');
    }
  }

  //*metodo pra cambiar la novedad
  void _onSelectNovedadEvent(
      SelectNovedadEvent event, Emitter<PickingPickState> emit) {
    try {
      selectedNovedad = event.novedad;
      emit(SelectNovedadStateSuccess(event.novedad));
    } catch (e, s) {
      emit(SelectNovedadStateError('Errror al seleccionar novedad'));
      print('❌ Error en el SelectNovedadEvent $e ->$s');
    }
  }

  //*evento para establecer un proceso en ejecucion
  void _onSetIsProcessingEvent(
      SetIsProcessingEvent event, Emitter<PickingPickState> emit) {
    try {
      isProcessing = event.isProcessing;
      emit(SetIsProcessingState(isProcessing));
    } catch (e, s) {
      print("❌ Error en _onSetIsProcessingEvent: $e, $s");
    }
  }

  void _onAssignSubmuelleEvent(
      AssignSubmuelleEvent event, Emitter<PickingPickState> emit) async {
    try {
      //realizamos la peticion para ocupar el muelle
      final responseMuele = await repositoryBatch.ocuparMuelle(
          idMuelle: event.muelle.id ?? 0, isFull: event.isOccupied);

      if (responseMuele.result?.code != 200) {
        emit(SubMuelleOcupadoError(responseMuele.result?.msg ?? ''));
        return;
      }

      // Primero, actualizamos la base de datos para todos los productos
      for (var product in event.productsSeparate) {
        await db.pickProductsRepository.setFieldTablePickProducts(
            product.batchId ?? 0,
            product.idProduct ?? 0,
            'is_muelle',
            1,
            product.idMove ?? 0);

        // Actualizamos el muelle del producto
        await db.pickProductsRepository.setFieldTablePickProducts(
            product.batchId ?? 0,
            product.idProduct ?? 0,
            'muelle_id',
            event.muelle.id ?? 0,
            product.idMove ?? 0);

        // Actualizamos el nombre del muelle del producto
        await db.pickProductsRepository.setFieldStringTablePickProducts(
            product.batchId ?? 0,
            product.idProduct ?? 0,
            'location_dest_id',
            event.muelle.completeName ?? '',
            product.idMove ?? 0);
        //Actualizamos el barcode del muelle del producto
        await db.pickProductsRepository.setFieldStringTablePickProducts(
            product.batchId ?? 0,
            product.idProduct ?? 0,
            'barcode_location_dest',
            event.muelle.barcode ?? '',
            product.idMove ?? 0);
      }

      // Después, enviamos la petición a Odoo con todos los productos en una sola vez
      List<ListItem> itemsToSend = [];
      for (var product in event.productsSeparate) {
        // Traemos el tiempo de inicio de separación del producto desde la base de datos
        final userid = await PrefUtils.getUserId();

        DateTime fechaTransaccion = DateTime.now();
        String fechaFormateada = formatoFecha(fechaTransaccion);

        // Creamos los Item a enviar
        itemsToSend.add(ListItem(
          idMove: product.idMove ?? 0,
          idProducto: product.idProduct ?? 0,
          idLote: product.loteId ?? 0,
          idUbicacionDestino: event.muelle.id ?? 0,
          cantidadEnviada: (product.quantitySeparate ?? 0) > (product.quantity)
              ? product.quantity
              : product.quantitySeparate ?? 0,
          idOperario: userid,
          timeLine: product.timeSeparate == null
              ? 30.0
              : product.timeSeparate.toDouble(),
          fechaTransaccion:
              product.fechaTransaccion == "" || product.fechaTransaccion == null
                  ? fechaFormateada
                  : product.fechaTransaccion ?? "",
          observacion: product.observation == ""
              ? 'Sin novedad'
              : product.observation ?? "",
          dividida: false,
        ));
      }
      final response = await repository.sendProductTransferPick(
        TransferRequest(
          idTransferencia: currentProduct.batchId ?? 0,
          listItems: itemsToSend,
        ),
        false,
      );
      if (response.result?.code == 200) {
        add(FetchPickWithProductsEvent(event.productsSeparate[0].batchId ?? 0));
        emit(SubMuelleEditSusses('Submuelle asignado correctamente'));
      } else {
        emit(SubMuelleEditFail('Error al asignar el submuelle'));
      }
    } catch (e, s) {
      emit(SubMuelleEditFail('Error al asignar el submuelle'));
      print("❌ Error en el AssignSubmuelleEvent :$s ->$s");
    }
  }

  //*evento para seleccionar un submuelle
  void _onSelectecSubMuelle(
      SelectedSubMuelleEvent event, Emitter<PickingPickState> emit) {
    try {
      subMuelleSelected = Muelles();
      subMuelleSelected = event.subMuelleSlected;
      emit(SelectSubMuelle(subMuelleSelected));
    } catch (e, s) {
      print("❌ Error bloc selectedSubMuelle $e -> $s");
    }
  }

  //*evento para ver la cantidad
  void _onShowQuantityEvent(
      ShowQuantityEvent event, Emitter<PickingPickState> emit) {
    try {
      viewQuantity = !viewQuantity;
      emit(ShowQuantityState(viewQuantity));
    } catch (e, s) {
      print("❌ Error en _onShowQuantityEvent: $e, $s");
    }
  }

  //*metodo para cambiar la cantidad seleccionada
  void _onChangeQuantitySelectedEvent(
      ChangeQuantitySeparate event, Emitter<PickingPickState> emit) async {
    try {
      if (event.quantity > 0) {
        quantitySelected = event.quantity;
        await db.pickProductsRepository.setFieldTablePickProducts(
            pickWithProducts.pick?.id ?? 0,
            event.productId,
            'quantity_separate',
            event.quantity,
            event.idMove);
      }
      emit(ChangeQuantitySeparateStateSuccess(quantitySelected));
    } catch (e, s) {
      emit(ChangeQuantitySeparateStateError('Error al separar cantidad'));
      print('❌ Error en ChangeQuantitySeparate: $e -> $s ');
    }
  }

  //*evento para aumentar la cantidad
  void _onAddQuantitySeparateEvent(
      AddQuantitySeparate event, Emitter<PickingPickState> emit) async {
    try {
      if (quantitySelected > (currentProduct.quantity ?? 0)) {
        return;
      } else {
        quantitySelected = quantitySelected + event.quantity;
        await db.pickProductsRepository.incremenQtyProductSeparate(
            pickWithProducts.pick?.id ?? 0,
            event.productId,
            event.idMove,
            event.quantity);
        emit(ChangeQuantitySeparateStateSuccess(quantitySelected));
      }
    } catch (e, s) {
      emit(ChangeQuantitySeparateStateError('Error al aumentar cantidad'));
      print("❌ Error en el AddQuantitySeparate $e ->$s");
    }
  }

  //*evento para actualizar el valor del scan
  void _onUpdateScannedValueEvent(
      UpdateScannedValueEvent event, Emitter<PickingPickState> emit) {
    try {
      print('scannedValue: ${event.scannedValue}');
      switch (event.scan) {
        case 'location':
          // Acumulador de valores escaneados
          scannedValue1 += event.scannedValue.trim();
          print('scannedValue1: $scannedValue1.');
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
        case 'muelle':
          print('scannedValue4: $scannedValue4');
          scannedValue4 += event.scannedValue.trim();
          emit(UpdateScannedValueState(scannedValue4, event.scan));
          break;

        case 'toDo':
          scannedValue5 += event.scannedValue.trim();
          print('scannedValue5: $scannedValue5');
          emit(UpdateScannedValueState(scannedValue5, event.scan));
          break;

        default:
          print('Scan type not recognized: ${event.scan}');
      }
    } catch (e, s) {
      print("❌ Error en _onUpdateScannedValueEvent: $e, $s");
    }
  }

  void _onValidateFields(
      ValidateFieldsEvent event, Emitter<PickingPickState> emit) {
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
      }
      emit(ValidateFieldsStateSuccess(event.isOk));
    } catch (e, s) {
      emit(ValidateFieldsStateError('Error al validar campos'));
      print("❌ Error en el ValidateFieldsEvent $e ->$s");
    }
  }

  void _onClearScannedValueEvent(
      ClearScannedValueEvent event, Emitter<PickingPickState> emit) {
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
        case 'muelle':
          scannedValue4 = '';
          emit(ClearScannedValueState());
          break;
        case 'toDo':
          scannedValue5 = '';
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

  //*metodo para cambiar el producto actual

  void _onChangeCurrentProduct(
      ChangeCurrentProduct event, Emitter<PickingPickState> emit) async {
    try {
      viewQuantity = false;
      emit(CurrentProductChangedStateLoading());

      // --- 1. Lógica de Marcado del Producto Actual (Pre-Envío) ---
      // Estas acciones se ejecutan sin importar si Odoo tiene éxito, ya que son locales.
      await db.pickProductsRepository.setFieldTablePickProducts(
          pickWithProducts.pick?.id ?? 0,
          event.currentProduct.idProduct ?? 0,
          'is_selected',
          0,
          currentProduct.idMove ?? 0);

      // Cálculo de tiempo (Tu lógica original de cálculo de diferencia)
      DateTime dateTimeActuality = DateTime.parse(DateTime.now().toString());
      await db.pickProductsRepository.endStopwatchProduct(
          pickWithProducts.pick?.id ?? 0,
          dateTimeActuality.toString(),
          currentProduct.idProduct ?? 0,
          currentProduct.idMove ?? 0);

      final starTimeProduct = await db.pickProductsRepository
          .getFieldTableProductsPick(
              currentProduct.batchId ?? 0,
              currentProduct.idProduct ?? 0,
              currentProduct.idMove ?? 0,
              "time_separate_start");

      DateTime dateTimeStartProduct =
          starTimeProduct == "null" || starTimeProduct.isEmpty
              ? DateTime.parse(DateTime.now().toString())
              : DateTime.parse(starTimeProduct);

      Duration differenceProduct =
          dateTimeActuality.difference(dateTimeStartProduct);
      double secondsDifferenceProduct =
          differenceProduct.inMilliseconds / 1000.0;

      await db.pickProductsRepository.totalStopwatchProduct(
          pickWithProducts.pick?.id ?? 0,
          currentProduct.idProduct ?? 0,
          currentProduct.idMove ?? 0,
          secondsDifferenceProduct);

      // --- 2. PUNTO DE CONTROL CRÍTICO: Envío a Odoo ---
      // El 'await' aquí garantiza que el código ESPERA la respuesta antes de continuar.
      final response = await sendProuctOdoo();

      if (response.success == false) {
        // Si el envío falla (response.success es false, gracias a tu función SendResult),
        // EMITIMOS EL ERROR y SALIMOS DE LA FUNCIÓN. El currentProduct NO se actualiza.
        emit(SendProductPickOdooError(
            response.message)); // Usamos el mensaje de error de la respuesta
        return;
      }

      // --- 3. Procesar el Siguiente Producto (Solo si el Envío a Odoo fue Éxito) ---

      // La lista filtrada se debe re-evaluar o re-obtener si es necesario.
      // Asumo que 'filteredProducts' está disponible y actualizado.
      final nextProducts =
          filteredProducts.where((product) => product.isSeparate == 0).toList();

      if (nextProducts.isNotEmpty) {
        // Restablecemos los estados de la UI para el nuevo producto
        productIsOk = false;
        quantityIsOk = false;

        // Seleccionamos el siguiente producto de la lista
        currentProduct = nextProducts.first;

        // Lógica de ubicación
        if (currentProduct.locationId == oldLocation) {
          locationIsOk = true;
        } else {
          locationIsOk = false;
        }

        // Iniciamos el cronómetro del nuevo producto
        await db.pickProductsRepository.startStopwatch(
          pickWithProducts.pick?.id ?? 0,
          currentProduct.idProduct ?? 0,
          currentProduct.idMove ?? 0,
          DateTime.now().toString(),
        );
      } else {
        // No hay más productos pendientes. Podemos limpiar el currentProduct o dejar el estado de "terminado".
        print('✅ Todos los productos han sido separados.');
      }

      // --- 4. Emisión del Estado Final y Actualización de Lista ---

      emit(CurrentProductChangedState(
        currentProduct: currentProduct,
      ));

      // Forzar la actualización de la lista de productos
      add(FetchPickWithProductsEvent(pickWithProducts.pick?.id ?? 0));

      return;
    } catch (e, s) {
      // Manejo de cualquier excepción inesperada (conexión, base de datos)
      emit(CurrentProductChangedStateError(
          'Error crítico al procesar el cambio de producto.'));
      print("❌ Error en el ChangeCurrentProduct $e ->$s");
    }
  }

  //*metodo para enviar al wms
  Future<SendResult> sendProuctOdoo() async {
    try {
      DateTime dateTimeActuality = DateTime.parse(DateTime.now().toString());
      //traemos un producto de la base de datos  ya anteriormente guardado
      final product = await db.pickProductsRepository.getProductPick(
          pickWithProducts.pick?.id ?? 0,
          currentProduct.idProduct ?? 0,
          currentProduct.idMove ?? 0);

      double secondsDifference = 0.0;
// Verificación si la fecha de inicio es nula o vacía
      // Si `startTime` tiene un valor, continúa con el cálculo
      try {
        // Calcular la diferencia entre la fecha actual y la fecha de inicio
        Duration difference = dateTimeActuality.difference(DateTime.now());
        // Obtener la diferencia en segundos
        secondsDifference = difference.inMilliseconds / 1000.0;
        print("Diferencia en segundos: $secondsDifference");
      } catch (e) {
        // Si ocurre algún error durante el parseo (por ejemplo, formato incorrecto)
        print("❌ Error al parsear la fecha: $e");
      }

      final userid = await PrefUtils.getUserId();

      //enviamos el producto a odoo

      DateTime fechaTransaccion = DateTime.now();
      String fechaFormateada = formatoFecha(fechaTransaccion);

      final response = await repository.sendProductTransferPick(
        TransferRequest(
          idTransferencia: currentProduct.batchId ?? 0,
          listItems: [
            ListItem(
              idMove: product?.idMove ?? 0,
              idProducto: product?.idProduct ?? 0,
              idLote: product?.loteId ?? 0,
              idUbicacionDestino: product?.muelleId ?? 0,

              cantidadEnviada: (product?.quantitySeparate ?? 0.0) >
                      (product?.quantity ??
                          0.0) // Asegura que ambos lados sean numéricos
                  ? (product?.quantity ??
                      0.0) // Si es verdadero, usa quantity, pero también con ?? 0.0
                  : (product?.quantitySeparate ??
                      0.0), // Si es falso, usa quantitySeparate
              idOperario: userid,
              timeLine: product?.timeSeparate == null
                  ? 30.0
                  : product?.timeSeparate.toDouble(),
              fechaTransaccion: product?.fechaTransaccion == "" ||
                      product?.fechaTransaccion == null
                  ? fechaFormateada
                  : product?.fechaTransaccion ?? "",
              observacion: product?.observation == ""
                  ? 'Sin novedad'
                  : product?.observation ?? "",
              dividida: false,
            ),
          ],
        ),
        false,
      );

      if (response.result?.code == 200) {
        //recorremos todos los resultados de la respuesta
        for (var resultProduct in response.result!.result!) {
          await db.pickProductsRepository.setFieldTablePickProducts(
            resultProduct.idTransferencia ?? 0,
            resultProduct.idProduct ?? 0,
            'is_send_odoo',
            1,
            resultProduct.idMove ?? 0,
          );
        }
        return SendResult(
            success: true, message: 'Producto enviado exitosamente');
      } else {
        quantityIsOk = true;
        //elementos que no se pudieron enviar a odoo
        await db.pickProductsRepository.setFieldTablePickProducts(
          product?.batchId ?? 0,
          product?.idProduct ?? 0,
          'is_send_odoo',
          0,
          product?.idMove ?? 0,
        );
        return SendResult(
            success: false,
            message: response.result?.msg ?? 'Error al enviar el producto');
      }
    } catch (e, s) {
      print("❌ Error en el sendProuctOdoo $e ->$s ");
      return SendResult(success: false, message: 'Error inesperado: $e');
    }
  }

  //*metodo para validar la cantidad del producto
  void _onChangeQuantityIsOkEvent(
      ChangeIsOkQuantity event, Emitter<PickingPickState> emit) async {
    try {
      if (event.isOk) {
        await db.pickProductsRepository.setFieldTablePickProducts(event.batchId,
            event.productId, 'is_quantity_is_ok', 1, event.idMove);
      }
      quantityIsOk = event.isOk;
      emit(ChangeQuantityIsOkState(
        quantityIsOk,
      ));
    } catch (e, s) {
      print("❌ Error en el ChangeIsOkQuantity $e ->$s");
    }
  }

  //*metodo para validar la ubicacion de origen

  void _onChangeLocationIsOkEvent(
      ChangeLocationIsOkEvent event, Emitter<PickingPickState> emit) async {
    try {
      if (isLocationOk) {
        await db.pickProductsRepository.setFieldTablePickProducts(
          event.batchId,
          event.productId,
          'is_location_is_ok',
          1,
          event.idMove,
        );
        // cuando se lea la ubicacion se selecciona el batch
        await db.pickRepository
            .setFieldTablePick(event.batchId, 'is_selected', 1);
        locationIsOk = true;
        emit(ChangeLocationIsOkState(
          locationIsOk,
        ));
      }
    } catch (e, s) {
      print("❌ Error en el ChangeLocationIsOkEvent $e ->$s");
    }
  }

  //*metodo para validar la ubicacion de destino
  void _onChangeLocationDestIsOkEvent(
      ChangeLocationDestIsOkEvent event, Emitter<PickingPickState> emit) async {
    try {
      if (event.locationDestIsOk) {
        await db.pickProductsRepository.setFieldTablePickProducts(event.batchId,
            event.productId, 'location_dest_is_ok', 1, event.idMove);
      }
      locationDestIsOk = event.locationDestIsOk;
      emit(ChangeLocationDestIsOkState(
        locationDestIsOk,
      ));
    } catch (e, s) {
      print("❌ Error en el ChangeLocationDestIsOkEvent $e ->$s");
    }
  }

  //*metodo para validar el producto

  void _onChangeProductIsOkEvent(
      ChangeProductIsOkEvent event, Emitter<PickingPickState> emit) async {
    try {
      if (event.productIsOk) {
        //empezamos el tiempo de separacion del batch y del producto
        await db.pickProductsRepository.startStopwatch(
          event.batchId,
          event.productId,
          event.idMove,
          DateTime.now().toString(),
        );

        //calculamos la fecha de transaccion
        DateTime fechaTransaccion = DateTime.now();
        String fechaFormateada = formatoFecha(fechaTransaccion);
        //agregamos la fecha de transaccion
        await db.pickProductsRepository.dateTransaccionProduct(
          event.batchId,
          fechaFormateada,
          event.productId,
          event.idMove,
        );

        await db.pickProductsRepository.setFieldTablePickProducts(event.batchId,
            event.productId, 'is_quantity_is_ok', 1, event.idMove);
        quantityIsOk = event.productIsOk;

        await db.pickProductsRepository.setFieldTablePickProducts(
            event.batchId, event.productId, 'is_selected', 1, event.idMove);
        await db.pickProductsRepository.setFieldTablePickProducts(
            event.batchId, event.productId, 'product_is_ok', 1, event.idMove);
      }
      productIsOk = event.productIsOk;
      emit(ChangeProductIsOkState(
        productIsOk,
      ));
    } catch (e, s) {
      print("❌ Error en el ChangeProductIsOkEvent $e ->$s");
    }
  }

  //*metodo para mostrar el teclado
  void _onShowKeyboardEvent(
      ShowKeyboard event, Emitter<PickingPickState> emit) {
    try {
      isKeyboardVisible = event.showKeyboard;
      emit(ShowKeyboardState(showKeyboard: isKeyboardVisible));
    } catch (e, s) {
      print("❌ Error en _onShowKeyboardEvent: $e, $s");
    }
  }

  //* metodo para cargar la configuracion del usuario
  void _onLoadConfigurationsUserEvent(
      LoadConfigurationsUser event, Emitter<PickingPickState> emit) async {
    try {
      emit(ConfigurationLoading());
      int userId = await PrefUtils.getUserId();
      final response =
          await db.configurationsRepository.getConfiguration(userId);

      if (response != null) {
        emit(ConfigurationPickingLoaded(response));
        configurations = response;
      } else {
        emit(ConfigurationError('Error al cargar LoadConfigurationsUser'));
      }
    } catch (e, s) {
      print('❌ Error en LoadConfigurationsUser $e =>$s');
    }
  }

//* metodo para cargar las variables de la vista dependiendo del estado de los productos y del batch
  void _onLoadDataInfoEvent(
      LoadDataInfoEvent event, Emitter<PickingPickState> emit) {
    try {
      emit(LoadDataInfoLoading());

      // 🔍 Filtrar productos con isSeparate == 0
      final separatedProducts =
          filteredProducts.where((p) => p.isSeparate == 0).toList();

      if (separatedProducts.length != 0) {
        currentProduct = separatedProducts.first;
        if (currentProduct.locationId == oldLocation) {
          locationIsOk = true;
        } else {
          locationIsOk = currentProduct.isLocationIsOk == 1 ? true : false;
        }
        productIsOk = currentProduct.productIsOk == false
            ? false
            : currentProduct.productIsOk == 1
                ? true
                : false;
        locationDestIsOk = currentProduct.locationDestIsOk == 1 ? true : false;
        quantityIsOk = currentProduct.isQuantityIsOk == 1 ? true : false;
        index = pickWithProducts.pick?.indexList ?? 0;
        quantitySelected = currentProduct.quantitySeparate ?? 0;
        _isProcessing = false;
      }

      emit(LoadDataInfoSuccess());
    } catch (e, s) {
      emit(LoadDataInfoError("Error al cargar las variables de estado"));
      print("❌ Error en  LoadDataInfoEvent $e ->$s");
    }
  }

  //*evento para obtener los barcodes de un producto por paquete
  void _onFetchBarcodesProductEvent(
      FetchBarcodesProductEvent event, Emitter<PickingPickState> emit) async {
    try {
      listOfBarcodes.clear();

      listOfBarcodes = await db.barcodesPackagesRepository.getBarcodesProduct(
        pickWithProducts.pick?.id ?? 0,
        currentProduct.idProduct ?? 0,
        currentProduct.idMove ?? 0,
        "pick",
      );
      //mostrmaos los datos del producto
      print(
          "Producto ID: ${currentProduct.idProduct}, Move ID: ${currentProduct.idMove}, pick ID: ${pickWithProducts.pick?.id}");
      print("listOfBarcodes: ${listOfBarcodes.length}");
      emit(BarcodesProductLoadedState(listOfBarcodes: listOfBarcodes));
    } catch (e, s) {
      print("❌ Error en _onFetchBarcodesProductEvent: $e, $s");
    }
  }

  void _onFetchPickWithProductsEvent(
      FetchPickWithProductsEvent event, Emitter<PickingPickState> emit) async {
    try {
      print('Fetching pick with ID: ${event.pickId}');
      pickWithProducts = PickWithProducts();

      final response =
          await db.pickProductsRepository.getPickWithProducts(event.pickId);

      if (response != null) {
        pickWithProducts = response;

        if (pickWithProducts.products!.isEmpty) {
          print('No hay productos en el batch');
          emit(EmptyProductsPick());
          return;
        }

        listProducts.clear();
        listProducts.addAll(pickWithProducts.products!);

        filteredProducts.clear();
        filteredProducts.addAll(pickWithProducts.products!);

        await sortProductsByLocationId();

        add(LoadDataInfoEvent());
        getPosicions();
        products();

        add(FetchBarcodesProductEvent());

        emit(LoadProductsBatchSuccesStateBD(
            listOfProductsBatch: filteredProducts));
      } else {
        pickWithProducts = PickWithProducts();
        emit(EmptyProductsPick());
        print('No se encontró el batch con ID: ${event.pickId}');
      }
    } catch (e, s) {
      print("❌ Error en el FetchBatchWithProductsEvent $e ->$s");
    }
  }

  void products() {
    try {
      // Usamos un Set para evitar duplicados y mejorar el rendimiento de búsqueda
      Set<String> productIdsSet = {};
      // Recorremos los productos del batch
      for (var product in filteredProducts) {
        // Validamos que el productId no sea nulo y lo convertimos a String
        if (product.productId != null) {
          productIdsSet.add(product.productId.toString());
        }
      }
      // Asignamos el Set a la lista, si es necesario
      listOfProductsName = productIdsSet.toList();
    } catch (e, s) {
      print("❌ Error en el products $e ->$s");
    }
  }

  void getPosicions() {
    try {
      // Usar un Set para evitar duplicados automáticamente
      Set<String> positionsSet = {};
      // Usamos un filtro para no tener que comprobar locationId en cada iteración
      for (var product in filteredProducts) {
        // Solo añadimos locationId si no es nulo ni vacío
        String locationId = product.locationId ?? '';
        if (locationId.isNotEmpty) {
          positionsSet.add(locationId);
        }
      }

      // Convertimos el Set a lista si es necesario
      positionsOrigen = positionsSet.toList();
    } catch (e, s) {
      print("❌ Error en getPosicions: $e -> $s");
    }
  }

  //*metodo para ordenar los productos por ubicacion
  Future<List<ProductsBatch>> sortProductsByLocationId() async {
    try {
      final products = filteredProducts;
      final batch = pickWithProducts.pick;

      //traemos el batch actualizado
      final batchUpdated = await db.pickRepository.getPickById(batch?.id ?? 0);

      //ORDENAMOS LOS PRODUCTOS SEGUN EL ORDENAMIENTO QUE DIGA EL BATCH
      switch (batchUpdated?.orderBy) {
        case "removal_priority":
          {
            if (batchUpdated?.orderPicking == "asc") {
              products.sort((a, b) {
                return a.rimovalPriority!.compareTo(b.rimovalPriority!);
              });
            } else {
              products.sort((a, b) {
                return b.rimovalPriority!.compareTo(a.rimovalPriority!);
              });
            }
          }
          break;
        case "location_name":
          {
            if (batchUpdated?.orderPicking == "asc") {
              products.sort((a, b) {
                return a.locationId!.compareTo(b.locationId!);
              });
            } else {
              products.sort((a, b) {
                return b.locationId!.compareTo(a.locationId!);
              });
            }
          }
          break;
        case "product_name":
          {
            if (batchUpdated?.orderPicking == "asc") {
              products.sort((a, b) {
                return a.productId!.compareTo(b.productId!);
              });
            } else {
              products.sort((a, b) {
                return b.productId!.compareTo(a.productId!);
              });
            }
          }
          break;
      }

      // Filtrar los productos con isPending == 1
      List<ProductsBatch> pendingProducts =
          products.where((product) => product.isPending == 1).toList();

      // Filtrar los productos que no están pendientes
      List<ProductsBatch> nonPendingProducts =
          products.where((product) => product.isPending != 1).toList();

      // Concatenar los productos no pendientes con los productos pendientes al final
      filteredProducts.clear();
      filteredProducts.addAll(nonPendingProducts);
      filteredProducts.addAll(pendingProducts);

      return filteredProducts;
    } catch (e, s) {
      print("❌ Error en el sortProductsByLocationId $e ->$s");
      return [];
    }
  }

//*evento para obtener todas las novedades
  void _onLoadAllNovedadesEvent(
      LoadAllNovedadesPickEvent event, Emitter<PickingPickState> emit) async {
    try {
      final response = await db.novedadesRepository.getAllNovedades();
      novedades.clear();
      if (response != null) {
        novedades = response;
        print("novedades: ${novedades.length}");
      }
      emit(NovedadesLoadedState(listOfNovedades: novedades));
    } catch (e, s) {
      print("❌ Error en __onLoadAllNovedadesEvent: $e, $s");
    }
  }

  void _onFetchPickingPickFromDBEvent(
      FetchPickingPickFromDBEvent event, Emitter<PickingPickState> emit) async {
    emit(PickingPickBDLoading());
    try {
      // Aquí llamas a tu repositorio para obtener los datos
      final result = await db.pickRepository.getAllPickingPicks(
        'pick',
      );
      listOfPick.clear();
      listOfPickFiltered.clear();

      if (result.isNotEmpty) {
        listOfPick = result;
        listOfPickFiltered = result;

        emit(PickingPickLoadedBD(listOfPickFiltered));
        return;
      }
      emit(PickingPickLoadedBD([]));
    } catch (e) {
      emit(PickingPickError(e.toString()));
    }
  }

  void _onFetchPickingPickEvent(
      FetchPickingPickEvent event, Emitter<PickingPickState> emit) async {
    emit(PickingPickLoading());
    try {
      await DataBaseSqlite().delePick('pick');
      oldLocation = '';

      // Aquí llamas a tu repositorio para obtener los datos
      final result = await pickingPickRepository.resPicks(event.isLoadinDialog);

      //validacion de la version de la app
      if ((result.updateVersion ?? false) == true) {
        emit(NeedUpdateVersionState());
      }

      if (result.result?.isNotEmpty == true) {
        await db.pickRepository.insertAllPickingPicks(result.result!, 'pick');
        // Convertir el mapa en una lista de productos únicos con cantidades sumadas
        final productsIterable =
            _extractAllProducts(result.result!).toList(growable: false);

        final sentProductsIterable =
            _getAllSentProducts(result.result!).toList(growable: false);

        final allBarcodes =
            _extractAllBarcodes(result.result!).toList(growable: false);

        print('productsToInsert: ${productsIterable.length}');
        print('sentProductsIterable: ${sentProductsIterable.length}');
        print('allBarcodes: ${allBarcodes.length}');

        // Enviar la lista agrupada a insertBatchProducts
        await db.pickProductsRepository
            .insertPickProducts(productsIterable, 'pick');

        await db.pickProductsRepository
            .insertPickProducts(sentProductsIterable, 'pick');

        if (allBarcodes.isNotEmpty) {
          // Enviar la lista agrupada a insertBarcodesPackageProduct
          await DataBaseSqlite()
              .barcodesPackagesRepository
              .insertOrUpdateBarcodes(
                allBarcodes,
                'pick',
              );
        }

        add(FetchPickingPickFromDBEvent(true));
        emit(PickingPickLoaded(result.result ?? []));
        return;
      } else {
        listOfPick = [];
        listOfPickFiltered = [];
        emit(PickingPickLoaded(result.result ?? []));
      }
    } catch (e) {
      emit(PickingPickError(e.toString()));
    }
  }

  void getMuelles() {
    try {
      muelles.clear();
      if (pickWithProducts.pick?.muelle?.isNotEmpty == true) {
        muelles.add(pickWithProducts.pick?.muelle ?? '');
      }
    } catch (e, s) {
      print("❌ Error en el getMuelles $e ->$s");
    }
  }

  Iterable<ProductsBatch> _extractAllProducts(List<ResultPick> batches) sync* {
    for (final batch in batches) {
      if (batch.lineasTransferencia != null) {
        yield* batch.lineasTransferencia!;
      }
    }
  }

  Iterable<ProductsBatch> _getAllSentProducts(List<ResultPick> batches) sync* {
    for (final batch in batches) {
      if (batch.lineasTransferenciaEnviadas != null) {
        yield* batch.lineasTransferenciaEnviadas!;
      }
    }
  }

  Iterable<Barcodes> _extractAllBarcodes(List<ResultPick> batches) sync* {
    for (final batch in batches) {
      if (batch.lineasTransferencia == null) continue;

      for (final product in batch.lineasTransferencia!) {
        if (product.productPacking != null) {
          yield* product.productPacking!;
        }
        if (product.otherBarcode != null) {
          yield* product.otherBarcode!;
        }
      }
    }
  }

  String formatSecondsToHHMMSS(double secondsDecimal) {
    try {
      // Redondear a los segundos más cercanos
      int totalSeconds = secondsDecimal.round();

      // Calcular horas, minutos y segundos
      int hours = totalSeconds ~/ 3600;
      int minutes = (totalSeconds % 3600) ~/ 60;
      int seconds = totalSeconds % 60;

      // Formatear en 00:00:00
      String formattedTime = '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';

      return formattedTime;
    } catch (e, s) {
      print("❌ Error en el formatSecondsToHHMMSS $e ->$s");
      return "";
    }
  }

  String calcularUnidadesSeparadas() {
    try {
      if (pickWithProducts.products == null ||
          pickWithProducts.products!.isEmpty) {
        return "0.0";
      }
      dynamic totalSeparadas = 0;
      dynamic totalCantidades = 0;
      for (var product in pickWithProducts.products!) {
        totalSeparadas += product.quantitySeparate ?? 0;
        totalCantidades += (product.quantity) ?? 0; // Aseguramos que sea int
      }
      // Evitar división por cero
      if (totalCantidades == 0) {
        return "0.0";
      }
      final progress = (totalSeparadas / totalCantidades) * 100;
      return progress.toStringAsFixed(2);
    } catch (e, s) {
      print("❌ Error en el calcularUnidadesSeparadas $e ->$s");
      return '';
    }
  }
}

class SendResult {
  final bool success;
  final String message;
  SendResult({required this.success, required this.message});

  factory SendResult.fromJson(Map<String, dynamic> json) {
    return SendResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
    };
  }
}
