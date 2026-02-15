// ignore_for_file: collection_methods_unrelated_type

import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/features/user/data/models/user_configuration_model.dart';
import 'package:wms_app/src/core/utils/formats_utils.dart';
import 'package:wms_app/src/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/src/presentation/models/novedades_response_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/inventario/data/inventario_repository.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_image_send_novedad_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_temp_ia_model.dart';
import 'package:wms_app/src/presentation/views/wms_packing/data/wms_packing_repository.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/lista_product_packing.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/packing_response_model.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/response_packing_pedido_model.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/sen_pack_request.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/un_pack_request.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';

part 'packing_pedido_event.dart';
part 'packing_pedido_state.dart';

class PackingPedidoBloc extends Bloc<PackingPedidoEvent, PackingPedidoState> {
  //*variables para validar
  bool locationIsOk = false;
  bool productIsOk = false;
  bool locationDestIsOk = false;
  bool quantityIsOk = false;
  bool isKeyboardVisible = false;
  bool viewQuantity = false;

  //*isSticker
  bool isSticker = false;
  // //*validaciones de campos del estado de la vista
  bool isLocationOk = true;
  bool isProductOk = true;
  bool isLocationDestOk = true;
  bool isQuantityOk = true;

  String scannedValue1 = '';
  String scannedValue2 = '';
  String scannedValue3 = '';
  String scannedValue4 = '';
  String scannedValue5 = '';
  //* ultima ubicacion
  String oldLocation = '';
  double quantitySelected = 0;

  TemperatureIa resultTemperature = TemperatureIa();

  //*controller para la busqueda
  TextEditingController searchController = TextEditingController();
  TextEditingController searchControllerPedido = TextEditingController();
  TextEditingController searchControllerProduct = TextEditingController();
  TextEditingController controllerTemperature = TextEditingController();
  TextEditingController temperatureController = TextEditingController();

  //lista de pedidos
  List<PedidoPackingResult> listOfPedidos = [];
  List<PedidoPackingResult> listOfPedidosBD = [];
  List<PedidoPackingResult> listOfPedidosFilters = [];

  //*lista de productos de un pedido
  List<ProductoPedido> listOfProductos = []; //lista de productos de un pedido
  List<ProductoPedido> listOfProductosProgress =
      []; //lista de productos sin certificar
  List<ProductoPedido> productsDone = []; //lista de productos ya certificados
  List<ProductoPedido> productsDonePacking =
      []; //lista de productos ya certificados
  List<ProductoPedido> listOfProductsForPacking =
      []; //lista de productos sin certificar seleccionados para empacar

  bool viewDetail = true;

  //*lista de todas las pocisiones de los productos del batchs
  List<String> positions = [];

  //*lista de paquetes
  List<Paquete> packages = [];
  //*lista de barcodes
  List<Barcodes> listOfBarcodes = [];
  List<Barcodes> listAllOfBarcodes = [];
  List<ProductoPedido> listOfProductsName = [];

  PedidoPackingResult currentPedidoPack = PedidoPackingResult();

  //*producto actual
  ProductoPedido currentProduct = ProductoPedido();

  //configuracion del usuario //permisos
  UserConfigurationModel configurations = UserConfigurationModel();
  String currentFilterKey = 'priority_high';
  //*lista de novedades
  List<Novedad> novedades = [];

//*base de datos
  DataBaseSqlite db = DataBaseSqlite();
  //*repositorio
  WmsPackingRepository wmsPackingRepository = WmsPackingRepository();
  //repositorio de inventario
  InventarioRepository inventarioRepository = InventarioRepository();
  PackingPedidoBloc() : super(PackingPedidoInitial()) {
    on<PackingPedidoEvent>((event, emit) {});
    //evento para mostrar el teclado
    on<ShowKeyboardEvent>(_onShowKeyboardEvent);
    //*obtener todos los pedidos para packing de odoo
    on<LoadAllPackingPedidoEvent>(_onLoadAllPackingEvent);
    //*cargar los pedidos de packing desde la base de datos
    on<LoadPackingPedidoFromDBEvent>(_onLoadPackingPedidoFromDBEvent);

    //*buscar un pedido
    on<SearchPedidoEvent>(_onSearchPedidoEvent);
    //*asignar un usuario a una orden de compra
    on<AssignUserToPedido>(_onAssignUserToPedido);
    //* evento para empezar o terminar el tiempo
    on<StartOrStopTimePedido>(_onStartOrStopTimePedido);

    //*evento para obtener la configuracion del usuario
    on<LoadConfigurationsUser>(_onLoadConfigurationsUserEvent);

    //cargar pedido y productos
    on<LoadPedidoAndProductsEvent>(_onLoadPedidoAndProductsEvent);
    on<ShowDetailvent>(_onShowDetailEvent);

    //*evento para validar los campos de la vista
    on<ValidateFieldsPackingEvent>(_onValidateFieldsPacking);

    //*cambiar el estado de las variables
    on<ChangeLocationIsOkEvent>(_onChangeLocationIsOkEvent);
    on<ChangeLocationDestIsOkEvent>(_onChangeLocationDestIsOkEvent);
    on<ChangeProductIsOkEvent>(_onChangeProductIsOkEvent);

    //*evento para actualizar el valor del scan
    on<UpdateScannedValuePackEvent>(_onUpdateScannedValueEvent);
    on<ClearScannedValuePackEvent>(_onClearScannedValueEvent);

    //*evento para cambiar la cantidad seleccionada
    on<ChangeQuantitySeparate>(_onChangeQuantitySelectedEvent);

    //*cantidad
    on<ChangeIsOkQuantity>(_onChangeQuantityIsOkEvent);
    on<AddQuantitySeparate>(_onAddQuantitySeparateEvent);

    //*cargamos el producto a certificar
    on<FetchProductEvent>(_onFetchProductEvent);

    //enviar temperatura
    on<GetTemperatureEvent>(_onGetTemperatureEvent);
    on<SendImageNovedad>(_onSendImageNovedad);
    on<SendTemperatureEvent>(_onSendTemperatureEvent);
    on<SendTemperatureManualPackEvent>(_onSendTemperatureManualEvent);

    //*evento para obtener las novedades
    on<LoadAllNovedadesPackEvent>(_onLoadAllNovedadesEvent);
    add(LoadAllNovedadesPackEvent());

    //*metodo para dividir el producto en varios paquetes
    on<SetPickingSplitEvent>(_onSetPickingsSplitEvent);

    //*Picking
    on<SetPickingsEvent>(_onSetPickingsEvent);

    //*evento para ver la cantidad
    on<ShowQuantityPackEvent>(_onShowQuantityEvent);

    //*confirmar el sticker
    on<ChangeStickerEvent>(_onChangeStickerEvent);

    //*packing
    on<SetPackingsEvent>(_onSetPackingsEvent);

    //*evento para seleccionar productos sin certificar
    on<SelectProductPackingEvent>(_onSelectProductPackingEvent);
    //*evento para desseleccionar productos sin certificar
    on<UnSelectProductPackingEvent>(_onUnSelectProductPackingEvent);

    //*metodo para desempacar productos
    on<UnPackingEvent>(_onUnPackingEvent);

    //*metodo para empezar o terminar timepo
    on<StartOrStopTimePack>(_onStartOrStopTimeOrder);

    //*metodo para crear barckorder o no
    on<CreateBackPackOrNot>(_onCreateBackOrder);

    //*metodo para validar la confirmacion
    on<ValidateConfirmEvent>(_onValidateConfirmEvent);

    //evento para eliminar un producto del paquete temporal
    on<DeleteProductFromTemporaryPackageEvent>(
        _onDeleteProductFromTemporaryPackageEvent);
    on<ViewProductImageEvent>(_onViewProductImageEvent);

    on<SortPackingListEvent>((event, emit) {
      List<PedidoPackingResult> sortedList =
          List.from(this.listOfPedidosFilters);
      sortedList.sort((a, b) {
        switch (event.field) {
          case 'priority':
            // Asumimos '1' = Alta, '0' = Normal.
            final String pA = a.priority ?? '0';
            final String pB = b.priority ?? '0';
            // Si es ascendente: 0 -> 1 (Normal primero).
            // Si es descendente: 1 -> 0 (Alta primero).
            currentFilterKey =
                event.ascending ? 'priority_normal' : 'priority_high';

            return event.ascending ? pA.compareTo(pB) : pB.compareTo(pA);

          case 'backorder':
            // Verificamos si tienen nombre de backorder (no nulo y no vacío)
            final bool hasBackorderA =
                a.backorderName != null && a.backorderName!.isNotEmpty;
            final bool hasBackorderB =
                b.backorderName != null && b.backorderName!.isNotEmpty;

            // Convertimos a números para poder comparar:
            // 1 = Tiene Backorder
            // 0 = No tiene
            final int valA = hasBackorderA ? 1 : 0;
            final int valB = hasBackorderB ? 1 : 0;
            currentFilterKey =
                event.ascending ? 'backorder_asc' : 'backorder_desc';
            // Si es ascendente (true): 0 va primero (Sin backorder -> Con backorder)
            // Si es descendente (false): 1 va primero (Con backorder -> Sin backorder)
            return event.ascending
                ? valA.compareTo(valB)
                : valB.compareTo(valA);

          case 'date':
            // Parseo seguro de fechas
            DateTime dateA =
                DateTime.tryParse(a.fechaCreacion.toString()) ?? DateTime(1900);
            DateTime dateB =
                DateTime.tryParse(b.fechaCreacion.toString()) ?? DateTime(1900);

            int resultDate = dateA.compareTo(dateB);
            currentFilterKey = event.ascending ? 'date_asc' : 'date_desc';
            return event.ascending ? resultDate : -resultDate;

          case 'name':
            final nameA = a.name ?? '';
            final nameB = b.name ?? '';
            currentFilterKey = event.ascending ? 'name_asc' : 'name_desc';
            int resultName = nameA.toLowerCase().compareTo(nameB.toLowerCase());
            return event.ascending ? resultName : -resultName;

          default:
            return 0;
        }
      });

      this.listOfPedidosFilters = sortedList;
      emit(PackingPackSuccess(sortedList));
    });
  }

  void _onViewProductImageEvent(
      ViewProductImageEvent event, Emitter<PackingPedidoState> emit) async {
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

  void _onDeleteProductFromTemporaryPackageEvent(
      DeleteProductFromTemporaryPackageEvent event,
      Emitter<PackingPedidoState> emit) async {
    try {
      emit(DeleteProductFromTemporaryPackageLoading());

      //tenemos que revertir los valores de is_ok

      //validamos que el producto no este en la lista de producto de por hacer

      if (listOfProductosProgress
          .any((prod) => prod.idMove == event.product.idMove)) {
        ///buscamos

        await db.productosPedidosRepository.findAndAddQuantityAndDelete(
          event.product.idProduct ?? 0,
          event.product.idMove ?? 0,
          event.product.quantitySeparate ?? 0,
          event.product.pedidoId ?? 0,
          'packing-pack',
        );
        //actualizamos todas las listas
        add(LoadPedidoAndProductsEvent(event.product.pedidoId ?? 0));
        emit(DeleteProductFromTemporaryPackageOkState());
        return;
      }

      print('event.product.pedidoId: ${event.product.toMap()}');

      // is_separate
      await db.productosPedidosRepository.revertProductFields(
          event.product.pedidoId ?? 0,
          event.product.idProduct ?? 0,
          event.product.idMove ?? 0,
          'packing-pack');

      //actualizamos todas las listas
      add(LoadPedidoAndProductsEvent(event.product.pedidoId ?? 0));

      emit(DeleteProductFromTemporaryPackageOkState());
    } catch (e, s) {
      print('Error en el  _onDeleteProductFromTemporaryPackageEvent: $e, $s');
      emit(DeleteProductFromTemporaryPackageError(e.toString()));
    }
  }

  void _onValidateConfirmEvent(
      ValidateConfirmEvent event, Emitter<PackingPedidoState> emit) async {
    try {
      emit(ValidateConfirmLoading());
      final response = await wmsPackingRepository.confirmationValidate(
          event.idPedido, event.isBackOrder, event.isLoadinDialog);

      if (response.result?.code == 200) {
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

  void _onCreateBackOrder(
      CreateBackPackOrNot event, Emitter<PackingPedidoState> emit) async {
    try {
      emit(CreateBackOrderOrNotLoading());

      final response = await wmsPackingRepository.validateTransfer(
          event.idPick, event.isBackOrder, false);

      if (response.result?.code == 200) {
        add(StartOrStopTimePack(
          event.idPick,
          'end_time_transfer',
        ));

        await db.pedidoPackRepository.updatePedidoPackField(
          event.idPick,
          "is_terminate",
          1,
        );
        //pedimos los nuevos picks
        add(LoadPackingPedidoFromDBEvent());

        emit(CreateBackOrderOrNotSuccess(
            event.isBackOrder, response.result?.msg ?? ""));
      } else {
        emit(CreateBackOrderOrNotFailure(
          response.result?.msg ??
              'Error Desconocido contactar con Soporte Técnico',
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

  void _onStartOrStopTimeOrder(
      StartOrStopTimePack event, Emitter<PackingPedidoState> emit) async {
    try {
      final time = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      print("time : $time");

      if (event.value == "start_time_transfer") {
        await db.pedidoPackRepository.updatePedidoPackField(
          event.idPedido,
          "start_time_transfer",
          time,
        );
      } else if (event.value == "end_time_transfer") {
        await db.pedidoPackRepository.updatePedidoPackField(
          event.idPedido,
          "end_time_transfer",
          time,
        );
      }

      await db.pedidoPackRepository.updatePedidoPackField(
        event.idPedido,
        "is_selected",
        1,
      );
      await db.pedidoPackRepository.updatePedidoPackField(
        event.idPedido,
        "is_started",
        1,
      );

      //hacemos la peticion de mandar el tiempo
      final response = await wmsPackingRepository.sendTimePack(
        event.idPedido,
        event.value,
        time,
        false,
      );

      if (response) {
        emit(StartOrStopTimePackSuccess(event.value));
      } else {
        emit(StartOrStopTimePackFailure('Error al enviar el tiempo'));
      }
    } catch (e, s) {
      print('Error en el _onStartOrStopTimeOrder: $e, $s');
    }
  }

  //metodo para desempacar productos
  void _onUnPackingEvent(
      UnPackingEvent event, Emitter<PackingPedidoState> emit) async {
    try {
      emit(UnPackingLoading());

      final responseUnPacking = await wmsPackingRepository.unPack(
        event.request,
      );

      if (responseUnPacking.result?.code == 200) {
        //si es exitoso procedemos a desemapcar los productos
        //recorremos todo los productos del request
        for (var product in event.request.listItems) {
          //actualizamos el estado del producto como no separado
          await db.productosPedidosRepository
              .setFieldTableProductosPedidosUnPacking(
                  event.pedidoId,
                  event.productId,
                  "is_separate",
                  null,
                  product.idMove,
                  event.request.idPaquete,
                  'packing-pack');
          //actualizamso el estado del producto como no empaquetado
          await db.productosPedidosRepository
              .setFieldTableProductosPedidosUnPacking(
                  event.pedidoId,
                  event.productId,
                  "is_package",
                  null,
                  product.idMove,
                  event.request.idPaquete,
                  'packing-pack');

          //actualizamos el estado del producto como no dividido
          await db.productosPedidosRepository
              .setFieldTableProductosPedidosUnPacking(
                  event.pedidoId,
                  event.productId,
                  "is_product_split",
                  null,
                  product.idMove,
                  event.request.idPaquete,
                  'packing-pack');
          //actualizamos el estado del producto como no certificado
          await db.productosPedidosRepository
              .setFieldTableProductosPedidosUnPacking(
                  event.pedidoId,
                  event.productId,
                  "is_certificate",
                  null,
                  product.idMove,
                  event.request.idPaquete,
                  'packing-pack');

          //actualizamos el valor de is_location
          await db.productosPedidosRepository
              .setFieldTableProductosPedidosUnPacking(
                  event.pedidoId,
                  event.productId,
                  "is_location_is_ok",
                  null,
                  product.idMove,
                  event.request.idPaquete,
                  'packing-pack');

          //actualizamos el valor de quantity_separate
          await db.productosPedidosRepository
              .setFieldTableProductosPedidosUnPacking(
                  event.pedidoId,
                  event.productId,
                  "quantity_separate",
                  null,
                  product.idMove,
                  event.request.idPaquete,
                  'packing-pack');

          //actualizamos el valor de is_selected
          await db.productosPedidosRepository
              .setFieldTableProductosPedidosUnPacking(
                  event.pedidoId,
                  event.productId,
                  "is_selected",
                  null,
                  product.idMove,
                  event.request.idPaquete,
                  'packing-pack');

          //actualizamos el valor de product_is_ok
          await db.productosPedidosRepository
              .setFieldTableProductosPedidosUnPacking(
                  event.pedidoId,
                  event.productId,
                  "product_is_ok",
                  null,
                  product.idMove,
                  event.request.idPaquete,
                  'packing-pack');

          //actualzamos el valor de is_quantity_is_ok
          await db.productosPedidosRepository
              .setFieldTableProductosPedidosUnPacking(
                  event.pedidoId,
                  event.productId,
                  "is_quantity_is_ok",
                  null,
                  product.idMove,
                  event.request.idPaquete,
                  'packing-pack');

          //actualizamos el valor de package_name
          await db.productosPedidosRepository
              .setFieldTableProductosPedidosUnPacking(
                  event.pedidoId,
                  event.productId,
                  "package_name",
                  null,
                  product.idMove,
                  event.request.idPaquete,
                  'packing-pack');

          //acrtualizamos el valor del id_paquete en el producto
          await db.productosPedidosRepository
              .setFieldTableProductosPedidosUnPacking(
                  event.pedidoId,
                  event.productId,
                  "id_package",
                  null,
                  product.idMove,
                  event.request.idPaquete,
                  'packing-pack');

          await db.productosPedidosRepository
              .setFieldTableProductosPedidosUnPacking(
                  event.pedidoId,
                  event.productId,
                  "observation",
                  null,
                  product.idMove,
                  event.request.idPaquete,
                  'packing-pack');
        }

        //restamos la cantidad de productos desempacados a un paquete
        await db.packagesRepository.updatePackageCantidad(
          event.request.idPaquete,
          event.request.listItems.length,
        );

        //VERIFICAMOS CUANTOS PRODUCTOS TIENE EL PAQUETE
        final response =
            await db.packagesRepository.getPackageById(event.request.idPaquete);
        if (response != null) {
          if (response.cantidadProductos == 0) {
            //si la cantidad de productos es 0 eliminamos el paquete

            await updateConsecutivePackages(
              consecutivoReferencia: response.consecutivo ?? '',
              packages: packages,
            );

            await db.packagesRepository
                .deletePackageById(event.request.idPaquete);
            //vamos actualizar los consecutivos
          }
        }

        //actualizamos la lista de productos
        add(LoadPedidoAndProductsEvent(event.pedidoId));
        emit(UnPackignSuccess("Desempaquetado del producto exitoso"));
      } else {
        emit(UnPackignError('Error al desempacar los productos'));
      }
    } catch (e, s) {
      print('Error en el  _onUnPackingEvent: $e, $s');
      emit(UnPackignError(e.toString()));
    }
  }

  Future<void> updateConsecutivePackages({
    required String consecutivoReferencia,
    required List<Paquete> packages,
  }) async {
    final refNum = _extraerNumeroConsecutivo(consecutivoReferencia);
    if (refNum == null) return;

    for (final paquete in packages) {
      final paqueteNum =
          _extraerNumeroConsecutivo(paquete.consecutivo?.toString());

      if (paqueteNum != null && paqueteNum > refNum) {
        final nuevoConsecutivo = 'Caja${paqueteNum - 1}';
        final paqueteActualizado = Paquete(
          id: paquete.id,
          name: paquete.name,
          batchId: paquete.batchId,
          pedidoId: paquete.pedidoId,
          cantidadProductos: paquete.cantidadProductos,
          listaProductosInPacking: paquete.listaProductosInPacking,
          isSticker: paquete.isSticker,
          isCertificate: paquete.isCertificate,
          type: paquete.type,
          consecutivo: nuevoConsecutivo,
        );

        await db.packagesRepository.updatePackageById(paqueteActualizado);
      }
    }
  }

  int? _extraerNumeroConsecutivo(String? consecutivo) {
    if (consecutivo == null) return null;
    final match = RegExp(r'(\d+)$').firstMatch(consecutivo);
    return match != null ? int.parse(match.group(1)!) : null;
  }

  //*metodo para seleccionar un producto sin certificar
  void _onSelectProductPackingEvent(
      SelectProductPackingEvent event, Emitter<PackingPedidoState> emit) async {
    try {
      // Verificar si el producto ya está en la lista de productos seleccionados
      if (!listOfProductsForPacking.contains(event.producto)) {
        // Agregar el producto a la lista si no está ya presente
        listOfProductsForPacking.add(event.producto);
        // Emitir un nuevo estado con la lista actualizada
        emit(ListOfProductsForPackingState(listOfProductsForPacking));
      }
    } catch (e, s) {
      print('Error en el _onSelectProductPackingEvent: $e, $s');
      emit(WmsPackingErrorState(e.toString()));
    }
  }

  //*metodo para deseleccionar un producto sin certificar
  void _onUnSelectProductPackingEvent(UnSelectProductPackingEvent event,
      Emitter<PackingPedidoState> emit) async {
    try {
      // Verificar si el producto está en la lista antes de intentar eliminarlo
      if (listOfProductsForPacking.contains(event.producto)) {
        // Eliminar el producto de la lista
        listOfProductsForPacking.remove(event.producto);
        // Emitir un nuevo estado con la lista actualizada
        emit(ListOfProductsForPackingState(listOfProductsForPacking));
      }
    } catch (e, s) {
      print('Error en el _onUnSelectProductPackingEvent: $e, $s');
      emit(WmsPackingErrorState(e.toString()));
    }
  }

  void _onSetPackingsEvent(
      SetPackingsEvent event, Emitter<PackingPedidoState> emit) async {
    try {
      if (event.productos.isEmpty) return;

      emit(WmsPackingLoadingState());

      final idOperario = await PrefUtils.getUserId();
      final fechaTransaccion = DateTime.now();
      final fechaFormateada = formatoFecha(fechaTransaccion);

      List<ListItemPack> listItems = event.productos.map((producto) {
        return ListItemPack(
          idMove: producto.idMove ?? 0,
          idProducto: producto.idProduct,
          idLote: int.parse(producto.loteId.toString()),
          idUbicacionOrigen:
              (producto.idLocation is int) ? producto.idLocation : 0,
          idUbicacionDestino:
              (producto.idLocation is int) ? producto.idLocationDest : 0,
          cantidadEnviada: event.isCertificate
              ? (producto.quantitySeparate ?? 0) > (producto.quantity)
                  ? producto.quantity
                  : producto.quantitySeparate ?? 0
              : producto.quantity ?? 0,
          observacion: producto.observation ?? 'Sin novedad',
          timeLine: producto.timeSeparate == 0.0 ? 2 : producto.timeSeparate,
          idOperario: idOperario,
          fechaTransaccion: fechaFormateada,
        );
      }).toList();

      final packingRequest = PackingPackRequest(
        idTransferencia: event.productos[0].pedidoId ?? 0,
        isSticker: event.isSticker,
        isCertificate: event.isCertificate,
        pesoTotalPaquete: 34.0, // Considera calcular esto dinámicamente
        listItems: listItems,
      );

      final responsePacking = await wmsPackingRepository.sendPackRequest(
        packingRequest,
        true,
      );

      if (responsePacking.result?.code != 200) {
        emit(WmsPackingErrorState(responsePacking.result?.msg ?? ""));
        return;
      }

      final paquete = Paquete(
        id: responsePacking.result?.result?[0].idPaquete ?? 0,
        name: responsePacking.result?.result?[0].namePaquete ?? '',
        batchId: event.productos[0].batchId,
        pedidoId: event.productos[0].pedidoId,
        cantidadProductos: event.productos.length,
        listaProductosInPacking: event.productos,
        isSticker: event.isSticker,
        consecutivo: responsePacking.result?.result?[0].consecutivo ?? 0,
      );

      packages.add(paquete);
      await db.packagesRepository.insertPackage(paquete, 'packing-pack');

      await db.pedidoPackRepository.updatePedidoPackField(
        currentPedidoPack.id ?? 0,
        "is_selected",
        1,
      );

      await _actualizarProductoBatch(
        db,
        event.productos,
        paquete,
        event.isCertificate,
      );

      listOfProductsForPacking = [];

      add(LoadPedidoAndProductsEvent(event.productos[0].pedidoId ?? 0));

      emit(WmsPackingSuccessState('Empaquetado exitoso'));
    } catch (e, s) {
      print('Error en _onSetPackingsEvent: $e\n$s');
      emit(WmsPackingErrorState('Ocurrió un error inesperado'));
    }
  }

  Future<void> _actualizarProductoBatch(
    DataBaseSqlite db,
    List<ProductoPedido> productos,
    Paquete paquete,
    bool isCertificate,
  ) async {
    final idPaquete = paquete.id;
    final nombrePaquete = paquete.name;

    final fieldsToUpdate = isCertificate
        ? {
            "package_name": nombrePaquete,
            "is_separate": 1,
            "id_package": idPaquete,
            "is_package": 1,
          }
        : {
            "package_name": nombrePaquete,
            "is_separate": 1,
            "id_package": idPaquete,
            "is_package": 1,
            "is_certificate": 0,
            "time_separate": 2
          };

    await db.productosPedidosRepository.updateProductosBatch(
      productos: productos,
      fieldsToUpdate: fieldsToUpdate,
      isCertificate: isCertificate,
    );
  }

  ///*metodo para cambiar el estado del sticker
  void _onChangeStickerEvent(
      ChangeStickerEvent event, Emitter<PackingPedidoState> emit) {
    isSticker = event.isSticker;
    emit(ChangeStickerState(isSticker));
  }

  //*evento para ver la cantidad
  void _onShowQuantityEvent(
      ShowQuantityPackEvent event, Emitter<PackingPedidoState> emit) {
    try {
      viewQuantity = !viewQuantity;
      emit(ShowQuantityPackState(viewQuantity));
    } catch (e, s) {
      print("❌ Error en _onShowQuantityEvent: $e, $s");
    }
  }

  //*metodo que se encarga de hacer el picking
  void _onSetPickingsEvent(
      SetPickingsEvent event, Emitter<PackingPedidoState> emit) async {
    try {
      emit(SetPickingPackingLoadingState());

      final DateTime dateTimeNow = DateTime.now();

      await db.productosPedidosRepository.setFieldTableProductosPedidos3(
          event.pedidoId,
          event.productId,
          "time_separate_end",
          dateTimeNow.toString(),
          event.idMove,
          'packing-pack');

      final productUpdate = await db.productosPedidosRepository
          .getProductoPedidoById(event.pedidoId, event.idMove, 'packing-pack');

      print('productUpdate :${productUpdate.toMap()}');

      // Calcular la diferencia del producto ya separado
      Duration differenceProduct = dateTimeNow
          .difference(DateTime.parse(productUpdate.timeSeparatStart));

      // Obtener la diferencia en segundos
      double secondsDifferenceProduct =
          differenceProduct.inMilliseconds / 1000.0;

      print('secondsDifferenceProduct: $secondsDifferenceProduct');
      //actualizamos el dato de tiempoSeparado
      await db.productosPedidosRepository.setFieldTableProductosPedidos3(
          event.pedidoId,
          event.productId,
          "time_separate",
          secondsDifferenceProduct,
          event.idMove,
          'packing-pack');

      //mandamos a traer el tiempo de inicio

      //actualizamos el estado del producto como separado
      await db.productosPedidosRepository.setFieldTableProductosPedidos3(
          event.pedidoId,
          event.productId,
          "is_separate",
          1,
          event.idMove,
          'packing-pack');
      await db.productosPedidosRepository.setFieldTableProductosPedidos3(
          event.pedidoId,
          event.productId,
          "is_package",
          0,
          event.idMove,
          'packing-pack');
      await db.productosPedidosRepository.setFieldTableProductosPedidos3(
          event.pedidoId,
          event.productId,
          "is_certificate",
          1,
          event.idMove,
          'packing-pack');

      //actualizamos la cantidad se mparada
      quantitySelected = 0;
      viewQuantity = false;
      add(LoadPedidoAndProductsEvent(event.pedidoId));
      emit(SetPickingPackingOkState());
    } catch (e, s) {
      print('Error en el  _onSetPickingsEvent: $e, $s');
      emit(SetPickingPackingErrorState(e.toString()));
    }
  }

  //*metdo para dividir el producto
  void _onSetPickingsSplitEvent(
      SetPickingSplitEvent event, Emitter<PackingPedidoState> emit) async {
    try {
      emit(SetPickingPackingLoadingState());

      final DateTime dateTimeNow = DateTime.now();

      await db.productosPedidosRepository.setFieldTableProductosPedidos3(
          event.pedidoId,
          event.productId,
          "time_separate_end",
          dateTimeNow.toString(),
          event.idMove,
          'packing-pack');
      await db.productosPedidosRepository.setFieldTableProductosPedidos3(
          event.pedidoId,
          event.productId,
          "observation",
          'Producto dividido',
          event.idMove,
          'packing-pack');

      final productUpdate = await db.productosPedidosRepository
          .getProductoPedidoById(event.pedidoId, event.idMove, 'packing-pack');

      print('productUpdate :${productUpdate.toMap()}');

      // Calcular la diferencia del producto ya separado
      Duration differenceProduct = dateTimeNow
          .difference(DateTime.parse(productUpdate.timeSeparatStart));

      // Obtener la diferencia en segundos
      double secondsDifferenceProduct =
          differenceProduct.inMilliseconds / 1000.0;

      print('secondsDifferenceProduct: $secondsDifferenceProduct');
      //actualizamos el dato de tiempoSeparado
      await db.productosPedidosRepository.setFieldTableProductosPedidos3(
          event.pedidoId,
          event.productId,
          "time_separate",
          secondsDifferenceProduct,
          event.idMove,
          'packing-pack');

      //actualizamos el estado del producto como separado
      await db.productosPedidosRepository.setFieldTableProductosPedidos3(
          event.pedidoId,
          event.productId,
          "is_separate",
          1,
          event.idMove,
          'packing-pack');

      //marcamos el producto como producto split
      await db.productosPedidosRepository.setFieldTableProductosPedidos3(
          event.pedidoId,
          event.productId,
          "is_product_split",
          1,
          event.idMove,
          'packing-pack');

      await db.productosPedidosRepository.setFieldTableProductosPedidos3(
          event.pedidoId,
          event.productId,
          "is_package",
          0,
          event.idMove,
          'packing-pack');
      // actualizamos el estado del producto como certificado
      await db.productosPedidosRepository.setFieldTableProductosPedidos3(
          event.pedidoId,
          event.productId,
          "is_certificate",
          1,
          event.idMove,
          'packing-pack');

//calculamos la cantidad pendiente del producto
      var pendingQuantity = (event.producto.quantity - event.quantity);
      //creamos un nuevo producto (duplicado) con la cantidad separada
      await db.productosPedidosRepository.insertDuplicateProductoPedido(
          event.producto, pendingQuantity, event.producto.type ?? "");

      //actualizamos la cantidad separada
      quantitySelected = 0;
      viewQuantity = false;
      //actualizamos la lista de productos
      add(LoadPedidoAndProductsEvent(event.pedidoId));
      emit(SetPickingPackingOkState());
    } catch (e, s) {
      print('Error en el  _onSetPickingsSplitEvent: $e, $s');
      emit(SplitProductError(e.toString()));
    }
  }

  //*meotod para cargar todas las novedades
  void _onLoadAllNovedadesEvent(
      LoadAllNovedadesPackEvent event, Emitter<PackingPedidoState> emit) async {
    try {
      emit(NovedadesPackingLoadingState());
      final response = await db.novedadesRepository.getAllNovedades();
      if (response != null) {
        novedades.clear();
        novedades = response;
        print("novedades: ${novedades.length}");
        emit(NovedadesPackingLoadedState(listOfNovedades: novedades));
      }
    } catch (e, s) {
      print("Error en __onLoadAllNovedadesEvent: $e, $s");
      emit(NovedadesPackingErrorState(e.toString()));
    }
  }

  //metodo para enviar la temperatura del producto

  void _onSendTemperatureEvent(
    SendTemperatureEvent event,
    Emitter<PackingPedidoState> emit,
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
      final response = await wmsPackingRepository.sendTemperature(
        resultTemperature.temperature ?? 0.0,
        event.moveLineId,
        event.file,
        true,
      );

      //esperamos la repuesta y emitimos el estadp
      if (response.code == 200) {
        //actualizamos la temepratura por producto en la bd y la imagen

        await db.productosPedidosRepository.setFieldTableProductosPedidos2(
            currentProduct.pedidoId ?? 0,
            currentProduct.idProduct ?? 0,
            'temperatura',
            resultTemperature.temperature ?? 0.0,
            event.moveLineId,
            'packing-pack');

        //agregamos la imagen de temperatura del producto a la bd
        await db.productosPedidosRepository.setFieldTableProductosPedidos2(
            currentProduct.pedidoId ?? 0,
            currentProduct.idProduct ?? 0,
            'image',
            response.imageUrl ?? "",
            event.moveLineId,
            'packing-pack');

        //limpiamos el dato de temperatura
        resultTemperature = TemperatureIa();

        add(LoadPedidoAndProductsEvent(currentProduct.pedidoId ?? 0));

        emit(SendTemperatureSuccess(
            response.result ?? 'Temperatura enviada correctamente'));
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
    SendTemperatureManualPackEvent event,
    Emitter<PackingPedidoState> emit,
  ) async {
    try {
      emit(SendTemperatureLoading());

      print('currentProduct: ${currentProduct.toMap()}');

      //enviamos la temperatura con la imagen
      final response = await wmsPackingRepository.sendTemperatureManual(
        temperatureController.text,
        event.moveLineId,
        true,
      );

      //esperamos la repuesta y emitimos el estadp

      //esperamos la repuesta y emitimos el estadp
      if (response.code == 200) {
        //actualizamos la temepratura por producto en la bd y la imagen
        await db.productosPedidosRepository.setFieldTableProductosPedidos2(
            currentProduct.pedidoId ?? 0,
            currentProduct.idProduct ?? 0,
            'temperatura',
            temperatureController.text ?? 0.0,
            event.moveLineId,
            'packing-pack');

        //limpiamos el dato de temperatura
        temperatureController.clear();
        resultTemperature = TemperatureIa();

        add(LoadPedidoAndProductsEvent(currentProduct.pedidoId ?? 0));
        emit(SendTemperatureSuccess(
            response.result ?? 'Temperatura enviada correctamente'));
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

  //metodo para obtener la temperaturs desde la ia

  void _onGetTemperatureEvent(
    GetTemperatureEvent event,
    Emitter<PackingPedidoState> emit,
  ) async {
    try {
      emit(GetTemperatureLoading());
      // 1. Llamar al método que analiza la imagen y devuelve la temperatura
      final result =
          await wmsPackingRepository.getTemperatureWithImage(event.file);

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
      print('Error en el _onGetTemperatureEvent: $e, $s');
      emit(GetTemperatureFailure(
          'Ocurrió un error al procesar la imagen y obtener la temperatura'));
    }
  }

  //metodo para enviar una imagen de novedad
  void _onSendImageNovedad(
      SendImageNovedad event, Emitter<PackingPedidoState> emit) async {
    try {
      print('------ Enviando imagen de novedad ---');
      print(
          'pedidoId: ${event.pedidoId} moveLineId: ${event.moveLineId} productId: ${event.productId}');
      emit(SendImageNovedadLoading());
      final response = await wmsPackingRepository.sendImageNoved(
        event.moveLineId,
        event.file,
      );
      if (response.code == 200) {
        //actualizamos la imagen de novedad en la bd
        await db.productosPedidosRepository.setFieldTableProductosPedidos3(
          event.pedidoId,
          event.productId,
          "image_novedad",
          response.imageUrl ?? "",
          event.moveLineId,
          'packing-pack',
        );

        emit(SendImageNovedadSuccess(response, event.cantidad));
        //  add(GetPorductsToEntrada(event.idRecepcion));
      } else {
        emit(SendImageNovedadFailure(
            response.msg ?? 'Error al enviar la imagen'));
      }
    } catch (e, s) {
      print('Error en el _onSendImageNovedad: $e, $s');
      emit(SendImageNovedadFailure('Ocurrió un error al enviar la imagen'));
    }
  }

  void _onFetchProductEvent(
      FetchProductEvent event, Emitter<PackingPedidoState> emit) async {
    try {
      isLocationOk = true;
      isProductOk = true;
      isLocationDestOk = true;
      isQuantityOk = true;

      emit(FetchProductLoadingState());
      listOfBarcodes.clear();
      currentProduct = ProductoPedido();
      currentProduct = event.pedido;
      listOfBarcodes = await db.barcodesPackagesRepository.getBarcodesProduct(
          currentProduct.batchId ?? 0,
          currentProduct.idProduct,
          currentProduct.idMove ?? 0,
          'packing-pack');
      locationIsOk = currentProduct.isLocationIsOk == 1 ? true : false;
      productIsOk = currentProduct.productIsOk == 1 ? true : false;
      locationDestIsOk = currentProduct.locationDestIsOk == 1 ? true : false;
      quantityIsOk = currentProduct.isQuantityIsOk == 1 ? true : false;
      quantitySelected = currentProduct.isProductSplit == 1
          ? 0
          : currentProduct.quantitySeparate ?? 0;
      products();

      emit(FetchProductLoadedState());
    } catch (e, s) {
      print('Error en el  _onFetchProductEvent: $e, $s');
      emit(FetchProductErrorState(e.toString()));
    }
  }

  void products() {
    // Limpiamos la lista 'listOfProductsName' para asegurarnos que no haya duplicados de iteraciones anteriores
    listOfProductsName.clear();

    // Recorremos los productos del batch
    for (var i = 0; i < listOfProductosProgress.length; i++) {
      var product = listOfProductosProgress[i];

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

  void _onAddQuantitySeparateEvent(
      AddQuantitySeparate event, Emitter<PackingPedidoState> emit) async {
    quantitySelected = quantitySelected + event.quantity;

    await db.productosPedidosRepository.incremenQtytProductSeparatePacking(
        event.pedidoId,
        event.productId,
        event.idMove,
        event.quantity,
        'packing-pack');

    emit(ChangeQuantitySeparateState(quantitySelected));
  }

  void _onChangeQuantityIsOkEvent(
      ChangeIsOkQuantity event, Emitter<PackingPedidoState> emit) async {
    if (event.isOk) {
      //actualizamos la cantidad del producto a true
      await db.productosPedidosRepository.setFieldTableProductosPedidos(
          event.pedidoId,
          event.productId,
          "is_quantity_is_ok",
          1,
          event.idMove,
          'packing-pack');
    }
    quantityIsOk = event.isOk;
    emit(ChangeIsOkState(
      quantityIsOk,
    ));
  }

  //*metodo para cambiar la cantidad seleccionada
  void _onChangeQuantitySelectedEvent(
      ChangeQuantitySeparate event, Emitter<PackingPedidoState> emit) async {
    print('event.quantity: ${event.quantity}');
    if (event.quantity > 0) {
      quantitySelected = event.quantity;
      await db.productosPedidosRepository.setFieldTableProductosPedidos3(
          event.pedidoId,
          event.productId,
          "quantity_separate",
          event.quantity,
          event.idMove,
          'packing-pack');
    }
    emit(ChangeQuantitySeparateState(quantitySelected));
  }

//*evento para limpiar el valor del scan
  void _onClearScannedValueEvent(
      ClearScannedValuePackEvent event, Emitter<PackingPedidoState> emit) {
    try {
      switch (event.scan) {
        case 'location':
          scannedValue1 = '';
          emit(ClearScannedValuePackState());
          break;
        case 'product':
          scannedValue2 = '';
          emit(ClearScannedValuePackState());
          break;
        case 'quantity':
          scannedValue3 = '';
          emit(ClearScannedValuePackState());
          break;
        case 'muelle':
          scannedValue4 = '';
          emit(ClearScannedValuePackState());
          break;

        case 'toDo':
          scannedValue5 = '';
          emit(ClearScannedValuePackState());
          break;

        default:
          print('Scan type not recognized: ${event.scan}');
      }
      emit(ClearScannedValuePackState());
    } catch (e, s) {
      print("❌ Error en _onClearScannedValueEvent: $e, $s");
    }
  }

  //*evento para actualizar el valor del scan
  void _onUpdateScannedValueEvent(
      UpdateScannedValuePackEvent event, Emitter<PackingPedidoState> emit) {
    try {
      switch (event.scan) {
        case 'location':
          // Acumulador de valores escaneados
          scannedValue1 += event.scannedValue.trim();
          print('scannedValue1: $scannedValue1');
          emit(UpdateScannedValuePackState(scannedValue1, event.scan));
          break;
        case 'product':
          scannedValue2 += event.scannedValue.trim();
          print('scannedValue2: $scannedValue2');
          emit(UpdateScannedValuePackState(scannedValue2, event.scan));
          break;
        case 'quantity':
          scannedValue3 += event.scannedValue.trim();
          print('scannedValue3: $scannedValue3');
          emit(UpdateScannedValuePackState(scannedValue3, event.scan));
          break;
        case 'muelle':
          print('scannedValue4: $scannedValue4');
          scannedValue4 += event.scannedValue.trim();
          emit(UpdateScannedValuePackState(scannedValue4, event.scan));
          break;

        case 'toDo':
          print('scannedValue5: $scannedValue5');
          scannedValue5 += event.scannedValue.trim();
          emit(UpdateScannedValuePackState(scannedValue5, event.scan));
          break;

        default:
          print('Scan type not recognized: ${event.scan}');
      }
    } catch (e, s) {
      print("❌ Error en _onUpdateScannedValueEvent: $e, $s");
    }
  }

  void _onChangeProductIsOkEvent(
      ChangeProductIsOkEvent event, Emitter<PackingPedidoState> emit) async {
    if (event.productIsOk) {
      //agregamos el tiempo de inicio
      await db.productosPedidosRepository.setFieldTableProductosPedidos(
          event.pedidoId,
          event.productId,
          "time_separate_start",
          DateTime.now().toString(),
          event.idMove,
          'packing-pack');

      //actualizamos el producto a true
      await db.productosPedidosRepository.setFieldTableProductosPedidos(
          event.pedidoId,
          event.productId,
          "product_is_ok",
          1,
          event.idMove,
          'packing-pack');
      //actualizamos la cantidad separada
      await db.productosPedidosRepository.setFieldTableProductosPedidos3(
          event.pedidoId,
          event.productId,
          "quantity_separate",
          event.quantity,
          event.idMove,
          'packing-pack');
    }
    productIsOk = event.productIsOk;
    emit(ChangeProductPackingIsOkState(
      productIsOk,
    ));
  }

  void _onChangeLocationDestIsOkEvent(
      ChangeLocationDestIsOkEvent event, Emitter<PackingPedidoState> emit) {
    locationDestIsOk = event.locationDestIsOk;
    emit(ChangeIsOkState(
      locationDestIsOk,
    ));
  }

  void _onChangeLocationIsOkEvent(
      ChangeLocationIsOkEvent event, Emitter<PackingPedidoState> emit) async {
    if (isLocationOk) {
      //*actualizamos la seleccion del pedido y producto
      //actualizamos el estado del pedido como seleccionado
      await db.pedidoPackRepository
          .updatePedidoPackField(event.pedidoId, "is_selected", 1);
      // actualizamo el valor de que he seleccionado el producto
      await db.productosPedidosRepository.setFieldTableProductosPedidos(
          event.pedidoId,
          event.productId,
          "is_selected",
          1,
          currentProduct.idMove ?? 0,
          'packing-pack');
      //*actualizamos la ubicacion del producto a true
      await db.productosPedidosRepository.setFieldTableProductosPedidos(
          event.pedidoId,
          event.productId,
          "is_location_is_ok",
          1,
          currentProduct.idMove ?? 0,
          'packing-pack');

      locationIsOk = true;
      emit(ChangeLocationPackingIsOkState(
        locationIsOk,
      ));
    }
  }

  void _onValidateFieldsPacking(
      ValidateFieldsPackingEvent event, Emitter<PackingPedidoState> emit) {
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
    print(
        'Location: $isLocationOk, Product: $isProductOk, LocationDest: $isLocationDestOk, Quantity: $isQuantityOk');
    emit(ValidateFieldsPackingState(event.isOk));
  }

  //*evento para ver el detalle
  void _onShowDetailEvent(
      ShowDetailvent event, Emitter<PackingPedidoState> emit) {
    try {
      viewDetail = !viewDetail;
      emit(ShowDetailPackState(viewDetail));
    } catch (e, s) {
      print("❌ Error en _onShowQuantityEvent: $e, $s");
    }
  }

  //*metodo para cargar el pedido actual y sus productos:
  void _onLoadPedidoAndProductsEvent(LoadPedidoAndProductsEvent event,
      Emitter<PackingPedidoState> emit) async {
    try {
      emit(LoadPedidoAndProductsLoading());
      //cargamos el pedido actual
      final response =
          await db.pedidoPackRepository.getPedidoPackById(event.idPedido);

      //obtenemos todos los productos de un pedido
      final responseProducts = await db.productosPedidosRepository
          .getProductosPedido(event.idPedido, 'packing-pack');

      if (response != null) {
        currentPedidoPack = response;

        if (responseProducts != null && responseProducts is List) {
          print(
              'responseProducts lista de productos: ${responseProducts.length}');
          listOfProductos.clear();
          listOfProductos = responseProducts;
          productsDonePacking.clear();

          //filtramos y creamos la lista de productos listo a empacar
          productsDone = listOfProductos
              .where((product) =>
                  (product.isSeparate == true || product.isSeparate == 1) &&
                  (product.isCertificate == true ||
                      product.isCertificate == 1) &&
                  (product.isPackage == false || product.isPackage == 0))
              .toList();

          print('productsDone: ${productsDone.length}');
          print('listOfProductos: ${listOfProductos.length}');

          productsDonePacking = listOfProductos
              .where((product) =>
                  product.isSeparate == 1 && product.isPackage == 1)
              .toList();

          print('productsDonePacking: ${productsDonePacking.length}');

          //filtramos y creamos la lista de productos listo a separar para empaque
          listOfProductosProgress = listOfProductos.where((product) {
            return product.isSeparate == null || product.isSeparate == 0;
          }).toList();

          ordenarProducts();

          //despues de obtener los productos vamos a obtener todos los codigos de barras de este pedido
          listAllOfBarcodes.clear();
          final responseBarcodes = await db.barcodesPackagesRepository
              .getBarcodesByBatchIdAndType(event.idPedido, 'packing-pack');

          if (responseBarcodes != null && responseBarcodes is List) {
            listAllOfBarcodes = responseBarcodes;
          }

          //traemos todos los paquetes de la base de datos del pedido en cuesiton
          final packagesDB =
              await db.packagesRepository.getPackagesPedido(event.idPedido);
          packages.clear();
          packages.addAll(packagesDB);
          print('packagesDB: ${packagesDB.length}');

          //obtenemos las posiciones de los productos
          getPosicions();
        }

        emit(LoadPedidoAndProductsLoaded(
          currentPedidoPack,
        ));
      } else {
        emit(LoadPedidoAndProductsError('No se encontró el pedido'));
      }
    } catch (e, s) {
      print('Error en el _onLoadPedidoAndProductsEvent: $e, $s');
      emit(LoadPedidoAndProductsError(e.toString()));
    }
  }

  void ordenarProducts() {
    listOfProductosProgress.sort((a, b) {
      return a.locationId!.compareTo(b.locationId!);
    });
  }

  void getPosicions() {
    positions.clear(); // Limpia la lista antes de agregar nuevas posiciones
    for (var product in listOfProductos) {
      if (product.locationId != null) {
        // Verifica si la posición ya existe en la lista
        if (!positions.contains(product.locationId!)) {
          positions
              .add(product.locationId!); // Solo agrega si no está en la lista
        }
      }
    }
    print('positions: ${positions.length}');
  }

  //* metodo para cargar la configuracion del usuario
  void _onLoadConfigurationsUserEvent(
      LoadConfigurationsUser event, Emitter<PackingPedidoState> emit) async {
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

  //metodo para empezar o terminar el tiempo
  void _onStartOrStopTimePedido(
      StartOrStopTimePedido event, Emitter<PackingPedidoState> emit) async {
    try {
      final time = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      print("time : $time");
      if (event.value == "start_time_transfer") {
        await db.pedidoPackRepository.updatePedidoPackField(
          event.id,
          "start_time_transfer",
          time,
        );
        await db.pedidoPackRepository.updatePedidoPackField(
          event.id,
          "is_selected",
          1,
        );
      } else if (event.value == "end_time_transfer") {
        await db.pedidoPackRepository.updatePedidoPackField(
          event.id,
          "end_time_transfer",
          time,
        );
      }
      //hacemos la peticion de mandar el tiempo
      final response = await wmsPackingRepository.sendTime(
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
  void _onAssignUserToPedido(
      AssignUserToPedido event, Emitter<PackingPedidoState> emit) async {
    try {
      int userId = await PrefUtils.getUserId();
      String nameUser = await PrefUtils.getUserName();

      emit(AssignUserToPedidoLoading());
      final response = await wmsPackingRepository.assignUserToTransfer(
        false,
        userId,
        event.id,
      );

      if (response) {
        //actualizamos la tabla entrada:
        await db.pedidoPackRepository.updatePedidoPackField(
          event.id,
          "responsable_id",
          userId,
        );

        await db.pedidoPackRepository.updatePedidoPackField(
          event.id,
          "responsable",
          nameUser,
        );
        await db.pedidoPackRepository.updatePedidoPackField(
          event.id,
          "is_selected",
          1,
        );

        add(StartOrStopTimePedido(
          event.id,
          "start_time_transfer",
        ));

        emit(AssignUserToPedidoLoaded(
          id: event.id,
        ));
      } else {
        emit(AssignUserToPedidoError(
            "La recepción ya tiene un responsable asignado"));
      }
    } catch (e, s) {
      emit(AssignUserToPedidoError('Error al asignar el usuario'));
      print('Error en el _onAssignUserToOrder: $e, $s');
    }
  }

  void _onSearchPedidoEvent(
    SearchPedidoEvent event,
    Emitter<PackingPedidoState> emit,
  ) async {
    try {
      final query =
          event.query.trim(); // Elimina espacios en blanco al inicio/final

      if (query.isEmpty) {
        // Si la consulta está vacía, muestra la lista completa de la DB
        listOfPedidosFilters = listOfPedidosBD;
      } else {
        // Normaliza la consulta una sola vez para eficiencia
        final normalizedQuery = normalizeText(query);

        // Filtra la lista de pedidos de la base de datos (la fuente de verdad)
        listOfPedidosFilters = listOfPedidosBD.where((pedido) {
          // Normaliza los campos de cada pedido para la comparación
          final name = normalizeText(pedido.name ?? '');
          final referencia = normalizeText(pedido.referencia ?? '');
          final contactoName = normalizeText(pedido.contactoName ?? '');
          final backorder = normalizeText(pedido.backorderName ?? '');

          // Realiza la búsqueda en los campos relevantes
          // Si alguno de los campos contiene la consulta normalizada, se incluye el pedido
          return name.contains(normalizedQuery) ||
              referencia.contains(normalizedQuery) ||
              contactoName.contains(normalizedQuery) ||
              backorder.contains(normalizedQuery);
        }).toList();
      }

      // Emite el nuevo estado con la lista filtrada
      emit(PackingPedidoLoadedFromDBState(listOfPedidos: listOfPedidosBD));
    } catch (e, s) {
      print('Error en el _onSearchPedidoEvent: $e, $s');
      // Emite un estado de error si algo sale mal durante la búsqueda
      emit(PackingPedidoError(e.toString()));
    }
  }

  String normalizeText(String input) {
    // Normaliza texto: sin tildes, minúsculas, sin espacios a los extremos
    const Map<String, String> accentMap = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };

    return input
        .trim()
        .toLowerCase()
        .split('')
        .map((char) => accentMap[char] ?? char)
        .join();
  }

  void _onShowKeyboardEvent(
      ShowKeyboardEvent event, Emitter<PackingPedidoState> emit) {
    isKeyboardVisible = event.showKeyboard;
    emit(ShowKeyboardState(showKeyboard: isKeyboardVisible));
  }

  void _onLoadAllPackingEvent(
      LoadAllPackingPedidoEvent event, Emitter<PackingPedidoState> emit) async {
    emit(WmsPackingPedidoWMSLoading());
    try {
      final response =
          await wmsPackingRepository.resPackingPedido(event.isLoadinDialog);

      if (response.result != null && response.result is List) {
        listOfPedidos.clear();
        listOfPedidosBD.clear();
        listOfPedidos.addAll(response.result!);
        listOfPedidosBD.addAll(response.result!);

        if ((response.updateVersion ?? false) == true) {
          emit(NeedUpdateVersionState());
        }

        if (listOfPedidos.isNotEmpty) {
          await DataBaseSqlite()
              .pedidoPackRepository
              .insertPedidosPack(listOfPedidos);

          //convertir el mapa en una lista de productos unicos del pedido para packing
          //convertir el mapa en una lista de productos unicos del pedido para packing
          List<ProductoPedido> productsToInsert =
              listOfPedidos.expand((pedido) => pedido.listaProductos!).toList();
          //Convertir el mapa en una lista los barcodes unicos de cada producto
          List<Barcodes> barcodesToInsert = productsToInsert
              .expand((product) => product.productPacking!)
              .toList();

          //convertir el mapap en una lsita de los otros barcodes de cada producto
          List<Barcodes> otherBarcodesToInsert = productsToInsert
              .expand((product) => product.otherBarcode!)
              .toList();

          //convertir el mapa en una lista de productos unicos de paquetes que se encuentra en un pedido dentro de listado de paquetes y listado de productos
          List<ProductoPedido> productsPackagesToInsert = listOfPedidos
              .expand((pedido) => pedido.listaPaquetes!)
              .expand((paquete) => paquete.listaProductosInPacking!)
              .toList();
          print('productsPackagesToInsert :${productsPackagesToInsert.length}');

          //covertir el mapa en una lista de los paquetes de un pedido
          List<Paquete> packagesToInsert =
              listOfPedidos.expand((pedido) => pedido.listaPaquetes!).toList();

          // Enviar la lista agrupada de productos de un pedido para packing
          await DataBaseSqlite()
              .productosPedidosRepository
              .insertProductosPedidos(productsToInsert, 'packing-pack');
          // Enviar la lista agrupada de barcodes de un producto para packing
          await DataBaseSqlite()
              .barcodesPackagesRepository
              .insertOrUpdateBarcodes(barcodesToInsert, 'packing-pack');
          // Enviar la lista agrupada de otros barcodes de un producto para packing
          await DataBaseSqlite()
              .barcodesPackagesRepository
              .insertOrUpdateBarcodes(otherBarcodesToInsert, 'packing-pack');
          //guardamos los productos de los paquetes que ya fueron empaquetados
          await DataBaseSqlite()
              .productosPedidosRepository
              .insertProductosOnPackage(
                  productsPackagesToInsert, 'packing-pack');
          //enviamos la lista agrupada de los paquetes de un pedido para packing
          await DataBaseSqlite()
              .packagesRepository
              .insertPackages(packagesToInsert, 'packing-pack');

          //creamos las cajas que ya estan creadas
          print('productsToInsert pack : ${productsToInsert.length}');
          print('barcode product pack : ${barcodesToInsert.length}');
          print('otherBarcodes    pack : ${otherBarcodesToInsert.length}');
          print('paquetes: pack: ${otherBarcodesToInsert.length}');

          // //* Carga los batches desde la base de datos
          add(LoadPackingPedidoFromDBEvent());
        }

        emit(WmsPackingPedidoWMSLoaded(
          listOfPedidos: listOfPedidos,
        ));
      } else {
        print('Error resBatchs: response is null');
      }
    } catch (e, s) {
      print('Error en el  _onLoadAllPackingEvent: $e, $s');
      emit(PackingPedidoError(e.toString()));
    }
  }

  void _onLoadPackingPedidoFromDBEvent(LoadPackingPedidoFromDBEvent event,
      Emitter<PackingPedidoState> emit) async {
    try {
      emit(PackingPedidoLoadingState());
      final batchsFromDB = await db.pedidoPackRepository.getAllPedidosPack();
      listOfPedidosBD.clear();
      listOfPedidosBD = batchsFromDB;
      listOfPedidosFilters.clear();
      listOfPedidosFilters = List.from(listOfPedidosBD);
      emit(PackingPedidoLoadedFromDBState(listOfPedidos: listOfPedidosBD));
    } catch (e, s) {
      print('Error en el  _onLoadBatchsFromDBEvent: $e, $s');
      emit(PackingPedidoError(e.toString()));
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
      if (listOfProductos.isEmpty) {
        return "0.0";
      }
      dynamic totalSeparadas = 0;
      dynamic totalCantidades = 0;
      for (var product in listOfProductos) {
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
