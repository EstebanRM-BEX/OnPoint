// ignore_for_file: prefer_is_empty
// This bloc refactors the scan module of PickingPickBloc to Clean Architecture.
// It delegates I/O operations to use cases from features/picking/domain/usecases/.
// UI handlers (no I/O) are kept unchanged.

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/features/picking/domain/usecases/assign_muelle_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/get_barcodes_product_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/get_muelles_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/get_products_for_edit_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/get_product_image_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/get_scan_pick_with_products_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/increment_quantity_separate_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/mark_location_dest_ok_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/mark_location_ok_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/mark_pick_as_done_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/mark_product_ok_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/mark_quantity_ok_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/record_pick_time_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/send_product_to_odoo_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/update_quantity_separate_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/validate_confirm_pick_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/validate_transfer_usecase.dart';
import 'package:wms_app/features/user/data/models/user_configuration_model.dart';
import 'package:wms_app/features/user/domain/entities/user_novelty.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/submeuelle_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/PickhWithProducts_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/response_pick_model.dart';

part 'pick_scan_event.dart';
part 'pick_scan_state.dart';

/// Clean-Architecture refactor del scan de PickingPickBloc.
///
/// - UI-pure handlers delegate only to in-memory state (no I/O).
/// - SQLite handlers use the corresponding use case.
/// - Odoo handlers use the corresponding use case.
/// - Mixed handlers compose multiple use cases.
///
/// The existing PickingPickBloc is kept as-is; the screen can be migrated
/// to this new bloc progressively.
@injectable
class PickScanBloc extends Bloc<PickScanEvent, PickScanState> {
  // ── Use cases ─────────────────────────────────────────────────────────────
  final MarkLocationOkUseCase markLocationOkUseCase;
  final MarkLocationDestOkUseCase markLocationDestOkUseCase;
  final MarkProductOkUseCase markProductOkUseCase;
  final MarkQuantityOkUseCase markQuantityOkUseCase;
  final UpdateQuantitySeparateUseCase updateQuantitySeparateUseCase;
  final IncrementQuantitySeparateUseCase incrementQuantitySeparateUseCase;
  final GetScanPickWithProductsUseCase getScanPickWithProductsUseCase;
  final GetBarcodesProductUseCase getBarcodesProductUseCase;
  final GetProductsForEditUseCase getProductsForEditUseCase;
  final GetMuellesUseCase getMuellesUseCase;
  final GetProductImageUseCase getProductImageUseCase;
  final ValidateConfirmPickUseCase validateConfirmPickUseCase;
  final ValidateTransferUseCase validateTransferUseCase;
  final MarkPickAsDoneUseCase markPickAsDoneUseCase;
  final RecordPickTimeUseCase recordPickTimeUseCase;
  final SendProductToOdooUseCase sendProductToOdooUseCase;
  final AssignMuelleUseCase assignMuelleUseCase;

  // ── In-memory state (same as original PickingPickBloc scan section) ──────

  List<ResultPick> listOfPick = [];
  List<ResultPick> listOfPickFiltered = [];
  List<ResultPick> historyPicks = [];
  List<ResultPick> filtersHistoryPicks = [];
  // historyPickId gestionado por PickingListBloc
  List<ResultPick> listOfPickCompo = [];
  List<ResultPick> listOfPickCompoFiltered = [];

  List<ProductsBatch> filteredProducts = [];
  List<ProductsBatch> listProducts = [];
  List<String> listOfProductsName = [];
  List<Barcodes> listOfBarcodes = [];

  List<String> muelles = [];
  List<Muelles> submuelles = [];
  Muelles subMuelleSelected = Muelles();

  PickWithProducts pickWithProducts = PickWithProducts();
  ProductsBatch currentProduct = ProductsBatch();

  TextEditingController searchController = TextEditingController();
  TextEditingController searchPickController = TextEditingController();
  TextEditingController editProductController = TextEditingController();

  List<Novedad> novedades = [];
  List<String> positionsOrigen = [];
  String oldLocation = '';

  bool locationIsOk = false;
  bool productIsOk = false;
  bool locationDestIsOk = false;
  bool quantityIsOk = false;

  bool isSearch = true;
  String scannedValue1 = '';
  String scannedValue2 = '';
  String scannedValue3 = '';
  String scannedValue4 = '';
  String scannedValue5 = '';
  String selectedNovedad = '';

  bool isLocationOk = true;
  bool isProductOk = true;
  bool isLocationDestOk = true;
  bool isQuantityOk = true;

  UserConfigurationModel configurations = UserConfigurationModel();

  dynamic quantitySelected = 0;
  int index = 0;
  bool isProcessing = false;
  bool viewQuantity = false;
  String currentFilterKey = 'priority_high';

  PickScanBloc({
    required this.markLocationOkUseCase,
    required this.markLocationDestOkUseCase,
    required this.markProductOkUseCase,
    required this.markQuantityOkUseCase,
    required this.updateQuantitySeparateUseCase,
    required this.incrementQuantitySeparateUseCase,
    required this.getScanPickWithProductsUseCase,
    required this.getBarcodesProductUseCase,
    required this.getProductsForEditUseCase,
    required this.getMuellesUseCase,
    required this.getProductImageUseCase,
    required this.validateConfirmPickUseCase,
    required this.validateTransferUseCase,
    required this.markPickAsDoneUseCase,
    required this.recordPickTimeUseCase,
    required this.sendProductToOdooUseCase,
    required this.assignMuelleUseCase,
  }) : super(PickScanInitial()) {
    // ── UI puro ────────────────────────────────────────────────────────────
    on<ValidateFieldsEvent>(_onValidateFields);
    on<ShowQuantityEvent>(_onShowQuantityEvent);
    on<SetIsProcessingEvent>(_onSetIsProcessingEvent);
    on<SelectedSubMuelleEvent>(_onSelectecSubMuelle);
    on<SelectNovedadEvent>(_onSelectNovedadEvent);

    // ── SQLite ─────────────────────────────────────────────────────────────
    on<ChangeLocationIsOkEvent>(_onChangeLocationIsOkEvent);
    on<ChangeLocationDestIsOkEvent>(_onChangeLocationDestIsOkEvent);
    on<ChangeProductIsOkEvent>(_onChangeProductIsOkEvent);
    on<ChangeIsOkQuantity>(_onChangeQuantityIsOkEvent);
    on<ChangeQuantitySeparate>(_onChangeQuantitySelectedEvent);
    on<AddQuantitySeparate>(_onAddQuantitySeparateEvent);
    on<FetchPickWithProductsEvent>(_onFetchPickWithProductsEvent);
    on<FetchBarcodesProductEvent>(_onFetchBarcodesProductEvent);
    // LoadDataInfo se ejecuta internamente desde FetchPickWithProductsEvent
    on<LoadProductEditEvent>(_onEditProductEvent);
    on<PickingOkEvent>(_onPickingOkEvent);

    // ── Odoo API ───────────────────────────────────────────────────────────
    on<FetchMuellesEvent>(_onFetchMuellesEvent);
    on<ViewProductImageEvent>(_onViewProductImageEvent);
    on<ValidateConfirmEvent>(_onValidateConfirmEvent);
    on<CreateBackOrderOrNot>(_onCreateBackOrder);

    // ── Mixto ──────────────────────────────────────────────────────────────
    on<ChangeCurrentProduct>(_onChangeCurrentProduct);
    on<AssignSubmuelleEvent>(_onAssignSubmuelleEvent);
    on<StartOrStopTimeTransfer>(_onStartOrStopTimeTransfer);
    on<PickOkEvent>(_onPickOkEvent);
  }

  @override
  Future<void> close() {
    searchController.dispose();
    searchPickController.dispose();
    editProductController.dispose();
    return super.close();
  }

  // ── UI puro ──────────────────────────────────────────────────────────────

  void _onValidateFields(
      ValidateFieldsEvent event, Emitter<PickScanState> emit) {
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
      debugPrint("❌ Error en ValidateFieldsEvent $e ->$s");
    }
  }

  void _onShowQuantityEvent(
      ShowQuantityEvent event, Emitter<PickScanState> emit) {
    try {
      viewQuantity = !viewQuantity;
      emit(ShowQuantityState(viewQuantity));
    } catch (e, s) {
      debugPrint("❌ Error en _onShowQuantityEvent: $e, $s");
    }
  }

  void _onSetIsProcessingEvent(
      SetIsProcessingEvent event, Emitter<PickScanState> emit) {
    try {
      isProcessing = event.isProcessing;
      emit(SetIsProcessingState(isProcessing));
    } catch (e, s) {
      debugPrint("❌ Error en _onSetIsProcessingEvent: $e, $s");
    }
  }

  void _onSelectecSubMuelle(
      SelectedSubMuelleEvent event, Emitter<PickScanState> emit) {
    try {
      subMuelleSelected = Muelles();
      subMuelleSelected = event.subMuelleSlected;
      emit(SelectSubMuelle(subMuelleSelected));
    } catch (e, s) {
      debugPrint("❌ Error bloc selectedSubMuelle $e -> $s");
    }
  }

  void _onSelectNovedadEvent(
      SelectNovedadEvent event, Emitter<PickScanState> emit) {
    try {
      selectedNovedad = event.novedad;
      emit(SelectNovedadStateSuccess(event.novedad));
    } catch (e, s) {
      emit(SelectNovedadStateError('Error al seleccionar novedad'));
      debugPrint('❌ Error en el SelectNovedadEvent $e ->$s');
    }
  }

  // ── SQLite ────────────────────────────────────────────────────────────────

  void _onChangeLocationIsOkEvent(
      ChangeLocationIsOkEvent event, Emitter<PickScanState> emit) async {
    try {
      if (isLocationOk) {
        final result = await markLocationOkUseCase(MarkLocationOkParams(
            batchId: event.batchId,
            productId: event.productId,
            idMove: event.idMove));
        result.fold(
          (failure) => debugPrint(
              "❌ Error en markLocationOk: ${failure.message}"),
          (_) {
            locationIsOk = true;
            currentProduct.isLocationIsOk = 1;
            emit(ChangeLocationIsOkState(locationIsOk));
          },
        );
      }
    } catch (e, s) {
      debugPrint("❌ Error en ChangeLocationIsOkEvent $e ->$s");
    }
  }

  void _onChangeLocationDestIsOkEvent(ChangeLocationDestIsOkEvent event,
      Emitter<PickScanState> emit) async {
    try {
      final result = await markLocationDestOkUseCase(MarkLocationDestOkParams(
          batchId: event.batchId,
          productId: event.productId,
          idMove: event.idMove,
          isOk: event.locationDestIsOk));
      result.fold(
        (failure) => debugPrint(
            "❌ Error en markLocationDestOk: ${failure.message}"),
        (_) {
          locationDestIsOk = event.locationDestIsOk;
          currentProduct.locationDestIsOk = event.locationDestIsOk ? 1 : 0;
          emit(ChangeLocationDestIsOkState(locationDestIsOk));
        },
      );
    } catch (e, s) {
      debugPrint("❌ Error en ChangeLocationDestIsOkEvent $e ->$s");
    }
  }

  void _onChangeProductIsOkEvent(
      ChangeProductIsOkEvent event, Emitter<PickScanState> emit) async {
    try {
      if (event.productIsOk) {
        final result = await markProductOkUseCase(MarkProductOkParams(
            batchId: event.batchId,
            productId: event.productId,
            idMove: event.idMove));
        result.fold(
          (failure) =>
              debugPrint("❌ Error en markProductOk: ${failure.message}"),
          (_) => null,
        );
        quantityIsOk = event.productIsOk;
        currentProduct.isQuantityIsOk = 1;
      }
      productIsOk = event.productIsOk;
      currentProduct.productIsOk = event.productIsOk ? 1 : 0;
      emit(ChangeProductIsOkState(productIsOk));
    } catch (e, s) {
      debugPrint("❌ Error en ChangeProductIsOkEvent $e ->$s");
    }
  }

  void _onChangeQuantityIsOkEvent(
      ChangeIsOkQuantity event, Emitter<PickScanState> emit) async {
    try {
      final result = await markQuantityOkUseCase(MarkQuantityOkParams(
          batchId: event.batchId,
          productId: event.productId,
          idMove: event.idMove,
          isOk: event.isOk));
      result.fold(
        (failure) =>
            debugPrint("❌ Error en markQuantityOk: ${failure.message}"),
        (_) => null,
      );
      quantityIsOk = event.isOk;
      currentProduct.isQuantityIsOk = event.isOk ? 1 : 0;
      emit(ChangeQuantityIsOkState(quantityIsOk));
    } catch (e, s) {
      debugPrint("❌ Error en ChangeIsOkQuantity $e ->$s");
    }
  }

  void _onChangeQuantitySelectedEvent(
      ChangeQuantitySeparate event, Emitter<PickScanState> emit) async {
    try {
      if (event.quantity > 0) {
        quantitySelected = event.quantity;
        final result = await updateQuantitySeparateUseCase(UpdateQuantityParams(
            pickId: pickWithProducts.pick?.id ?? 0,
            productId: event.productId,
            idMove: event.idMove,
            quantity: event.quantity));
        result.fold(
          (failure) => debugPrint(
              "❌ Error en updateQuantitySeparate: ${failure.message}"),
          (_) => null,
        );
      }
      emit(ChangeQuantitySeparateStateSuccess(quantitySelected));
    } catch (e, s) {
      emit(ChangeQuantitySeparateStateError('Error al separar cantidad'));
      debugPrint('❌ Error en ChangeQuantitySeparate: $e -> $s');
    }
  }

  void _onAddQuantitySeparateEvent(
      AddQuantitySeparate event, Emitter<PickScanState> emit) async {
    try {
      if (quantitySelected > (currentProduct.quantity ?? 0)) {
        return;
      }
      quantitySelected = quantitySelected + event.quantity;
      final result = await incrementQuantitySeparateUseCase(
          IncrementQuantityParams(
              pickId: pickWithProducts.pick?.id ?? 0,
              productId: event.productId,
              idMove: event.idMove,
              quantity: event.quantity));
      result.fold(
        (failure) => debugPrint(
            "❌ Error en incrementQuantitySeparate: ${failure.message}"),
        (_) => null,
      );
      emit(ChangeQuantitySeparateStateSuccess(quantitySelected));
    } catch (e, s) {
      emit(ChangeQuantitySeparateStateError('Error al aumentar cantidad'));
      debugPrint("❌ Error en AddQuantitySeparate $e ->$s");
    }
  }

  void _onFetchPickWithProductsEvent(
      FetchPickWithProductsEvent event, Emitter<PickScanState> emit) async {
    try {
      debugPrint('Fetching pick with ID: ${event.pickId}');
      pickWithProducts = PickWithProducts();

      final result = await getScanPickWithProductsUseCase(
          GetScanPickWithProductsParams(pickId: event.pickId));

      result.fold(
        (failure) {
          pickWithProducts = PickWithProducts();
          emit(EmptyProductsPick());
          debugPrint('❌ Error getPickWithProducts: ${failure.message}');
        },
        (response) {
          pickWithProducts = response;

          if (pickWithProducts.products!.isEmpty) {
            emit(EmptyProductsPick());
            return;
          }

          listProducts.clear();
          listProducts.addAll(pickWithProducts.products!);
          filteredProducts.clear();
          filteredProducts.addAll(pickWithProducts.products!);

          sortProductsByLocationId();
          _loadDataInfo();
          _products();
          _getPosicions();
          add(FetchBarcodesProductEvent());

          emit(LoadProductsBatchSuccesStateBD(
              listOfProductsBatch: filteredProducts));
        },
      );
    } catch (e, s) {
      debugPrint("❌ Error en FetchPickWithProductsEvent $e ->$s");
    }
  }

  void _onFetchBarcodesProductEvent(
      FetchBarcodesProductEvent event, Emitter<PickScanState> emit) async {
    try {
      listOfBarcodes.clear();
      final result = await getBarcodesProductUseCase(GetBarcodesProductParams(
          pickId: pickWithProducts.pick?.id ?? 0,
          productId: currentProduct.idProduct ?? 0,
          idMove: currentProduct.idMove ?? 0));

      result.fold(
        (failure) =>
            debugPrint("❌ Error getBarcodesProduct: ${failure.message}"),
        (barcodes) {
          listOfBarcodes = barcodes;
          debugPrint("listOfBarcodes: ${listOfBarcodes.length}");
        },
      );
      emit(BarcodesProductLoadedState(listOfBarcodes: listOfBarcodes));
    } catch (e, s) {
      debugPrint("❌ Error en _onFetchBarcodesProductEvent: $e, $s");
    }
  }

  void _onEditProductEvent(
      LoadProductEditEvent event, Emitter<PickScanState> emit) async {
    try {
      final result = await getProductsForEditUseCase(
          GetProductsForEditParams(pickId: pickWithProducts.pick?.id ?? 0));

      result.fold(
        (failure) {
          debugPrint("❌ Error getProductsForEdit: ${failure.message}");
          emit(LoadProductsBatchSuccesStateBD(listOfProductsBatch: []));
        },
        (products) {
          if (products.isEmpty) {
            emit(LoadProductsBatchSuccesStateBD(listOfProductsBatch: []));
            return;
          }
          filteredProducts.clear();
          filteredProducts.addAll(products);
          emit(LoadProductsBatchSuccesStateBD(
              listOfProductsBatch: filteredProducts));
        },
      );
    } catch (e, s) {
      debugPrint("❌ Error en _onEditProductEvent: $e -> $s");
    }
  }

  void _onPickingOkEvent(
      PickingOkEvent event, Emitter<PickScanState> emit) async {
    try {
      emit(PickingOkLoading());
      final result =
          await markPickAsDoneUseCase(MarkPickAsDoneParams(pickId: event.batchId));
      result.fold(
        (failure) {
          emit(PickingOkError());
          debugPrint("❌ Error markPickAsDone: ${failure.message}");
        },
        (_) => emit(PickingOkState()),
      );
    } catch (e, s) {
      emit(PickingOkError());
      debugPrint("❌ Error en PickingOkEvent $e -> $s");
    }
  }

  // ── Odoo API ─────────────────────────────────────────────────────────────

  void _onFetchMuellesEvent(
      FetchMuellesEvent event, Emitter<PickScanState> emit) async {
    try {
      emit(MuellesLoadingState());
      submuelles.clear();

      final result = await getMuellesUseCase(GetMuellesParams(
          muelleId: pickWithProducts.pick?.muelleId ?? 0));

      result.fold(
        (failure) {
          emit(MuellesErrorState(failure.message));
        },
        (list) {
          submuelles = list;
          debugPrint("submuelles: ${submuelles.length}");
          emit(MuellesLoadedState(listOfMuelles: submuelles));
        },
      );
    } catch (e, s) {
      emit(MuellesErrorState('Error al cargar los muelles'));
      debugPrint("❌ Error en _onFetchMuellesEvent: $e, $s");
    }
  }

  void _onViewProductImageEvent(
      ViewProductImageEvent event, Emitter<PickScanState> emit) async {
    try {
      emit(ViewProductImageLoading());
      final result = await getProductImageUseCase(
          GetProductImageParams(productId: event.idProduct));

      result.fold(
        (failure) => emit(ViewProductImageFailure(failure.message)),
        (url) => emit(ViewProductImageSuccess(url)),
      );
    } catch (e, s) {
      emit(ViewProductImageFailure(e.toString()));
      debugPrint('❌ Error en ViewProductImageEvent: $e, $s');
    }
  }

  void _onValidateConfirmEvent(
      ValidateConfirmEvent event, Emitter<PickScanState> emit) async {
    try {
      emit(ValidateConfirmLoading());
      final result = await validateConfirmPickUseCase(ValidateConfirmPickParams(
          pickId: event.idPick, isBackOrder: event.isBackOrder));

      result.fold(
        (failure) => emit(ValidateConfirmFailure(failure.message)),
        (msg) {
          add(PickingOkEvent(
              pickWithProducts.pick?.id ?? 0, currentProduct.idProduct ?? 0));
          emit(ValidateConfirmSuccess(event.isBackOrder, msg));
        },
      );
    } catch (e, s) {
      emit(ValidateConfirmFailure('Error al validar la confirmacion'));
      debugPrint('❌ Error en _onValidateConfirmEvent: $e, $s');
    }
  }

  void _onCreateBackOrder(
      CreateBackOrderOrNot event, Emitter<PickScanState> emit) async {
    try {
      emit(CreateBackOrderOrNotLoading());

      final result = await validateTransferUseCase(ValidateTransferParams(
          pickId: event.idPick, isBackOrder: event.isBackOrder));

      result.fold(
        (failure) => emit(CreateBackOrderOrNotFailure(
            failure.message, event.isBackOrder)),
        (msg) {
          add(StartOrStopTimeTransfer(event.idPick, 'end_time_transfer'));

          if (event.isExternalProduct == true) {
            // Historial gestionado por PickingListBloc al navegar de vuelta
          } else {
            add(ValidateFieldsEvent(field: "locationDest", isOk: true));
            add(ChangeLocationDestIsOkEvent(true, currentProduct.idProduct ?? 0,
                pickWithProducts.pick?.id ?? 0, currentProduct.idMove ?? 0));
            isSearch = true;
            add(PickingOkEvent(
                pickWithProducts.pick?.id ?? 0, currentProduct.idProduct ?? 0));
            // Remove pick from local DB
            final db = DataBaseSqlite();
            db.pickRepository.deletePickById(event.idPick);
            listOfPick.removeWhere((pick) => pick.id == event.idPick);
            listOfPickFiltered.removeWhere((pick) => pick.id == event.idPick);
            // La lista de picks se refresca desde PickingListBloc al volver
          }

          emit(CreateBackOrderOrNotSuccess(event.isBackOrder, msg));
        },
      );
    } catch (e, s) {
      emit(CreateBackOrderOrNotFailure(
          'Error al crear la backorder', event.isBackOrder));
      debugPrint('❌ Error en _onCreateBackOrder: $e, $s');
    }
  }

  // ── Mixto ─────────────────────────────────────────────────────────────────

  void _onChangeCurrentProduct(
      ChangeCurrentProduct event, Emitter<PickScanState> emit) async {
    try {
      viewQuantity = false;
      emit(CurrentProductChangedStateLoading());

      // 1. Pre-send local DB operations (time/mark)
      final db = DataBaseSqlite();
      await db.pickProductsRepository.setFieldTablePickProducts(
          pickWithProducts.pick?.id ?? 0,
          event.currentProduct.idProduct ?? 0,
          'is_selected',
          0,
          currentProduct.idMove ?? 0);

      final dateTimeActuality = DateTime.parse(DateTime.now().toString());
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

      final dateTimeStart = (starTimeProduct == "null" || starTimeProduct.isEmpty)
          ? DateTime.parse(DateTime.now().toString())
          : DateTime.parse(starTimeProduct);

      final diff = dateTimeActuality.difference(dateTimeStart);
      final seconds = diff.inMilliseconds / 1000.0;

      await db.pickProductsRepository.totalStopwatchProduct(
          pickWithProducts.pick?.id ?? 0,
          currentProduct.idProduct ?? 0,
          currentProduct.idMove ?? 0,
          seconds);

      // 2. Send to Odoo via use case
      final sendResult = await sendProductToOdooUseCase(SendProductParams(
          pickId: pickWithProducts.pick?.id ?? 0,
          productId: currentProduct.idProduct ?? 0,
          idMove: currentProduct.idMove ?? 0,
          currentBatchId: currentProduct.batchId ?? 0));

      final odooResult = sendResult.fold((failure) => null, (r) => r);

      if (odooResult == null || !odooResult.success) {
        emit(SendProductPickOdooError(
            odooResult?.message ?? 'Error al enviar a Odoo'));
        return;
      }

      // 3. Find next product
      // Exclude the processed product from in-memory lists immediately.
      // isSeparate is final so we can't mutate it; DB already has is_separate=1.
      filteredProducts.removeWhere(
          (p) => p.idProduct == event.currentProduct.idProduct &&
              p.idMove == event.currentProduct.idMove);
      listProducts.removeWhere(
          (p) => p.idProduct == event.currentProduct.idProduct &&
              p.idMove == event.currentProduct.idMove);

      final nextProducts =
          filteredProducts.where((p) => p.isSeparate == 0).toList();

      if (nextProducts.isNotEmpty) {
        productIsOk = false;
        quantityIsOk = false;
        currentProduct = nextProducts.first;
        locationIsOk = (currentProduct.locationId == oldLocation);

        await db.pickProductsRepository.startStopwatch(
          pickWithProducts.pick?.id ?? 0,
          currentProduct.idProduct ?? 0,
          currentProduct.idMove ?? 0,
          DateTime.now().toString(),
        );
      }

      emit(CurrentProductChangedState(currentProduct: currentProduct));
      add(FetchPickWithProductsEvent(pickWithProducts.pick?.id ?? 0));
    } catch (e, s) {
      emit(CurrentProductChangedStateError(
          'Error crítico al procesar el cambio de producto.'));
      debugPrint("❌ Error en ChangeCurrentProduct $e ->$s");
    }
  }

  void _onAssignSubmuelleEvent(
      AssignSubmuelleEvent event, Emitter<PickScanState> emit) async {
    try {
      final result = await assignMuelleUseCase(AssignMuelleParams(
          products: event.productsSeparate,
          muelle: event.muelle,
          isOccupied: event.isOccupied,
          currentBatchId: currentProduct.batchId ?? 0));

      result.fold(
        (failure) => emit(SubMuelleEditFail(failure.message)),
        (msg) {
          add(FetchPickWithProductsEvent(
              event.productsSeparate.first.batchId ?? 0));
          emit(SubMuelleEditSusses(
              '(${event.productsSeparate.length}) productos agregados al submuelle:\n'
              '${event.muelle.completeName}\n'
              'correctamente'));
        },
      );
    } catch (e, s) {
      emit(SubMuelleEditFail('Error al asignar el submuelle'));
      debugPrint("❌ Error en AssignSubmuelleEvent $e ->$s");
    }
  }

  void _onStartOrStopTimeTransfer(
      StartOrStopTimeTransfer event, Emitter<PickScanState> emit) async {
    try {
      final result = await recordPickTimeUseCase(
          RecordPickTimeParams(pickId: event.id, timeType: event.value));

      result.fold(
        (failure) =>
            emit(StartOrStopTimeTransferFailure(failure.message)),
        (_) => emit(StartOrStopTimeTransferSuccess(event.value)),
      );
    } catch (e, s) {
      debugPrint('❌ Error en _onStartOrStopTimeTransfer: $e, $s');
    }
  }

  void _onPickOkEvent(PickOkEvent event, Emitter<PickScanState> emit) async {
    try {
      emit(CreateBackOrderOrNotLoading());

      add(StartOrStopTimeTransfer(event.idPick, 'end_time_transfer'));
      add(ValidateFieldsEvent(field: "locationDest", isOk: true));
      add(ChangeLocationDestIsOkEvent(true, currentProduct.idProduct ?? 0,
          pickWithProducts.pick?.id ?? 0, currentProduct.idMove ?? 0));
      isSearch = true;

      add(PickingOkEvent(
          pickWithProducts.pick?.id ?? 0, currentProduct.idProduct ?? 0));
      // La lista de picks se refresca desde PickingListBloc al volver

      emit(PickOkEventSuccess('Pick cerrado correctamente'));
    } catch (e, s) {
      emit(CreateBackOrderOrNotFailure('Error al cerrar el pick', false));
      debugPrint('❌ Error en _onPickOkEvent: $e, $s');
    }
  }

  // ── Helpers públicos (llamados desde la screen) ───────────────────────────

  /// Ordena los productos por locationId según el orden configurado en el pick.
  Future<List<ProductsBatch>> sortProductsByLocationId() async {
    try {
      final products = filteredProducts;
      final batch = pickWithProducts.pick;

      final db = DataBaseSqlite();
      final batchUpdated =
          await db.pickRepository.getPickById(batch?.id ?? 0);

      switch (batchUpdated?.orderBy) {
        case "removal_priority":
          if (batchUpdated?.orderPicking == "asc") {
            products
                .sort((a, b) => a.rimovalPriority!.compareTo(b.rimovalPriority!));
          } else {
            products
                .sort((a, b) => b.rimovalPriority!.compareTo(a.rimovalPriority!));
          }
          break;
        case "location_name":
          if (batchUpdated?.orderPicking == "asc") {
            products.sort((a, b) => a.locationId!.compareTo(b.locationId!));
          } else {
            products.sort((a, b) => b.locationId!.compareTo(a.locationId!));
          }
          break;
        case "product_name":
          if (batchUpdated?.orderPicking == "asc") {
            products.sort((a, b) => a.productId!.compareTo(b.productId!));
          } else {
            products.sort((a, b) => b.productId!.compareTo(a.productId!));
          }
          break;
      }

      final pendingProducts =
          products.where((p) => p.isPending == 1).toList();
      final nonPendingProducts =
          products.where((p) => p.isPending != 1).toList();

      filteredProducts.clear();
      filteredProducts.addAll(nonPendingProducts);
      filteredProducts.addAll(pendingProducts);

      return filteredProducts;
    } catch (e, s) {
      debugPrint("❌ Error en sortProductsByLocationId $e ->$s");
      return [];
    }
  }

  /// Calcula el porcentaje de unidades separadas sobre el total pedido.
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
        totalCantidades += (product.quantity) ?? 0;
      }
      if (totalCantidades == 0) return "0.0";
      final progress = (totalSeparadas / totalCantidades) * 100;
      return progress.toStringAsFixed(2);
    } catch (e, s) {
      debugPrint("❌ Error en calcularUnidadesSeparadas $e ->$s");
      return '';
    }
  }

  // ── Helpers privados ──────────────────────────────────────────────────────

  void _loadDataInfo() {
    try {
      final separatedProducts =
          filteredProducts.where((p) => p.isSeparate == 0).toList();

      if (separatedProducts.isNotEmpty) {
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
        locationDestIsOk =
            currentProduct.locationDestIsOk == 1 ? true : false;
        quantityIsOk = currentProduct.isQuantityIsOk == 1 ? true : false;
        index = pickWithProducts.pick?.indexList ?? 0;
        quantitySelected = currentProduct.quantitySeparate ?? 0;
      }
    } catch (e, s) {
      debugPrint("❌ Error en _loadDataInfo $e ->$s");
    }
  }

  void _products() {
    try {
      Set<String> productIdsSet = {};
      for (var product in filteredProducts) {
        if (product.productId != null) {
          productIdsSet.add(product.productId.toString());
        }
      }
      listOfProductsName = productIdsSet.toList();
    } catch (e, s) {
      debugPrint("❌ Error en _products $e ->$s");
    }
  }

  void _getPosicions() {
    try {
      Set<String> positionsSet = {};
      for (var product in filteredProducts) {
        final locationId = product.locationId ?? '';
        if (locationId.isNotEmpty) {
          positionsSet.add(locationId);
        }
      }
      positionsOrigen = positionsSet.toList();
    } catch (e, s) {
      debugPrint("❌ Error en _getPosicions: $e -> $s");
    }
  }
}
