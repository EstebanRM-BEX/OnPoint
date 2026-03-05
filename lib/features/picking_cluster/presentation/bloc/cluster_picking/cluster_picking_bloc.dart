import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/picking_cluster/data/models/lote_producto_model.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/lote_producto.dart';
import 'package:wms_app/features/picking_cluster/domain/usecases/view_product_image_usecase.dart';
import 'package:wms_app/core/utils/formats_utils.dart';
import 'package:wms_app/features/user/domain/entities/user_novelty.dart';
import 'package:wms_app/features/user/domain/usecases/get_user_novelties.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/batch_product.dart';
import 'package:wms_app/features/user/data/models/user_configuration_model.dart';
import 'package:wms_app/features/user/domain/usecases/get_user_configuration.dart';
import '../../../domain/entities/picking_batch.dart';
import '../../../domain/usecases/get_picking_cluster_data.dart';
import '../../../domain/usecases/get_local_picking_cluster_data.dart';
import '../../../domain/usecases/get_local_batch_products_data.dart';
import '../../../domain/usecases/get_barcodes_product_use_case.dart';
import '../../../domain/usecases/get_lotes_producto_use_case.dart';
import '../../../domain/usecases/increment_quantity_separate_use_case.dart';
import '../../../domain/usecases/increment_product_separate_qty_use_case.dart';
import '../../../domain/usecases/get_field_table_products_use_case.dart';
import '../../../domain/usecases/set_cluster_batch_field_use_case.dart';
import '../../../domain/usecases/set_cluster_batch_product_field_use_case.dart';
import '../../../domain/usecases/get_product_batch_use_case.dart';
import '../../../domain/usecases/send_product_odoo_use_case.dart';

part 'cluster_picking_event.dart';
part 'cluster_picking_state.dart';

@injectable
class ClusterPickingBloc
    extends Bloc<ClusterPickingEvent, ClusterPickingState> {
  final GetPickingClusterData getPickingClusterData;
  final GetLocalPickingClusterData getLocalPickingClusterData;
  final GetLocalBatchProductsData getLocalBatchProductsData;
  final GetLotesProductoUseCase getLotesProductoUseCase;
  final SetClusterBatchFieldUseCase setClusterBatchFieldUseCase;
  final SetClusterBatchProductFieldUseCase setClusterBatchProductFieldUseCase;
  final GetBarcodesProductUseCase getBarcodesProductUseCase;
  final IncrementQuantitySeparateUseCase incrementQuantitySeparateUseCase;
  final IncrementProductSeparateQtyUseCase incrementProductSeparateQtyUseCase;
  final GetFieldTableProductsUseCase getFieldTableProductsUseCase;
  final GetProductBatchUseCase getProductBatchUseCase;
  final SendProductOdooUseCase sendProductOdooUseCase;
  final ViewProductImageUseCase viewProductImageUseCase;

  //uses cases de bloc user
  final GetUserConfiguration getUserConfiguration;
  final GetUserNovelties getUserNovelties;

  // //*validaciones de campos del estado de la vista
  bool isLocationOk = true;
  bool isProductOk = true;
  bool isLocationDestOk = true;
  bool isQuantityOk = true;
  bool isLoteOk = true;
  bool viewQuantity = false;
  bool locationsDestIsOk = false;

  //*variables para validar
  bool locationIsOk = false;
  bool productIsOk = false;
  bool locationDestIsOk = false;
  bool quantityIsOk = false;
  bool loteIsOk = false;
  bool locationsDestIsok = false;

  //variables para validar
  dynamic quantitySelected = 0;
  String oldLocation = '';
  //*indice del producto actual
  int index = 0;

  //producto actual
  BatchProduct? currentProduct;

  //variable para el batch actual y no perderlo e estados de validación
  PickingBatch? currentBatch;

  // listado de productos
  List<BatchProduct> products = [];
  List<BatchProduct> filteredProducts = [];

  //*lista de novedades
  List<Novedad> novedades = [];

  //lista de lotes de un producto
  List<LoteProducto> listLotesProduct = [];
  List<LoteProducto> listLotesProductFilters = [];
  LoteProducto lotesProductCurrent = LoteProducto();

  List<BatchBarcode> listOfBarcodes = [];

  //configuraciones del usuario
  UserConfigurationModel configurations = UserConfigurationModel();

  bool _isProcessing = false; // Bandera para controlar el estado del proceso
  bool isProcessing = false; // Bandera para controlar el estado del proceso

  ClusterPickingBloc({
    required this.getPickingClusterData,
    required this.getLocalPickingClusterData,
    required this.getLocalBatchProductsData,
    required this.getLotesProductoUseCase,
    required this.getUserConfiguration,
    required this.setClusterBatchFieldUseCase,
    required this.setClusterBatchProductFieldUseCase,
    required this.getBarcodesProductUseCase,
    required this.incrementQuantitySeparateUseCase,
    required this.incrementProductSeparateQtyUseCase,
    required this.getFieldTableProductsUseCase,
    required this.getProductBatchUseCase,
    required this.sendProductOdooUseCase,
    required this.viewProductImageUseCase,
    required this.getUserNovelties,
  }) : super(ClusterPickingInitial()) {
    on<FetchPickingClustersEvent>(_onFetchPickingClusters);
    on<LoadLocalPickingClustersEvent>(_onLoadLocalPickingClusters);
    on<FetchBatchProductsEvent>(_onFetchBatchProducts);
    on<LoadCurrentProductEvent>(_onLoadCurrentProduct);
    on<LoadConfigurationsUserEvent>(_onLoadConfigurationsUserEvent);
    on<ValidateFieldsEvent>(_onValidateFieldsEvent);
    on<ChangeProductIsOkEvent>(_onChangeProductIsOkEvent);
    on<ChangeLocationIsOkEvent>(_onChangeLocationIsOkEvent);
    on<ClearFieldsEvent>(_onClearFieldsEvent);
    on<FetchBarcodesProductEvent>(_onFetchBarcodesProductEvent);
    on<ChangeQuantitySeparate>(_onChangeQuantitySelectedEvent);
    on<ChangeIsOkQuantity>(_onChangeQuantityIsOkEvent);
    on<AddQuantitySeparate>(_onAddQuantitySeparateEvent);
    on<ShowQuantityEvent>(_onShowQuantityEvent);
    on<UpdateNovedadProductEvent>(_onUpdateNovedadProductEvent);
    //*metodo para establecer un proceso en ejecucion
    on<SetIsProcessingEvent>(_onSetIsProcessingEvent);
    //evento para separar un producto
    on<SeparateProductEvent>(_onSeparateProductEvent);
    //*cambiar el producto actual
    on<ChangeCurrentProduct>(_onChangeCurrentProduct);
    on<ViewProductImageEvent>(_onViewProductImageEvent);
    //*evento para cargar un producto seleccionado
    on<LoadSelectedProductEvent>(_onLoadSelectedProductEvent);
  }

//metodo para cargar un producto seleccionado
  void _onLoadSelectedProductEvent(
      LoadSelectedProductEvent event, Emitter<ClusterPickingState> emit) {
    try {
      currentProduct = event.selectedProduct;
      quantitySelected = currentProduct?.quantitySeparate ?? 0;
      add(FetchBarcodesProductEvent());
      emit(LoadSelectedProductState(currentProduct!));
    } catch (e, s) {
      debugPrint("❌ Error en _onLoadSelectedProductEvent: $e -> $s");
    }
  }

  void _onViewProductImageEvent(
      ViewProductImageEvent event, Emitter<ClusterPickingState> emit) async {
    try {
      debugPrint('Obteniendo imagen del producto con ID: ${event.idProduct}');
      emit(ViewProductImageLoading());

      final result = await viewProductImageUseCase.call(
        ViewProductImageParams(
            idProduct: event.idProduct, isLoadinDialog: true),
      );

      result.fold(
        (failure) => emit(ViewProductImageFailure(failure.message)),
        (url) => emit(ViewProductImageSuccess(url)),
      );
    } catch (e, s) {
      debugPrint('Error en el ViewProductImageEvent: $e, $s');
      emit(ViewProductImageFailure(e.toString()));
    }
  }

  void _onChangeCurrentProduct(
      ChangeCurrentProduct event, Emitter<ClusterPickingState> emit) async {
    try {
      viewQuantity = false;
      emit(CurrentProductChangedStateLoading());

      await setClusterBatchProductFieldUseCase
          .call(SetClusterBatchProductFieldParams(
        batchId: currentBatch?.id ?? 0,
        productId: event.currentProduct.idProduct ?? 0,
        field: 'is_selected',
        value: 0,
        idMove: event.currentProduct.idMove ?? 0,
        type: event.type,
      ));

      DateTime dateTimeActuality = DateTime.parse(DateTime.now().toString());

      // Actualizamos el tiempo total del producto ya separado
      await setClusterBatchProductFieldUseCase
          .call(SetClusterBatchProductFieldParams(
        batchId: currentBatch?.id ?? 0,
        productId: currentProduct?.idProduct ?? 0,
        field: 'time_separate_end',
        value: dateTimeActuality.toString(),
        idMove: currentProduct?.idMove ?? 0,
        type: event.type,
      ));

      await setClusterBatchProductFieldUseCase
          .call(SetClusterBatchProductFieldParams(
        batchId: currentBatch?.id ?? 0,
        productId: event.currentProduct.idProduct ?? 0,
        field: 'is_separate',
        value: 1,
        idMove: event.currentProduct.idMove ?? 0,
        type: event.type,
      ));

      final starTimeProductResult = await getFieldTableProductsUseCase.call(
        GetFieldTableProductsParams(
          batchId: currentProduct?.batchId ?? 0,
          productId: currentProduct?.idProduct ?? 0,
          moveId: currentProduct?.idMove ?? 0,
          field: "time_separate_start",
          type: event.type,
        ),
      );

      final starTimeProduct = starTimeProductResult.fold(
        (failure) => "",
        (value) => value,
      );

      DateTime dateTimeStartProduct =
          starTimeProduct == "null" || starTimeProduct.isEmpty
              ? DateTime.parse(DateTime.now().toString())
              : DateTime.parse(starTimeProduct);

      // Calcular la diferencia del producto ya separado
      Duration differenceProduct =
          dateTimeActuality.difference(dateTimeStartProduct);

      // Obtener la diferencia en segundos
      double secondsDifferenceProduct =
          differenceProduct.inMilliseconds / 1000.0;

      await setClusterBatchProductFieldUseCase
          .call(SetClusterBatchProductFieldParams(
        batchId: currentBatch?.id ?? 0,
        productId: currentProduct?.idProduct ?? 0,
        field: 'time_total_separate',
        value: secondsDifferenceProduct,
        idMove: currentProduct?.idMove ?? 0,
        type: event.type,
      ));

      final (success, errorMessage) = await sendProuctOdoo(event.type);

      if (!success) {
        emit(CurrentProductChangedStateError(errorMessage));
        return;
      }

      if (filteredProducts
          .where((product) => product.isSeparate == 0)
          .isNotEmpty) {
        productIsOk = false;
        quantityIsOk = false;
        currentProduct = filteredProducts
            .where((product) => product.isSeparate == 0)
            .toList()
            .first;
        if (currentProduct?.locationId == oldLocation) {
          debugPrint('La ubicación es igual');
          locationIsOk = true;
        } else {
          locationIsOk = false;
          debugPrint('La ubicación es diferente');
        }

        await setClusterBatchProductFieldUseCase
            .call(SetClusterBatchProductFieldParams(
          batchId: currentBatch?.id ?? 0,
          productId: currentProduct?.idProduct ?? 0,
          field: 'time_separate_start',
          value: DateTime.now().toString(),
          idMove: currentProduct?.idMove ?? 0,
          type: event.type,
        ));
      }
      emit(CurrentProductChangedState(
          currentProduct: currentProduct!, index: index));

      add(FetchBatchProductsEvent(currentBatch!));

      //mostramos todas las variables

      return;
      // }
    } catch (e, s) {
      emit(CurrentProductChangedStateError('Error al cambiar de producto'));
      debugPrint("❌ Error en el ChangeCurrentProduct $e ->$s");
    }
  }

  //* Metodo para enviar al wms
  Future<(bool, String)> sendProuctOdoo(String type) async {
    try {
      debugPrint("sendProuctOdoo ------------");

      // Traer producto de la base de datos local
      final productResult = await getProductBatchUseCase.call(
        GetProductBatchParams(
          batchId: currentBatch?.id ?? 0,
          productId: currentProduct?.idProduct ?? 0,
          idMove: currentProduct?.idMove ?? 0,
          type: type,
        ),
      );

      final product = productResult.fold(
        (failure) {
          debugPrint("❌ Error al traer producto de BD local: \$failure");
          return null;
        },
        (value) => value,
      );

      if (product == null) {
        return (false, 'No se pudo obtener el producto localmente');
      }

      // 1. Delegamos lógica de negocio, cálculos de tiempo, y variables al UseCase
      final response = await sendProductOdooUseCase.call(
        SendProductOdooParams(
          product: product,
          type: type,
          cantItemsSeparados: currentBatch?.productSeparateQty ?? 0,
          configurations: configurations,
        ),
      );

      // 2. Evaluamos la respuesta pura
      return await response.fold(
        (failure) async {
          // --- RUTINA CUANDO FALLA EL ENVÍO A ODOO ---

          final mensajeError = failure is ServerFailure
              ? failure.message
              : 'Error al enviar a Odoo';

          await setClusterBatchProductFieldUseCase.call(
            SetClusterBatchProductFieldParams(
              batchId: product.batchId ?? 0,
              productId: product.idProduct ?? 0,
              field: 'is_send_odoo',
              value: null,
              idMove: product.idMove ?? 0,
              type: type,
            ),
          );

          await setClusterBatchProductFieldUseCase.call(
            SetClusterBatchProductFieldParams(
              batchId: product.batchId ?? 0,
              productId: product.idProduct ?? 0,
              field: 'is_separate',
              value: 0,
              idMove: product.idMove ?? 0,
              type: type,
            ),
          );

          await setClusterBatchProductFieldUseCase.call(
            SetClusterBatchProductFieldParams(
              batchId: product.batchId ?? 0,
              productId: product.idProduct ?? 0,
              field: 'is_selected',
              value: 0,
              idMove: product.idMove ?? 0,
              type: type,
            ),
          );

          await setClusterBatchProductFieldUseCase.call(
            SetClusterBatchProductFieldParams(
              batchId: product.batchId ?? 0,
              productId: product.idProduct ?? 0,
              field: 'quantity_separate',
              value: 0,
              idMove: product.idMove ?? 0,
              type: type,
            ),
          );

          // Emitimos fallo para reaccionar en la vista si querremos
          // emit(SendToOdooStateError(mensajeError));
          return (false, mensajeError);
        },
        (success) async {
          // --- RUTINA CUANDO EL ENVÍO FUE EXITOSO ---

          await setClusterBatchProductFieldUseCase.call(
            SetClusterBatchProductFieldParams(
              batchId: product.batchId ?? 0,
              productId: product.idProduct ?? 0,
              field: 'is_send_odoo',
              value: 1,
              idMove: product.idMove ?? 0,
              type: type,
            ),
          );

          // emit(SendToOdooStateSuccess(true));
          return (true, '');
        },
      );
    } catch (e) {
      debugPrint("❌ Error en sendProuctOdoo: \$e");
      // emit(SendToOdooStateError('Exception en sendProuctOdoo'));
      return (false, 'Exception en sendProuctOdoo');
    }
  }

  void _onSeparateProductEvent(
      SeparateProductEvent event, Emitter<ClusterPickingState> emit) async {
    try {
      await setClusterBatchProductFieldUseCase
          .call(SetClusterBatchProductFieldParams(
        batchId: currentBatch?.id ?? 0,
        productId: event.productId,
        field: 'is_separate',
        value: 1,
        idMove: event.idMove,
        type: event.type,
      ));

      await incrementProductSeparateQtyUseCase.call(
        IncrementProductSeparateQtyParams(
          batchId: event.batchId,
          type: event.type,
        ),
      );

      emit(SeparateProductState(event.productId));
    } catch (e, s) {
      debugPrint("❌ Error en _onSeparateProductEvent: $e, $s");
    }
  }

  //*evento para establecer un proceso en ejecucion
  void _onSetIsProcessingEvent(
      SetIsProcessingEvent event, Emitter<ClusterPickingState> emit) {
    try {
      isProcessing = event.isProcessing;
      emit(SetIsProcessingState(isProcessing));
    } catch (e, s) {
      debugPrint("❌ Error en _onSetIsProcessingEvent: $e, $s");
    }
  }

  void _onUpdateNovedadProductEvent(UpdateNovedadProductEvent event,
      Emitter<ClusterPickingState> emit) async {
    try {
      await setClusterBatchProductFieldUseCase
          .call(SetClusterBatchProductFieldParams(
        batchId: currentBatch?.id ?? 0,
        productId: currentProduct?.idProduct ?? 0,
        field: 'observation',
        value: event.selectedNovedad,
        idMove: currentProduct?.idMove ?? 0,
        type: 'cluster',
      ));
      emit(UpdateNovedadProductState(event.selectedNovedad));
    } catch (e, s) {
      debugPrint("❌ Error en _onUpdateNovedadProductEvent: $e, $s");
    }
  }

  //*evento para ver la cantidad
  void _onShowQuantityEvent(
      ShowQuantityEvent event, Emitter<ClusterPickingState> emit) {
    try {
      viewQuantity = !viewQuantity;
      emit(ShowQuantityState(viewQuantity));
    } catch (e, s) {
      debugPrint("❌ Error en _onShowQuantityEvent: $e, $s");
    }
  }

  void updateStateQuantity(
      int productId, int batchId, int idMove, int value) async {
    await setClusterBatchProductFieldUseCase
        .call(SetClusterBatchProductFieldParams(
      batchId: batchId,
      productId: productId,
      field: 'is_quantity_is_ok',
      value: value,
      idMove: idMove,
      type: 'cluster',
    ));
  }

  //*evento para aumentar la cantidad
  void _onAddQuantitySeparateEvent(
      AddQuantitySeparate event, Emitter<ClusterPickingState> emit) async {
    try {
      if (quantitySelected > (currentProduct?.quantity ?? 0)) {
        return;
      } else {
        quantitySelected = quantitySelected + event.quantity;
        await incrementQuantitySeparateUseCase
            .call(IncrementQuantitySeparateParams(
          batchId: currentBatch?.id ?? 0,
          productId: event.productId,
          idMove: event.idMove,
          quantity: event.quantity,
          type: event.type,
        ));

        updateStateQuantity(
            event.productId, currentBatch?.id ?? 0, event.idMove, 1);

        emit(ChangeQuantitySeparateStateSuccess(quantitySelected));
      }
    } catch (e, s) {
      emit(ChangeQuantitySeparateStateError('Error al aumentar cantidad'));
      debugPrint("❌ Error en el AddQuantitySeparate $e ->$s");
    }
  }

  void _onChangeQuantityIsOkEvent(
      ChangeIsOkQuantity event, Emitter<ClusterPickingState> emit) async {
    try {
      if (event.isOk) {
        updateStateQuantity(
            event.productId, currentBatch?.id ?? 0, event.idMove, 1);
      }
      quantityIsOk = event.isOk;
      emit(ChangeQuantityIsOkState(
        quantityIsOk,
      ));
    } catch (e, s) {
      debugPrint("❌ Error en el ChangeIsOkQuantity $e ->$s");
    }
  }

  //*metodo para cambiar la cantidad seleccionada
  void _onChangeQuantitySelectedEvent(
      ChangeQuantitySeparate event, Emitter<ClusterPickingState> emit) async {
    try {
      if (event.quantity > 0) {
        quantitySelected = event.quantity;
        await setClusterBatchProductFieldUseCase
            .call(SetClusterBatchProductFieldParams(
          batchId: currentBatch?.id ?? 0,
          productId: event.productId,
          field: 'quantity_separate',
          value: event.quantity,
          idMove: event.idMove,
          type: event.type,
        ));
      }
      emit(ChangeQuantitySeparateStateSuccess(quantitySelected));
    } catch (e, s) {
      emit(ChangeQuantitySeparateStateError('Error al separar cantidad'));
      debugPrint('❌ Error en ChangeQuantitySeparate: $e -> $s ');
    }
  }

  void _onChangeProductIsOkEvent(
      ChangeProductIsOkEvent event, Emitter<ClusterPickingState> emit) async {
    try {
      if (event.productIsOk) {
        //empezamos el tiempo de separacion del batch y del producto
        await setClusterBatchProductFieldUseCase
            .call(SetClusterBatchProductFieldParams(
          batchId: event.batchId,
          productId: event.productId,
          field: 'time_separate_start',
          value: DateTime.now().toString(),
          idMove: event.idMove,
          type: event.type,
        ));

        //calculamos la fecha de transaccion
        DateTime fechaTransaccion = DateTime.now();
        String fechaFormateada = formatoFecha(fechaTransaccion);
        //agregamos la fecha de transaccion
        await setClusterBatchProductFieldUseCase
            .call(SetClusterBatchProductFieldParams(
          batchId: event.batchId,
          productId: event.productId,
          field: 'fecha_transaccion',
          value: fechaFormateada,
          idMove: event.idMove,
          type: event.type,
        ));

        updateStateQuantity(
            event.productId, currentBatch?.id ?? 0, event.idMove, 1);

        quantityIsOk = true;

        await setClusterBatchProductFieldUseCase
            .call(SetClusterBatchProductFieldParams(
          batchId: currentBatch?.id ?? 0,
          productId: event.productId,
          field: 'is_selected',
          value: 1,
          idMove: event.idMove,
          type: event.type,
        ));

        await setClusterBatchProductFieldUseCase
            .call(SetClusterBatchProductFieldParams(
          batchId: currentBatch?.id ?? 0,
          productId: event.productId,
          field: 'product_is_ok',
          value: 1,
          idMove: event.idMove,
          type: event.type,
        ));
      }

      productIsOk = event.productIsOk;
      emit(ChangeProductIsOkState(
        productIsOk,
      ));
    } catch (e, s) {
      debugPrint("❌ Error en el ChangeProductIsOkEvent $e ->$s");
    }
  }

  //*evento para obtener los barcodes de un producto por paquete
  void _onFetchBarcodesProductEvent(FetchBarcodesProductEvent event,
      Emitter<ClusterPickingState> emit) async {
    try {
      final response = await getBarcodesProductUseCase.call(
        GetBarcodesProductParams(
          batchId: currentBatch?.id ?? 0,
          productId: currentProduct?.idProduct ?? 0,
          idMove: currentProduct?.idMove ?? 0,
          type: 'cluster',
        ),
      );

      response.fold(
        (failure) {
          debugPrint("❌ Error fetch barcodes from domain: ${failure.message}");
        },
        (barcodes) {
          listOfBarcodes = barcodes;
          debugPrint("listOfBarcodes: ${listOfBarcodes.length}");
        },
      );
    } catch (e, s) {
      debugPrint("❌ Error en _onFetchBarcodesProductEvent: $e, $s");
    }
    emit(BarcodesProductLoadedState(listOfBarcodes: listOfBarcodes));
  }

  void _onClearFieldsEvent(
      ClearFieldsEvent event, Emitter<ClusterPickingState> emit) {
    try {
      isLocationOk = true;
      isProductOk = true;
      isLocationDestOk = true;
      isQuantityOk = true;
      isLoteOk = true;
      viewQuantity = false;
      locationsDestIsOk = false;

      locationIsOk = false;
      productIsOk = false;
      locationDestIsOk = false;
      quantityIsOk = false;
      loteIsOk = false;
      locationsDestIsok = false;

      isProcessing = false;
      _isProcessing = false;

      quantitySelected = 0;
      oldLocation = '';
      index = 0;
      currentProduct = const BatchProduct();
      currentBatch = null;
      products = [];
      filteredProducts = [];
      listLotesProduct = [];
      listOfBarcodes = [];
      listLotesProductFilters = [];
      lotesProductCurrent = LoteProducto();
      emit(ClearFieldsState());
    } catch (e, s) {
      emit(ClearFieldsStateError('Error al limpiar los campos'));
      debugPrint("❌ Error en el ClearFieldsEvent $e ->$s");
    }
  }

  void _onChangeLocationIsOkEvent(
      ChangeLocationIsOkEvent event, Emitter<ClusterPickingState> emit) async {
    try {
      if (isLocationOk) {
        await setClusterBatchProductFieldUseCase
            .call(SetClusterBatchProductFieldParams(
          batchId: event.batchId,
          productId: event.productId,
          field: 'is_location_is_ok',
          value: 1,
          idMove: event.idMove,
          type: event.type,
        ));

        //cuando se lea la ubicacion se selecciona el batch
        await setClusterBatchFieldUseCase.call(SetClusterBatchFieldParams(
          batchId: event.batchId,
          field: 'is_selected',
          value: 1,
          type: event.type,
        ));

        locationIsOk = true;
        emit(ChangeLocationIsOkState());
      }
    } catch (e, s) {
      debugPrint("❌ Error en el ChangeLocationIsOkEvent $e ->$s");
    }
  }

  void _onValidateFieldsEvent(
      ValidateFieldsEvent event, Emitter<ClusterPickingState> emit) {
    try {
      switch (event.field) {
        case 'location':
          isLocationOk = event.isOk;
          if (event.isOk) locationIsOk = true;
          break;
        case 'product':
          isProductOk = event.isOk;
          if (event.isOk) productIsOk = true;
          break;
        case 'locationDest':
          isLocationDestOk = event.isOk;
          if (event.isOk) locationDestIsOk = true;
          break;
        case 'quantity':
          isQuantityOk = event.isOk;
          if (event.isOk) quantityIsOk = true;
          break;
        case 'lote':
          isLoteOk = event.isOk;
          if (event.isOk) loteIsOk = true;
          break;
      }
      emit(ValidateFieldsStateSuccess(event.isOk));
    } catch (e, s) {
      emit(ValidateFieldsStateError('Error al validar campos'));
      debugPrint("❌ Error en el ValidateFieldsEvent $e ->$s");
    }
  }

  Future<void> _onFetchPickingClusters(
    FetchPickingClustersEvent event,
    Emitter<ClusterPickingState> emit,
  ) async {
    emit(PickingClustersLoading());

    final result = await getPickingClusterData(NoParams());

    result.fold(
      (failure) => emit(PickingClustersError(failure.message)),
      (batches) {
        // Once data is successfully fetched via network and cached by the repository,
        // we load it into the state directly from the local cache.
        add(const LoadLocalPickingClustersEvent());
      },
    );
  }

  Future<void> _onLoadLocalPickingClusters(
    LoadLocalPickingClustersEvent event,
    Emitter<ClusterPickingState> emit,
  ) async {
    emit(PickingClustersLoading());

    final result = await getLocalPickingClusterData(NoParams());

    result.fold(
      (failure) => emit(PickingClustersError(failure.message)),
      (batches) => emit(PickingClustersLoaded(batches)),
    );
  }

  // evento para obtener los productos de un batch
  Future<void> _onFetchBatchProducts(
    FetchBatchProductsEvent event,
    Emitter<ClusterPickingState> emit,
  ) async {
    emit(BatchProductsLoading());

    try {
      // 1. Fetch products
      final resultProducts = await getLocalBatchProductsData(
          GetBatchProductsParams(batchId: event.batch.id!));

      currentBatch = event.batch;

      bool hasError = false;
      String errorMsg = '';

      resultProducts.fold(
        (failure) {
          hasError = true;
          errorMsg = failure.message;
        },
        (productsResult) {
          final sortedProducts = _sortProducts(event.batch, productsResult);
          products = sortedProducts;
          filteredProducts = List.from(sortedProducts);
        },
      );

      if (hasError) {
        emit(BatchProductsError(errorMsg));
        return;
      }

      // 2. Fetch configurations
      final resultConfig = await getUserConfiguration(NoParams());
      resultConfig.fold(
        (failure) {
          debugPrint('Error al cargar config: ${failure.message}');
        },
        (config) {
          configurations = _mapUserConfiguration(config);
        },
      );

      //3. Fetch novelties
      final resultNovelties = await getUserNovelties(NoParams());
      resultNovelties.fold(
        (failure) {
          debugPrint('Error al cargar novedades: ${failure.message}');
        },
        (novelties) {
          novedades = novelties;
        },
      );

      // El usuario solicitó específicamente que LoadCurrentProductEvent se mantenga separado.
      // Por ende, comentamos esta orquestación interna:
      // await _setAndLoadCurrentProductDetails();

      // 5. Emit Loaded
      emit(BatchProductsLoaded(
        event.batch,
        products,
      ));
    } catch (e, s) {
      debugPrint("❌ Error en _onFetchBatchProducts: $e -> $s");
      emit(BatchProductsError('Error al procesar el lote: $e'));
    }
  }

//metodo de ordenamiento de productos segun el batch
  List<BatchProduct> _sortProducts(
      PickingBatch batch, List<BatchProduct> products) {
    if (products.isEmpty) return products;

    final sortedProducts = List<BatchProduct>.from(products);

    switch (batch.orderBy) {
      case "removal_priority":
        if (batch.orderPicking == "asc") {
          sortedProducts.sort((a, b) =>
              (a.removalPriority ?? 0).compareTo(b.removalPriority ?? 0));
        } else {
          sortedProducts.sort((a, b) =>
              (b.removalPriority ?? 0).compareTo(a.removalPriority ?? 0));
        }
        break;
      case "location_name":
        if (batch.orderPicking == "asc") {
          sortedProducts.sort((a, b) => (a.locationId?.toString() ?? "")
              .compareTo(b.locationId?.toString() ?? ""));
        } else {
          sortedProducts.sort((a, b) => (b.locationId?.toString() ?? "")
              .compareTo(a.locationId?.toString() ?? ""));
        }
        break;
      case "product_name":
        if (batch.orderPicking == "asc") {
          sortedProducts.sort((a, b) => (a.productId?.toString() ?? "")
              .compareTo(b.productId?.toString() ?? ""));
        } else {
          sortedProducts.sort((a, b) => (b.productId?.toString() ?? "")
              .compareTo(a.productId?.toString() ?? ""));
        }
        break;
    }

    // Filtrar los productos con isPending == 1
    List<BatchProduct> pendingProducts =
        sortedProducts.where((product) => product.isPending == 1).toList();

    // Filtrar los productos que no están pendientes
    List<BatchProduct> nonPendingProducts =
        sortedProducts.where((product) => product.isPending != 1).toList();

    // Concatenar los productos no pendientes con los productos pendientes al final
    return [...nonPendingProducts, ...pendingProducts];
  }

  Future<void> _setAndLoadCurrentProductDetails() async {
    final separatedProducts =
        filteredProducts.where((p) => p.isSeparate == 0).toList();

    if (separatedProducts.isNotEmpty) {
      currentProduct = separatedProducts.first;
      if (currentProduct?.locationId == oldLocation) {
        locationIsOk = true;
      } else {
        locationIsOk = currentProduct?.isLocationIsOk == 1;
      }

      productIsOk = currentProduct?.productIsOk == 1;
      locationDestIsOk = currentProduct?.locationDestIsOk == 1;
      quantityIsOk = currentProduct?.isQuantityIsOk == 1;
      quantitySelected = currentProduct?.quantitySeparate ?? 0;
      _isProcessing = false;
    } else {
      currentProduct = null;
    }

    debugPrint(
        'currentProduct: idProduct=${currentProduct?.idProduct}, name=${currentProduct?.name}');

    listLotesProduct = [];
    listLotesProductFilters = [];

    if (currentProduct != null && currentProduct?.productTracking == "lot") {
      final productId = currentProduct?.idProduct ?? 0;
      final result = await getLotesProductoUseCase(
        GetLotesProductoParams(productId: productId),
      );

      result.fold(
        (failure) {
          debugPrint("Error cargando lotes: ${failure.message}");
        },
        (lotes) {
          listLotesProduct = lotes
              .map((lote) => LoteProducto(
                    id: lote.id,
                    name: lote.name,
                    quantity: lote.quantity,
                    expirationDate: lote.expirationDate,
                    productId: lote.productId,
                    productName: lote.productName,
                  ))
              .toList();
          listLotesProductFilters = List.from(listLotesProduct);
        },
      );
    }
  }

  Future<void> _onLoadCurrentProduct(
    LoadCurrentProductEvent event,
    Emitter<ClusterPickingState> emit,
  ) async {
    // Re-evaluar el current product si la capa visual lo pide de nuevo manualmente
    emit(ClusterPickingLoading());
    await _setAndLoadCurrentProductDetails();
    if (state is BatchProductsLoaded) {
      final st = state as BatchProductsLoaded;
      add(FetchBarcodesProductEvent());
      emit(BatchProductsLoaded(st.batch, products));
    } else if (state is PickingClustersLoaded) {
      // no sobreescribir ClustersLoaded a BatchProductsLoaded
    }
  }

  void _onLoadConfigurationsUserEvent(
    LoadConfigurationsUserEvent event,
    Emitter<ClusterPickingState> emit,
  ) async {
    try {
      final result = await getUserConfiguration(NoParams());

      result.fold(
        (failure) {
          emit(ConfigurationError(failure.message));
        },
        (config) {
          final mappedConfig = _mapUserConfiguration(config);
          configurations = mappedConfig;

          if (state is BatchProductsLoaded) {
            // No pisar el BatchProductsLoaded con ConfigurationPickingLoaded
          } else if (state is PickingClustersLoaded) {
            // No overwrite
          } else if (state is BatchProductsLoading ||
              state is PickingClustersLoading) {
            // Do not interrupt loaders
          } else {
            emit(ConfigurationPickingLoaded(mappedConfig));
          }
        },
      );
    } catch (e, s) {
      debugPrint('❌ Error en LoadConfigurationsUser $e =>$s');
      emit(ConfigurationError('Error al cargar LoadConfigurationsUser: $e'));
    }
  }

  UserConfigurationModel _mapUserConfiguration(dynamic config) {
    if (config.result == null) return UserConfigurationModel();
    return UserConfigurationModel(
      result: UserConfigurationResultModel(
        code: config.result?.code,
        msg: config.result?.msg,
        result: config.result?.result != null
            ? UserProfileModel(
                id: config.result?.result?.id,
                name: config.result?.result?.name,
                email: config.result?.result?.email,
                lastName: config.result?.result?.lastName,
                rol: config.result?.result?.rol,
                muelleOption: config.result?.result?.muelleOption,
                accessProductionModule:
                    config.result?.result?.accessProductionModule,
                allowMoveExcessProduction:
                    config.result?.result?.allowMoveExcessProduction,
                hideValidatePicking: config.result?.result?.hideValidatePicking,
                locationPickingManual:
                    config.result?.result?.locationPickingManual,
                manualProductSelection:
                    config.result?.result?.manualProductSelection,
                manualQuantity: config.result?.result?.manualQuantity,
                manualSpringSelection:
                    config.result?.result?.manualSpringSelection,
                allowedWarehouses: config.result?.result?.allowedWarehouses,
                showDetallesPicking: config.result?.result?.showDetallesPicking,
                showNextLocationsInDetails:
                    config.result?.result?.showNextLocationsInDetails,
                locationPackManual: config.result?.result?.locationPackManual,
                showDetallesPack: config.result?.result?.showDetallesPack,
                showNextLocationsInDetailsPack:
                    config.result?.result?.showNextLocationsInDetailsPack,
                manualProductSelectionPack:
                    config.result?.result?.manualProductSelectionPack,
                manualQuantityPack: config.result?.result?.manualQuantityPack,
                manualSpringSelectionPack:
                    config.result?.result?.manualSpringSelectionPack,
                scanProduct: config.result?.result?.scanProduct,
                allowMoveExcess: config.result?.result?.allowMoveExcess,
                hideExpectedQty: config.result?.result?.hideExpectedQty,
                manualProductReading:
                    config.result?.result?.manualProductReading,
                manualSourceLocation:
                    config.result?.result?.manualSourceLocation,
                showOwnerField: config.result?.result?.showOwnerField,
                manualProductSelectionTransfer:
                    config.result?.result?.manualProductSelectionTransfer,
                manualSourceLocationTransfer:
                    config.result?.result?.manualSourceLocationTransfer,
                manualDestLocationTransfer:
                    config.result?.result?.manualDestLocationTransfer,
                manualQuantityTransfer:
                    config.result?.result?.manualQuantityTransfer,
                countQuantityInventory:
                    config.result?.result?.countQuantityInventory,
                hideValidateTransfer:
                    config.result?.result?.hideValidateTransfer,
                hideValidateReception:
                    config.result?.result?.hideValidateReception,
                hideValidatePacking: config.result?.result?.hideValidatePacking,
                updateItemInventory: config.result?.result?.updateItemInventory,
                scanDestinationLocationReception:
                    config.result?.result?.scanDestinationLocationReception,
                updateLocationInventory:
                    config.result?.result?.updateLocationInventory,
                showPhotoTemperature:
                    config.result?.result?.showPhotoTemperature,
                returnsLocationDestOption:
                    config.result?.result?.returnsLocationDestOption,
                locationManualInventory:
                    config.result?.result?.locationManualInventory,
                manualProductSelectionInventory:
                    config.result?.result?.manualProductSelectionInventory,
              )
            : null,
      ),
    );
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
      debugPrint("❌ Error en el formatSecondsToHHMMSS $e ->$s");
      return "";
    }
  }
}
