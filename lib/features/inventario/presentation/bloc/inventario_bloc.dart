// lib/features/inventario/presentation/bloc/inventario_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/inventario/domain/entities/barcode_producto.dart';
import 'package:wms_app/features/inventario/domain/entities/lote_producto_inventario.dart';
import 'package:wms_app/features/inventario/domain/entities/producto_inventario.dart';
import 'package:wms_app/features/inventario/domain/entities/ubicacion_inventario.dart';
import 'package:wms_app/features/inventario/domain/usecases/crear_lote_inventario.dart';
import 'package:wms_app/features/inventario/domain/usecases/enviar_producto_inventario.dart';
import 'package:wms_app/features/inventario/domain/usecases/get_all_barcodes_inventario.dart';
import 'package:wms_app/features/inventario/domain/usecases/get_barcodes_producto.dart';
import 'package:wms_app/features/inventario/domain/usecases/get_configuracion_usuario_inventario.dart';
import 'package:wms_app/features/inventario/domain/usecases/get_lotes_producto.dart';
import 'package:wms_app/features/inventario/domain/usecases/get_productos_count.dart';
import 'package:wms_app/features/inventario/domain/usecases/get_productos_local.dart';
import 'package:wms_app/features/inventario/domain/usecases/get_ubicaciones_local.dart';
import 'package:wms_app/features/inventario/domain/usecases/sync_productos_inventario.dart';
import 'package:wms_app/features/user/domain/entities/user_configuration.dart';

part 'inventario_event.dart';
part 'inventario_state.dart';

@injectable
class InventarioBloc extends Bloc<InventarioEvent, InventarioState> {
  // ─── Usecases ────────────────────────────────────────────────────────────────

  final SyncProductosInventario syncProductosInventario;
  final GetProductosLocal getProductosLocal;
  final GetProductosCount getProductosCount;
  final GetUbicacionesLocal getUbicacionesLocal;
  final GetLotesProducto getLotesProducto;
  final EnviarProductoInventario enviarProductoInventario;
  final CrearLoteInventario crearLoteInventario;
  final GetBarcodesProducto getBarcodesProducto;
  final GetAllBarcodesInventario getAllBarcodesInventario;
  final GetConfiguracionUsuarioInventario getConfiguracionUsuarioInventario;

  // ─── TextEditingControllers ───────────────────────────────────────────────────

  final TextEditingController searchControllerLocation =
      TextEditingController();
  final TextEditingController searchControllerProducts =
      TextEditingController();
  final TextEditingController searchControllerLote = TextEditingController();
  final TextEditingController newLoteController = TextEditingController();
  final TextEditingController dateLoteController = TextEditingController();
  final TextEditingController controllerLocation = TextEditingController();
  final TextEditingController controllerLote = TextEditingController();
  final TextEditingController controllerProduct = TextEditingController();
  final TextEditingController controllerQuantity = TextEditingController();
  final TextEditingController cantidadController = TextEditingController();

  // ─── Estado de campos escaneados ─────────────────────────────────────────────

  String scannedValue1 = '';
  String scannedValue2 = '';
  String scannedValue3 = '';
  String scannedValue4 = '';

  // ─── Listas ───────────────────────────────────────────────────────────────────

  List<UbicacionInventario> ubicaciones = [];
  List<UbicacionInventario> ubicacionesFilters = [];
  List<ProductoInventario> productos = [];
  List<ProductoInventario> productosFilters = [];
  List<LoteProductoInventario> listLotesProduct = [];
  List<LoteProductoInventario> listLotesProductFilters = [];
  List<BarcodeProducto> barcodeInventario = [];
  List<BarcodeProducto> allBarcodeInventario = [];

  // ─── Selecciones actuales ─────────────────────────────────────────────────────

  UbicacionInventario? currentUbication;
  ProductoInventario? currentProduct;
  LoteProductoInventario? currentProductLote;

  // ─── Flags de validación ─────────────────────────────────────────────────────

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
  bool isLoading = false;

  // ─── Configuración y conteo ───────────────────────────────────────────────────

  UserConfiguration configurations = UserConfiguration();
  String? selectedAlmacen;
  int quantitySelected = 1;
  int productosCount = 0;

  // ─── Constructor ──────────────────────────────────────────────────────────────

  InventarioBloc({
    required this.syncProductosInventario,
    required this.getProductosLocal,
    required this.getProductosCount,
    required this.getUbicacionesLocal,
    required this.getLotesProducto,
    required this.enviarProductoInventario,
    required this.crearLoteInventario,
    required this.getBarcodesProducto,
    required this.getAllBarcodesInventario,
    required this.getConfiguracionUsuarioInventario,
  }) : super(InventarioInitial()) {
    on<GetLocationsEvent>(_onLoadLocations, transformer: restartable());
    on<SearchLocationEvent>(_onSearchLocationEvent, transformer: droppable());
    on<SearchLotevent>(_onSearchLoteEvent, transformer: droppable());
    on<SearchProductEvent>(_onSearchProductEvent, transformer: droppable());
    on<ValidateFieldsEvent>(_onValidateFieldsEvent);
    on<ChangeLocationIsOkEvent>(_onChangeLocationIsOkEvent);
    on<ChangeProductIsOkEvent>(_onChangeProductIsOkEvent);
    on<ChangeIsOkQuantity>(_onChangeIsOkQuantity);
    on<GetProductsEvent>(_onGetProducts, transformer: restartable());
    on<GetProductsForDB>(_onGetProductsBD, transformer: droppable());
    on<CleanFieldsEent>(_onCleanFieldsEvent);
    on<GetLotesProduct>(_onGetLotesProduct);
    on<SelectecLoteEvent>(_onSelectecLoteEvent);
    on<ShowQuantityEvent>(_onShowQuantityEvent);
    on<FetchBarcodesProductEvent>(_onFetchBarcodesProductEvent);
    on<AddQuantitySeparate>(_onAddQuantitySeparate);
    on<ChangeQuantitySeparate>(_onChangeQuantitySeparate);
    on<SendProductInventarioEnvet>(_onSendProductInventarioEvent);
    on<CreateLoteProduct>(_onCreateLoteProduct);
    on<LoadConfigurationsUserInventory>(_onLoadConfigurationsUserEvent);
    on<FilterUbicacionesAlmacenEvent>(
      _onFilterUbicacionesEvent,
      transformer: droppable(),
    );
    on<SetUbicacionFijaEvent>(_onSetUbicacionFijaEvent);
    on<FetchAllBarcodesInventarioEvent>(
      _onFetchAllBarcodesInventarioEvent,
      transformer: droppable(),
    );
    on<LoadProductosCountEvent>(_onLoadProductosCountEvent);
  }

  // ─── Limpieza de campos (typo preservado del legacy) ─────────────────────────

  void clenanFields() {
    productIsOk = false;
    loteIsOk = false;
    quantityIsOk = false;
    isProductOk = true;
    isLoteOk = true;
    isQuantityOk = true;
    currentProduct = null;
    currentProductLote = null;
    if (!ubicacionFija) {
      currentUbication = null;
      locationIsOk = false;
      isLocationOk = true;
      controllerLocation.clear();
    }
    viewQuantity = false;
    quantitySelected = 0;
    controllerProduct.clear();
    controllerLote.clear();
    controllerQuantity.clear();
    cantidadController.clear();
    listLotesProduct.clear();
    listLotesProductFilters.clear();
    barcodeInventario.clear();
    scannedValue1 = '';
    scannedValue2 = '';
    scannedValue3 = '';
    scannedValue4 = '';
  }

  // ─── Handlers ────────────────────────────────────────────────────────────────

  Future<void> _onLoadLocations(
    GetLocationsEvent event,
    Emitter<InventarioState> emit,
  ) async {
    emit(LoadLocationsLoading());
    final result = await getUbicacionesLocal(NoParams());
    result.fold((failure) => emit(LoadLocationsFailure(failure.message)), (
      ubics,
    ) {
      ubicaciones = ubics;
      ubicacionesFilters = ubics;
      if (ubics.isNotEmpty) {
        emit(LoadLocationsSuccess(ubics));
      } else {
        emit(LoadLocationsFailure('No se encontraron ubicaciones'));
      }
    });
  }

  Future<void> _onSearchLocationEvent(
    SearchLocationEvent event,
    Emitter<InventarioState> emit,
  ) async {
    emit(SearchLoading());
    final query = event.query.toLowerCase();
    final filtrados = ubicaciones.where((location) {
      final name = (location.name ?? '').toLowerCase();
      final barcode = (location.barcode ?? '').toString().trim();
      return name.contains(query) || barcode.contains(query);
    }).toList();
    ubicacionesFilters = filtrados;
    emit(SearchLocationSuccess(filtrados));
  }

  Future<void> _onSearchLoteEvent(
    SearchLotevent event,
    Emitter<InventarioState> emit,
  ) async {
    emit(SearchLoading());
    final query = event.query.toLowerCase();
    final filtrados = listLotesProduct.where((lote) {
      return lote.name?.toLowerCase().contains(query) ?? false;
    }).toList();
    listLotesProductFilters = filtrados;
    emit(SearchLoteSuccess(filtrados));
  }

  Future<void> _onSearchProductEvent(
    SearchProductEvent event,
    Emitter<InventarioState> emit,
  ) async {
    emit(SearchLoading());
    final query = event.query.trim().toLowerCase();

    if (query.isEmpty) {
      productosFilters = List.from(productos);
      emit(SearchProductSuccess(productosFilters));
      return;
    }

    // Normaliza cualquier campo a texto en minúsculas para que la coincidencia
    // sea exacta también con valores alfanuméricos (referencias, barcodes).
    String norm(dynamic v) => (v ?? '').toString().toLowerCase();

    final filtrados = productos.where((product) {
      final campos = <String>[
        norm(product.name), // nombre
        norm(product.code), // referencia / código de producto
        norm(product.barcode), // barcode principal
        norm(product.lotName), // lote
        norm(product.locationName), // ubicación
      ];
      // Barcodes alternos y de empaque (pueden ser alfanuméricos).
      for (final b in (product.otherBarcodes ?? const [])) {
        campos.add(norm(b.barcode));
      }
      for (final b in (product.productPacking ?? const [])) {
        campos.add(norm(b.barcode));
      }
      return campos.any((campo) => campo.contains(query));
    }).toList();

    productosFilters = filtrados;
    emit(SearchProductSuccess(filtrados));
  }

  Future<void> _onValidateFieldsEvent(
    ValidateFieldsEvent event,
    Emitter<InventarioState> emit,
  ) async {
    switch (event.field) {
      case 'location':
        isLocationOk = event.isOk;
        break;
      case 'product':
        isProductOk = event.isOk;
        break;
      case 'lote':
        isLoteOk = event.isOk;
        break;
      case 'quantity':
        isQuantityOk = event.isOk;
        break;
    }

    if (isLocationOk && isProductOk && isLoteOk && isQuantityOk) {
      emit(ValidateFieldsStateSuccess(true));
    } else {
      emit(ValidateFieldsStateError('Faltan campos por completar'));
    }
  }

  Future<void> _onChangeLocationIsOkEvent(
    ChangeLocationIsOkEvent event,
    Emitter<InventarioState> emit,
  ) async {
    currentUbication = event.locationSelect;
    locationIsOk = true;
    controllerLocation.text = event.locationSelect.name ?? '';
    emit(ChangeLocationIsOkState(true));
  }

  Future<void> _onChangeProductIsOkEvent(
    ChangeProductIsOkEvent event,
    Emitter<InventarioState> emit,
  ) async {
    currentProduct = event.productSelect;
    productIsOk = true;
    controllerProduct.text = event.productSelect.name ?? '';
    add(FetchBarcodesProductEvent());
    if (currentProduct?.tracking == 'lot') {
      add(
        GetLotesProduct(
          isManual: event.isManual,
          idLote: (currentProduct?.lotId as int?) ?? 0,
        ),
      );
    } else {
      viewQuantity = false;
      if (currentProduct?.tracking == 'none' ||
          currentProduct?.tracking == null) {
        add(ChangeIsOkQuantity(true));
      }
    }
    emit(ChangeProductIsOkState(true));
  }

  Future<void> _onChangeIsOkQuantity(
    ChangeIsOkQuantity event,
    Emitter<InventarioState> emit,
  ) async {
    quantityIsOk = event.isQuantity;
    isQuantityOk = event.isQuantity;
    emit(ChangeQuantityIsOkState(event.isQuantity));
  }

  Future<void> _onGetProducts(
    GetProductsEvent event,
    Emitter<InventarioState> emit,
  ) async {
    if (isLoading) return;
    isLoading = true;
    emit(GetProductsLoadingInventory());

    final syncResult = await syncProductosInventario(
      SyncProductosParams(
        isLoadingDialog: event.isDialogLoading,
        onProgress: (phase, processed, total) {
          emit(SyncProgressState(phase: phase, processed: processed, total: total));
        },
      ),
    );

    final syncFailure = syncResult.fold<Failure?>((f) => f, (_) => null);
    if (syncFailure != null) {
      isLoading = false;
      if (syncFailure is SessionExpiredFailure) {
        emit(InventarioSessionExpiredState());
      }
      emit(GetProductsFailureInventory(syncFailure.message));
      return;
    }

    final localResult = await getProductosLocal(NoParams());
    localResult.fold(
      (failure) {
        isLoading = false;
        emit(GetProductsFailureInventory(failure.message));
      },
      (productList) {
        productos = List.from(productList);
        productosFilters = List.from(productList);
        productosCount = productList.length;
        isLoading = false;
        if (productList.isNotEmpty) {
          emit(GetProductsSuccess(productos));
          emit(GetProductsSuccessBD(productos));
        } else {
          emit(GetProductsFailureInventory('No se encontraron productos'));
        }
      },
    );
  }

  Future<void> _onGetProductsBD(
    GetProductsForDB event,
    Emitter<InventarioState> emit,
  ) async {
    emit(GetProductsLoadingBD());
    final result = await getProductosLocal(NoParams());
    result.fold(
      (failure) {
        isLoading = false;
        emit(GetProductsFailureInventory(failure.message));
      },
      (productList) {
        productos = productList;
        productosFilters = productList;
        isLoading = false;
        if (productList.isNotEmpty) {
          emit(GetProductsSuccessBD(productList));
        } else {
          emit(GetProductsFailureInventory('No se encontraron productos'));
        }
      },
    );
  }

  Future<void> _onCleanFieldsEvent(
    CleanFieldsEent event,
    Emitter<InventarioState> emit,
  ) async {
    clenanFields();
    emit(CleanFieldsState());
  }

  Future<void> _onGetLotesProduct(
    GetLotesProduct event,
    Emitter<InventarioState> emit,
  ) async {
    emit(GetLotesProductLoading());
    final result = await getLotesProducto(
      GetLotesProductoParams(productId: currentProduct?.productId ?? 0),
    );
    result.fold(
      (failure) {
        if (failure is SessionExpiredFailure) {
          emit(InventarioSessionExpiredState());
        }
        emit(GetLotesProductFailure(failure.message));
      },
      (lotes) {
        listLotesProduct = lotes;
        listLotesProductFilters = List.from(lotes);
        emit(GetLotesProductSuccess(lotes));
      },
    );
  }

  Future<void> _onSelectecLoteEvent(
    SelectecLoteEvent event,
    Emitter<InventarioState> emit,
  ) async {
    currentProductLote = event.lote;
    loteIsOk = true;
    isLoteOk = true;
    controllerLote.text = event.lote.name ?? '';
    add(ChangeIsOkQuantity(true));
    emit(ChangeLoteIsOkState(true));
  }

  Future<void> _onShowQuantityEvent(
    ShowQuantityEvent event,
    Emitter<InventarioState> emit,
  ) async {
    viewQuantity = event.showQuantity;
    emit(ShowQuantityState(event.showQuantity));
  }

  Future<void> _onFetchBarcodesProductEvent(
    FetchBarcodesProductEvent event,
    Emitter<InventarioState> emit,
  ) async {
    barcodeInventario.clear();
    final result = await getBarcodesProducto(
      GetBarcodesProductoParams(productId: currentProduct?.productId ?? 0),
    );
    result.fold((_) => emit(BarcodesProductLoadedState(listOfBarcodes: [])), (
      barcodes,
    ) {
      barcodeInventario = barcodes;
      emit(BarcodesProductLoadedState(listOfBarcodes: barcodeInventario));
    });
  }

  Future<void> _onAddQuantitySeparate(
    AddQuantitySeparate event,
    Emitter<InventarioState> emit,
  ) async {
    try {
      quantitySelected = quantitySelected + (num.tryParse(event.quantity.toString()) ?? 0).toInt();
      emit(ChangeQuantitySeparateStateSuccess(quantitySelected));
    } catch (e, s) {
      emit(ChangeQuantitySeparateStateError('Error al aumentar cantidad'));
      debugPrint('❌ Error en el AddQuantitySeparate $e -> $s');
    }
  }

  Future<void> _onChangeQuantitySeparate(
    ChangeQuantitySeparate event,
    Emitter<InventarioState> emit,
  ) async {
    quantitySelected = event.quantity;
    emit(ChangeQuantitySeparateStateSuccess(quantitySelected));
  }

  Future<void> _onSendProductInventarioEvent(
    SendProductInventarioEnvet event,
    Emitter<InventarioState> emit,
  ) async {
    emit(SendProductLoading());
    final result = await enviarProductoInventario(
      EnviarProductoInventarioParams(
        locationId: currentUbication?.id ?? 0,
        productId: currentProduct?.productId ?? 0,
        lotId: currentProductLote?.id ?? 0,
        quantity: event.cantidad,
      ),
    );
    result.fold(
      (failure) {
        if (failure is SessionExpiredFailure) {
          emit(InventarioSessionExpiredState());
        }
        emit(SendProductFailure(failure.message));
      },
      (resultado) {
        if (resultado.status == 'success') {
          clenanFields();
          cantidadController.clear();
          emit(SendProductSuccess());
        } else {
          emit(SendProductFailure(resultado.message ?? ''));
        }
      },
    );
  }

  Future<void> _onCreateLoteProduct(
    CreateLoteProduct event,
    Emitter<InventarioState> emit,
  ) async {
    emit(CreateLoteProductLoading());
    final result = await crearLoteInventario(
      CrearLoteInventarioParams(
        productId: currentProduct?.productId ?? 0,
        nameLote: event.nameLote,
        fechaCaducidad: event.fechaCaducidad,
        priorityExpiration: event.priorityExpiration,
      ),
    );
    result.fold(
      (failure) {
        if (failure is SessionExpiredFailure) {
          emit(InventarioSessionExpiredState());
        }
        emit(CreateLoteProductFailure(failure.message, 0));
      },
      (resultado) {
        if (resultado.code == 200) {
          final newLote = resultado.lote ?? const LoteProductoInventario();
          listLotesProduct.add(newLote);
          listLotesProductFilters = List.from(listLotesProduct);
          currentProductLote = newLote;
          loteIsOk = true;
          dateLoteController.clear();
          newLoteController.clear();
          add(SelectecLoteEvent(currentProductLote!));
          emit(CreateLoteProductSuccess());
        } else {
          emit(
            CreateLoteProductFailure(
              resultado.msg ??
                  'Error al crear el lote contactarse con el administrador',
              resultado.code ?? 0,
            ),
          );
        }
      },
    );
  }

  Future<void> _onLoadConfigurationsUserEvent(
    LoadConfigurationsUserInventory event,
    Emitter<InventarioState> emit,
  ) async {
    final result = await getConfiguracionUsuarioInventario(NoParams());
    result.fold(
      (failure) => emit(ConfigurationErrorInventory(failure.message)),
      (config) {
        configurations = config;
        emit(ConfigurationLoadedInventory(config));
      },
    );
  }

  Future<void> _onFilterUbicacionesEvent(
    FilterUbicacionesAlmacenEvent event,
    Emitter<InventarioState> emit,
  ) async {
    emit(FilterUbicacionesLoading());
    final query = event.almacen.toLowerCase();
    if (query.isEmpty) {
      ubicacionesFilters = ubicaciones;
      emit(FilterUbicacionesSuccess(ubicaciones));
      return;
    }
    final filtradas = ubicaciones.where((location) {
      return location.warehouseName?.toLowerCase().contains(query) ?? false;
    }).toList();
    selectedAlmacen = event.almacen;
    ubicacionesFilters = filtradas;
    if (filtradas.isNotEmpty) {
      emit(FilterUbicacionesSuccess(filtradas));
    } else {
      emit(
        FilterUbicacionesFailure(
          'No se encontraron ubicaciones para ese almacén',
        ),
      );
    }
  }

  Future<void> _onSetUbicacionFijaEvent(
    SetUbicacionFijaEvent event,
    Emitter<InventarioState> emit,
  ) async {
    try {
      ubicacionFija = event.ubicacionFija;
      emit(ChangeLocationIsOkState(locationIsOk));
    } catch (e, s) {
      debugPrint("❌ Error en SetUbicacionFijaEvent: $e, $s");
      emit(ChangeLocationIsOkState(false));
    }
  }

  Future<void> _onFetchAllBarcodesInventarioEvent(
    FetchAllBarcodesInventarioEvent event,
    Emitter<InventarioState> emit,
  ) async {
    final result = await getAllBarcodesInventario(NoParams());
    result.fold((failure) => emit(FetchAllBarcodesFailure(failure.message)), (
      barcodes,
    ) {
      allBarcodeInventario = barcodes;
      if (barcodes.isNotEmpty) {
        emit(FetchAllBarcodesSuccess(barcodes));
      } else {
        emit(FetchAllBarcodesFailure('No se encontraron códigos de barras'));
      }
    });
  }

  Future<void> _onLoadProductosCountEvent(
    LoadProductosCountEvent event,
    Emitter<InventarioState> emit,
  ) async {
    final result = await getProductosCount(NoParams());
    result.fold(
      (failure) => debugPrint('Error al obtener conteo: ${failure.message}'),
      (count) {
        productosCount = count;
        emit(LoadProductosCountSuccess(count));
      },
    );
  }

  // ─── Dispose ──────────────────────────────────────────────────────────────────

  @override
  Future<void> close() {
    searchControllerLocation.dispose();
    searchControllerProducts.dispose();
    searchControllerLote.dispose();
    newLoteController.dispose();
    dateLoteController.dispose();
    controllerLocation.dispose();
    controllerLote.dispose();
    controllerProduct.dispose();
    controllerQuantity.dispose();
    cantidadController.dispose();
    return super.close();
  }
}
