import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/services/interfaces/i_websocket_service.dart';
import 'package:wms_app/features/user/data/models/user_configuration_model.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/info_rapida/data/info_rapida_repository.dart';
import 'package:wms_app/src/presentation/views/info_rapida/models/info_rapida_model.dart';
import 'package:wms_app/src/presentation/views/info_rapida/models/update_product_request.dart';
import 'package:wms_app/features/inventario/domain/usecases/get_url_imagen_producto.dart';
import 'package:wms_app/src/presentation/providers/db/models/response_products_model.dart';
import 'package:wms_app/src/presentation/views/transferencias/data/transferencias_repository.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/models/request_create_trasnfer_model.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/models/response_create_transfer_mode.dart';

part 'info_rapida_event.dart';
part 'info_rapida_state.dart';

class InfoRapidaBloc extends Bloc<InfoRapidaEvent, InfoRapidaState> {
  final InfoRapidaRepository _infoRapidaRepository = InfoRapidaRepository();
  //*repositorio
  final TransferenciasRepository _transferenciasRepository =
      TransferenciasRepository();
  final UserBloc userBloc;
  InfoRapidaResult infoRapidaResult = InfoRapidaResult();

  String scannedValue1 = '';
  String selectedAlmacen = '';

  //controller
  TextEditingController searchControllerLocation = TextEditingController();
  TextEditingController searchControllerProducts = TextEditingController();

  //*lista de ubicaciones
  List<ResultUbicaciones> ubicaciones = [];
  List<ResultUbicaciones> ubicacionesFilters = [];

  //*lista de productos
  List<Product> productos = [];
  List<Product> productosFilters = [];
  List<Producto> productosFiltersMassTransfer = [];

  //*base de datos
  DataBaseSqlite db = DataBaseSqlite();

  bool isKeyboardVisible = false;
  bool isEdit = false;
  bool isNumericKeyboardType = false;
  bool isExpanded = false;

  bool isAscending = true;
  bool isInitialized = false;

  bool isMassTransferActive = false;
  ResultUbicaciones? currentUbicationDest;
  String scannedValue2 = ''; //ubicacion destino
  String scannedValue3 = ''; //producto
  Producto? currentProduct;
  bool productIsOk = false;
  bool isProductOk = true;
  //date de inicio y fin de la transferencia
  String dateTransferInicio = '';

  TextEditingController? controllerActivo;

  //*variables de escaneo
  bool isLocationDestOk = true;
  bool locationDestIsOk = false;

  List<Producto>? productosUbicacion = [];
  List<Ubicacion>? ubicacionesProducto = [];

  //*configuracion del usuario //permisos
  UserConfigurationModel configurations = UserConfigurationModel();

  //repositorio de inventario

  StreamSubscription<dynamic>? _wsSubscription;

  InfoRapidaBloc({required this.userBloc}) : super(InfoRapidaInitial()) {
    on<InfoRapidaEvent>((event, emit) {});

    on<GetInfoRapida>(_onGetInfoRapida);

    //metodo para buscar una ubicacion
    on<SearchLocationEvent>(_onSearchLocationEvent);

    // *activar el edit
    on<IsEditEvent>(_onIsEditEvent);

    //*metodo para cargar las ubicaciones
    on<GetListLocationsEvent>(_onLoadLocations);
    //*metodo para bucar un producto
    on<SearchProductEvent>(_onSearchProductEvent);

    //*metodo para bucar un producto en la lista de ubicaciones
    on<SearchProductLocationEvent>(_onSearchLocationWithProductEvent);
    on<SearchLocationProductsEvent>(_onSearchProductWithLocationsEvent);

    on<GetProductsList>(_onGetProductsBD);

    on<FilterUbicacionesAlmacenEvent>(_onFilterUbicacionesEvent);

    //evento para actualizar del producto
    on<UpdateProductEvent>(_onUpdateProductEvent);

    //*obtener las configuraciones y permisos del usuario desde la bd
    on<LoadConfigurationsUserInfo>(_onLoadConfigurationsUserEvent);

    //evento para editar una ubicacion
    on<EditLocationEvent>(_onEditLocationEvent);

    // ToggleProductExpansionEvent
    on<ToggleProductExpansionEvent>(_onToggleProductExpansionEvent);

    //evento para ordenar de formar ascendente o descendente las ubicaciones
    on<SortLocationsEvent>(_onSortLocationsEvent);

    //evento para ordenar de forma ascendente o descendente los productos
    on<SortProductsEvent>(_onSortProductsEvent);

    //evento para ver la url de un producto
    on<ViewProductImageEvent>(_onViewProductImageEvent);

    //evento para eliminar un producto de la lista de transferencias masivas
    on<RemoveProductFromMassTransferEvent>(
        _onRemoveProductFromMassTransferEvent);

    //evento para resetear la lista de productos filtrados
    on<ResetProductsFiltersMassTransferEvent>(
        _onResetProductsFiltersMassTransferEvent);

    //*metodo para validar la ubicacion
    on<ChangeLocationIsOkEvent>(_onChangeLocationIsOkEvent);

    on<ValidateFieldsEvent>(_onValidateFields);

//*metodo para validar el producto
    on<ChangeProductIsOkEvent>(_onChangeProductIsOkEvent);

    //*evento para enviar y crear la transferencia
    on<CreateNewMassTransferEvent>(_onCreateTransferEvent);

    on<ActivateMassTransferEvent>(_onActivateMassTransferEvent);

    on<ToggleProductMassTransferEvent>(_onToggleProductMassTransferEvent);

    on<SelectAllAvailableProductsEvent>(_onSelectAllAvailableProductsEvent);

    on<InitInfoRapidaEvent>(_onInitInfoRapida);

    on<_WsProductUpdateEvent>(_onWsProductUpdate);

    _wsSubscription = getIt<IWebSocketService>().messages.listen(_onRawWsMessage);
  }

  // Normaliza el propietario de un producto: null = sin propietario (grupo propio).
  String? _propietarioKey(Producto p) {
    final tieneManejo = p.manejoPropietario == true || p.manejoPropietario == 1;
    if (!tieneManejo) return null;
    final prop = p.propietario;
    if (prop == null || prop.isEmpty) return null;
    return prop;
  }

  void _onSelectAllAvailableProductsEvent(
      SelectAllAvailableProductsEvent event, Emitter<InfoRapidaState> emit) {
    final disponibles = (productosUbicacion ?? [])
        .where((p) => p.packing != true && (p.cantidadMano ?? 0) > 0)
        .toList();

    // Opción A: determinar el grupo objetivo por propietario.
    // Si ya hay seleccionados, usar su propietario; si no, usar el del primero disponible.
    String? targetKey;
    if (productosFiltersMassTransfer.isNotEmpty) {
      targetKey = _propietarioKey(productosFiltersMassTransfer.first);
    } else if (disponibles.isNotEmpty) {
      targetKey = _propietarioKey(disponibles.first);
    }

    final compatibles = disponibles
        .where((p) => _propietarioKey(p) == targetKey)
        .toList();

    final todosSeleccionados = compatibles.isNotEmpty &&
        compatibles.every(
            (p) => productosFiltersMassTransfer.any((s) => s.id == p.id));

    if (todosSeleccionados) {
      productosFiltersMassTransfer
          .removeWhere((s) => compatibles.any((p) => p.id == s.id));
    } else {
      for (final producto in compatibles) {
        if (!productosFiltersMassTransfer.any((p) => p.id == producto.id)) {
          productosFiltersMassTransfer.add(producto);
        }
      }
    }
    emit(ToggleProductMassTransferState());
  }

  void _onToggleProductMassTransferEvent(
      ToggleProductMassTransferEvent event, Emitter<InfoRapidaState> emit) {
    if (event.isSelected) {
      if (!productosFiltersMassTransfer
          .any((prod) => prod.id == event.product.id)) {
        // Validar compatibilidad de propietario con los ya seleccionados.
        if (productosFiltersMassTransfer.isNotEmpty) {
          final keyExistente =
              _propietarioKey(productosFiltersMassTransfer.first);
          final keyNuevo = _propietarioKey(event.product);

          if (keyExistente != keyNuevo) {
            final String msg;
            if (keyExistente == null) {
              msg =
                  'No puedes mezclar productos sin propietario con productos de "$keyNuevo"';
            } else if (keyNuevo == null) {
              msg =
                  'No puedes mezclar productos de "$keyExistente" con productos sin propietario';
            } else {
              msg =
                  'No puedes mezclar productos de "$keyExistente" con productos de "$keyNuevo"';
            }
            emit(MassTransferPropietarioMismatchState(msg));
            return;
          }
        }
        productosFiltersMassTransfer.add(event.product);
      }
    } else {
      productosFiltersMassTransfer
          .removeWhere((prod) => prod.id == event.product.id);
    }
    emit(ToggleProductMassTransferState());
  }

  void _onActivateMassTransferEvent(
      ActivateMassTransferEvent event, Emitter<InfoRapidaState> emit) {
    isMassTransferActive = event.activate;
    if (event.activate) {
      productosFiltersMassTransfer.clear();
    }
    emit(ActivateMassTransferState());
  }

  void _onCreateTransferEvent(
      CreateNewMassTransferEvent event, Emitter<InfoRapidaState> emit) async {
    try {
      emit(CreateTransferLoading());

      //obtenemos el id del operario
      final userid = await PrefUtils.getUserId();

      final request = CreateTransferRequest(
        dateStart: dateTransferInicio,
        dateEnd: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        idAlmacen: currentUbicationDest?.idWarehouse ?? 0,
        idUbicacionOrigen: infoRapidaResult.result?.id ?? 0,
        idUbicacionDestino: currentUbicationDest?.id ?? 0,
        idOperario: userid,
        fechaTransaccion:
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        listItems: productosFiltersMassTransfer
            .map((product) => ListItem(
                  idProducto: product.id ?? 0,
                  cantidadEnviada: product.cantidadMano ?? 0,
                  idLote: product.loteId ?? 0,
                  timeLine: 2,
                  idPropietario: product.idPropietario ??0
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
        productosFiltersMassTransfer.clear();
        //consultamos la informacion rapida de la ubicacion destino
        add(GetInfoRapida(
            currentUbicationDest?.id.toString() ?? '', true, false, false));
        dateTransferInicio = '';
        currentProduct = Producto();
        scannedValue2 = '';
        scannedValue3 = '';
        isLocationDestOk = true;
        locationDestIsOk = false;
        productIsOk = false;
        isProductOk = true;
        currentUbicationDest = ResultUbicaciones();
        productosFiltersMassTransfer.clear();
        isMassTransferActive = false;

        emit(CreateTransferSuccess(response));
      } else {
        emit(CreateTransferFailure(response.result?.msg ?? ""));
      }
    } catch (e, s) {
      debugPrint("❌ Error en el CreateTransferEvent $e ->$s");
      emit(CreateTransferFailure(e.toString()));
    }
  }

  void _onChangeProductIsOkEvent(
      ChangeProductIsOkEvent event, Emitter<InfoRapidaState> emit) async {
    if (event.productIsOk) {
      //Agregamos este producto a la lista de productos seleccionados para transferencia masiva(productosFiltersMassTransfer)

//quiero validar si este producto ya existe en la lista de productos seleccionados para transferencia masiva
      if (!productosFiltersMassTransfer
          .any((prod) => prod.id == event.productSelect.id)) {
        //el producto no existe en la lista, lo agregamos
        currentProduct = event.productSelect;
        productIsOk = event.productIsOk;
        productosFiltersMassTransfer.add(event.productSelect);
      } else {
        //el producto ya existe en la lista
        emit(ChangeProductOrderIsOkFailure(
          'El producto ya se encuentra en la lista de transferencia masiva',
        ));
      }

      emit(ChangeProductOrderIsOkState(
        productIsOk,
      ));
    }
  }

  void _onValidateFields(
      ValidateFieldsEvent event, Emitter<InfoRapidaState> emit) {
    try {
      switch (event.field) {
        case 'locationDest':
          isLocationDestOk = event.isOk;
          break;

        case 'product':
          isProductOk = event.isOk;
          break;
      }
      emit(ValidateFieldsStateSuccess(event.isOk));
    } catch (e, s) {
      emit(ValidateFieldsStateError('Error al validar campos'));
      debugPrint("❌ Error en el ValidateFieldsEvent $e ->$s");
    }
  }

  void _onChangeLocationIsOkEvent(
      ChangeLocationIsOkEvent event, Emitter<InfoRapidaState> emit) async {
    try {
      if (isLocationDestOk) {
        //valdiamos si es la ubicacion de destino
        if (event.isLocationDest) {
          currentUbicationDest = event.locationSelect;
          locationDestIsOk = true;
          add(SearchLocationEvent(''));
          searchControllerLocation.clear();
          emit(ChangeLocationIsOkState(
            isLocationDestOk,
            true,
          ));
        }
      }
    } catch (e, s) {
      debugPrint("❌ Error en el ChangeLocationIsOkEvent $e ->$s");
    }
  }

  //metodo para resetear la lista de productos
  void _onResetProductsFiltersMassTransferEvent(
      ResetProductsFiltersMassTransferEvent event,
      Emitter<InfoRapidaState> emit) {
    try {
      debugPrint('Reseteando la lista de productos filtrados');
      emit(ResetProductsFiltersMassTransferLoading());
      productosFiltersMassTransfer.clear();
      isMassTransferActive = false;
      currentUbicationDest = ResultUbicaciones();
      currentProduct = Producto();
      scannedValue2 = '';
      scannedValue3 = '';
      isLocationDestOk = true;
      locationDestIsOk = false;
      productIsOk = false;
      isProductOk = true;
      emit(ResetProductsFiltersMassTransferSuccess(
          productosFiltersMassTransfer));
    } catch (e, s) {
      debugPrint('Error en el ResetProductsFiltersMassTransferEvent: $e, $s');
      emit(ResetProductsFiltersMassTransferFailure(e.toString()));
    }
  }

  //metodo para eliminar un producto de la lista de transferencias masivas
  void _onRemoveProductFromMassTransferEvent(
      RemoveProductFromMassTransferEvent event, Emitter<InfoRapidaState> emit) {
    try {
      debugPrint('Eliminando producto de la lista de transferencias masivas');
      emit(RemoveProductFromMassTransferLoading());
      productosFiltersMassTransfer
          .removeWhere((element) => element.id == event.idProduct);
      emit(RemoveProductFromMassTransferSuccess(productosFiltersMassTransfer));
    } catch (e, s) {
      debugPrint('Error en el RemoveProductFromMassTransferEvent: $e, $s');
      emit(RemoveProductFromMassTransferFailure(e.toString()));
    }
  }

  void _onViewProductImageEvent(
      ViewProductImageEvent event, Emitter<InfoRapidaState> emit) async {
    try {
      debugPrint('Obteniendo imagen del producto con ID: ${event.idProduct}');
      emit(ViewProductImageLoading());

      final result = await getIt<GetUrlImagenProducto>()(
          GetUrlImagenProductoParams(productId: event.idProduct));

      result.fold(
        (failure) => emit(ViewProductImageFailure('Imagen no disponible')),
        (url) => emit(ViewProductImageSuccess(url)),
      );
    } catch (e, s) {
      debugPrint('Error en el ViewProductImageEvent: $e, $s');
      emit(ViewProductImageFailure(e.toString()));
    }
  }

  void _onSortProductsEvent(
      SortProductsEvent event, Emitter<InfoRapidaState> emit) {
    try {
      debugPrint('Ordenando productos, ascending: ${event.ascending}');
      emit(SortProductsLoading());
      if (event.ascending) {
        isAscending = true;
        infoRapidaResult.result?.productos
            ?.sort((a, b) => a.producto!.compareTo(b.producto!));
      } else {
        isAscending = false;
        infoRapidaResult.result?.productos
            ?.sort((a, b) => b.producto!.compareTo(a.producto!));
      }
      emit(SortProductsSuccess());
    } catch (e, s) {
      debugPrint('Error en el SortProductsEvent: $e, $s');
      emit(SortProductsFailure(e.toString()));
    }
  }

  void _onToggleProductExpansionEvent(
      ToggleProductExpansionEvent event, Emitter<InfoRapidaState> emit) {
    debugPrint('isExpanded: $isExpanded');
    isExpanded = event.isExpanded;
    emit(ProductExpansionToggled(isExpanded));
  }

  //*metodo para editar una ubicacion
  void _onEditLocationEvent(
      EditLocationEvent event, Emitter<InfoRapidaState> emit) async {
    try {
      emit(EditLocationLoading());
      final response = await _infoRapidaRepository.updateLocation(
          event.locationId, event.name, event.barcode, true);

      if (response.result?.code == 200) {
        await db.ubicacionesRepository.insertOrUpdateSingle(
          ResultUbicaciones(
            id: event.locationId,
            name: event.name,
            barcode: event.barcode,
          ),
        );
        infoRapidaResult = response.result ?? InfoRapidaResult();
        emit(EditLocationSuccess());
        add(
          IsEditEvent(false),
        );
      } else {
        add(
          IsEditEvent(true),
        );
        emit(UpdateProductFailure(
          '${response.result?.msg}',
        ));
      }
    } catch (e, s) {
      debugPrint('Error en el EditLocationEvent: $e, $s');
      emit(EditLocationFailure(e.toString()));
    }
  }

  //*metodo para cargar la configuracion del usuario
  void _onLoadConfigurationsUserEvent(
      LoadConfigurationsUserInfo event, Emitter<InfoRapidaState> emit) async {
    try {
      int userId = await PrefUtils.getUserId();
      final response =
          await db.configurationsRepository.getConfiguration(userId);

      if (response != null) {
        configurations = response;
        emit(ConfigurationLoadedInfoRapida(response));
      } else {
        emit(ConfigurationError('Error al cargar configuraciones'));
      }
    } catch (e, s) {
      emit(ConfigurationError(e.toString()));
      debugPrint('Error en LoadConfigurationsUserPack.dart: $e =>$s');
    }
  }

  void _onUpdateProductEvent(
      UpdateProductEvent event, Emitter<InfoRapidaState> emit) async {
    try {
      emit(UpdateProducrtLoading());
      final response = await _infoRapidaRepository.updateProduct(
        event.request,
        true,
      );

      if (response.result?.code == 200) {
        await db.productoInventarioRepository.updateProduct(event.request);
        infoRapidaResult = response.result ?? InfoRapidaResult();
        emit(UpdateProductSuccess());
        add(
          IsEditEvent(false),
        );
      } else {
        add(
          IsEditEvent(true),
        );
        emit(UpdateProductFailure(
          '${response.result?.msg}',
        ));
      }
    } catch (e, s) {
      debugPrint('Error en el UpdateProductEvent: $e, $s');
      emit(UpdateProductFailure(e.toString()));
    }
  }

  void _onFilterUbicacionesEvent(
      FilterUbicacionesAlmacenEvent event, Emitter<InfoRapidaState> emit) {
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
      debugPrint('Error en el FilterUbicacionesEvent: $e, $s');
      emit(FilterUbicacionesFailure(e.toString()));
    }
  }

  void _onGetProductsBD(
      GetProductsList event, Emitter<InfoRapidaState> emit) async {
    try {
      emit(GetProductsLoading());
      final response =
          await db.productoInventarioRepository.getAllUniqueProducts();
      productos.clear();
      productosFilters.clear();
      debugPrint('productos: ${response.length}');
      if (response.isNotEmpty) {
        productos = response;
        productosFilters = productos;

        emit(GetProductsSuccess(response));
      } else {
        emit(GetProductsFailure('No se encontraron productos'));
      }
    } catch (e, s) {
      emit(GetProductsFailure('Error al cargar los productos'));
      debugPrint('Error en el fetch de productos: $e=>$s');
    }
  }

  void _onSearchProductEvent(
      SearchProductEvent event, Emitter<InfoRapidaState> emit) async {
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
              (product.code?.toLowerCase().contains(query) ?? false) ||
              (product.barcode?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
      emit(SearchProductSuccess(productosFilters));
    } catch (e, s) {
      debugPrint('Error en el SearchLocationEvent: $e, $s');
      emit(SearchFailure(e.toString()));
    }
  }

  void _onSearchLocationWithProductEvent(
      SearchProductLocationEvent event, Emitter<InfoRapidaState> emit) async {
    try {
      emit(SearchLoading());

      final query = event.query.toLowerCase();
      if (query.isEmpty) {
        productosUbicacion = infoRapidaResult.result?.productos;
      } else {
        productosUbicacion = productosUbicacion?.where((product) {
          return (product.producto?.toLowerCase().contains(query) ?? false) ||
              (product.codigoBarras?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
      emit(SearchProductSuccess(productosFilters));
    } catch (e, s) {
      debugPrint('Error en el SearchLocationEvent: $e, $s');
      emit(SearchFailure(e.toString()));
    }
  }

  void _onSearchProductWithLocationsEvent(
      SearchLocationProductsEvent event, Emitter<InfoRapidaState> emit) async {
    try {
      emit(SearchLoading());

      final query = event.query.toLowerCase();
      if (query.isEmpty) {
        ubicacionesProducto = infoRapidaResult.result?.ubicaciones;
      } else {
        ubicacionesProducto = ubicacionesProducto?.where((location) {
          return (location.ubicacion?.toLowerCase().contains(query) ?? false) ||
              (location.codigoBarras?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
      emit(SearchProductSuccess(productosFilters));
    } catch (e, s) {
      debugPrint('Error en el SearchLocationEvent: $e, $s');
      emit(SearchFailure(e.toString()));
    }
  }

  void _onLoadLocations(
      GetListLocationsEvent event, Emitter<InfoRapidaState> emit) async {
    try {
      emit(LoadLocationsLoading());

      // // Verificar si las ubicaciones ya están cargadas en UserBloc
      // var userLocations = userBloc.ubicaciones;

      // // Si están vacías, cargar las ubicaciones desde UserBloc
      // if (userLocations.isEmpty) {
      //   debugPrint('Ubicaciones vacías, cargando desde UserBloc...');
      //   userBloc.add(LoadUserLocationsEvent());

      //   // Esperar a que se carguen las ubicaciones
      //   await for (final state in userBloc.stream) {
      //     if (state is UserLocationsLoaded) {
      //       userLocations = state.locations;
      //       debugPrint(
      //           'Ubicaciones cargadas desde UserBloc: ${userLocations.length}');
      //       break;
      //     } else if (state is UserLocationsError) {
      //       debugPrint('Error al cargar ubicaciones: ${state.message}');
      //       emit(LoadLocationsFailure(
      //           'Error al cargar ubicaciones: ${state.message}'));
      //       return;
      //     }
      //   }
      // }

      // Convertir UserLocation a ResultUbicaciones
      // final List<ResultUbicaciones> convertedLocations =
      //     userLocations.map((userLoc) {
      //   return ResultUbicaciones(
      //     id: userLoc.id,
      //     name: userLoc.name,
      //     idWarehouse: userLoc.idWarehouse,
      //     barcode: userLoc.barcode,
      //     warehouseName: userLoc.warehouseName,
      //   );
      // }).toList();

      ubicaciones.clear();
      ubicacionesFilters.clear();

      //CARGAMOS LAS UBICACIONES DESDE LA BASE DE DATOS LOCAL
      final response = await db.ubicacionesRepository.getAllUbicaciones();
      debugPrint('📍 ubicaciones: ${response.length}');
      ubicaciones.clear();
      ubicacionesFilters.clear();
      if (response.isNotEmpty) {
        ubicaciones = response;
        ubicacionesFilters = ubicaciones;
        debugPrint('ubicaciones cargadas: ${ubicaciones.length}');
        emit(LoadLocationsSuccess(ubicaciones));
      } else {
        debugPrint('No se encontraron ubicaciones en UserBloc');
        emit(LoadLocationsFailure('No se encontraron ubicaciones'));
      }
    } catch (e, s) {
      emit(LoadLocationsFailure('Error al cargar las ubicaciones'));
      debugPrint('Error en el fetch de ubicaciones: $e=>$s');
    }
  }

  void _onIsEditEvent(IsEditEvent event, Emitter<InfoRapidaState> emit) {
    isEdit = event.isEdit;
    debugPrint('isEdit: $isEdit');
    emit(IsEditState(isEdit));
  }

  void _onSearchLocationEvent(
      SearchLocationEvent event, Emitter<InfoRapidaState> emit) async {
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
          return (location.name?.toLowerCase().contains(query) ?? false) ||
              (location.barcode?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
      emit(SearchLocationSuccess(ubicacionesFilters));
    } catch (e, s) {
      debugPrint('Error en el SearchLocationEvent: $e, $s');
      emit(SearchFailure(e.toString()));
    }
  }

  void _onGetInfoRapida(
      GetInfoRapida event, Emitter<InfoRapidaState> emit) async {
    emit(InfoRapidaLoading());

    try {
      infoRapidaResult = InfoRapidaResult();
      searchControllerLocation.clear();
      searchControllerProducts.clear();

      InfoRapida infoRapida; // Defínelo fuera del if

      debugPrint('manual: ${event.isManual}');
      debugPrint('is product: ${event.isProduct}');
      debugPrint('barcode: ${event.barcode.trim()}');

      if (event.isManual) {
        productosUbicacion = [];
        ubicacionesProducto = [];
        infoRapida = await _infoRapidaRepository.getInfoQuickManual(
          false,
          event.barcode.trim(),
          event.isProduct,
        );

        productosUbicacion = infoRapida.result?.result?.productos;
        ubicacionesProducto = infoRapida.result?.result?.ubicaciones;
      } else {
        //validamos si la peticion es para un paquete
        if (event.barcode.contains("Caja") || event.barcode.contains("CAJA")) {
          infoRapida = await _infoRapidaRepository.getInfoQuick(
            false,
            event.barcode,
          );
        } else {
          infoRapida = await _infoRapidaRepository.getInfoQuick(
            false,
            event.barcode.trim(),
          );
        }
      }

      if ((infoRapida.result?.updateVersion ?? false) == true) {
        emit(NeedUpdateVersionState());
      }

      if (infoRapida.result?.code == 200) {
        infoRapidaResult = infoRapida.result!;
        productosUbicacion = infoRapidaResult.result?.productos;
        ubicacionesProducto = infoRapidaResult.result?.ubicaciones;

        emit(InfoRapidaLoaded(infoRapidaResult, infoRapida.result!.type!));
      } else {
        if (infoRapida.result?.code == 403) {
          emit(DeviceNotAuthorized());
          return;
        }

        emit(InfoRapidaError(
            error: infoRapida.result?.msg ?? 'Error desconocido'));
      }
      if (infoRapida.result?.code == 404) {
        emit(InfoRapidaError(
            error: infoRapida.result?.msg ?? 'Error desconocido'));
      }
    } catch (e) {
      emit(InfoRapidaError());
    }
  }

  Future<void> _onInitInfoRapida(
      InitInfoRapidaEvent event, Emitter<InfoRapidaState> emit) async {
    try {
      emit(InitInfoRapidaLoading());

      // Lanzar las 3 queries en paralelo antes de hacer await a cualquiera
      final locationsFuture = db.ubicacionesRepository.getAllUbicaciones();
      final productsFuture = db.productoInventarioRepository.getAllUniqueProducts();
      final configFuture = _fetchConfig();

      final locs = await locationsFuture;
      final prods = await productsFuture;
      final config = await configFuture;

      ubicaciones = locs;
      ubicacionesFilters = locs;
      productos = prods;
      productosFilters = prods;
      if (config != null) configurations = config;

      debugPrint(
          '✅ InitInfoRapida: ${locs.length} ubicaciones | ${prods.length} productos');
      isInitialized = true;
      emit(InitInfoRapidaSuccess());
    } catch (e, s) {
      debugPrint('❌ Error en InitInfoRapidaEvent: $e => $s');
      emit(InitInfoRapidaFailure(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }

  // Recibe el mensaje raw del WebSocket y despacha el evento interno
  void _onRawWsMessage(dynamic data) {
    try {
      final dynamic decoded = jsonDecode(data as String);
      if (decoded is! List) return;
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        final msg = item['message'];
        if (msg is! Map<String, dynamic>) continue;
        if (msg['type'] != 'notification') continue;
        final payload = msg['payload'];
        if (payload is! Map<String, dynamic>) continue;
        if (payload['action'] == 'update') {
          final wsData = payload['data'];
          if (wsData is Map<String, dynamic>) {
            add(_WsProductUpdateEvent(wsData));
          }
        }
      }
    } catch (_) {}
  }

  // Actualiza el producto en las listas en memoria (O(n), sin tocar SQLite)
  void _onWsProductUpdate(
      _WsProductUpdateEvent event, Emitter<InfoRapidaState> emit) {
    final int? productId = event.wsData['product_id'] as int?;
    if (productId == null) return;

    final int idx = productos.indexWhere((p) => p.productId == productId);
    if (idx == -1) return;

    final Product p = productos[idx];
    final Map<String, dynamic> d = event.wsData;

    if (d.containsKey('name')) p.name = d['name']?.toString();
    if (d.containsKey('code')) p.code = d['code'];
    if (d.containsKey('barcode')) p.barcode = d['barcode'];
    if (d.containsKey('tracking')) p.tracking = d['tracking']?.toString();
    if (d.containsKey('uom')) p.uom = d['uom'];
    if (d.containsKey('weight')) p.weight = (d['weight'] as num?)?.toDouble();
    if (d.containsKey('weight_uom_name')) p.weightUomName = d['weight_uom_name'];
    if (d.containsKey('volume')) p.volume = (d['volume'] as num?)?.toDouble();
    if (d.containsKey('volume_uom_name')) p.volumeUomName = d['volume_uom_name'];
    if (d.containsKey('category')) p.category = d['category'];
    if (d.containsKey('location_id')) p.locationId = d['location_id'] as int?;
    if (d.containsKey('location_name')) p.locationName = d['location_name']?.toString();
    if (d.containsKey('lot_id')) p.lotId = d['lot_id'];
    if (d.containsKey('lot_name')) p.lotName = d['lot_name'];
    if (d.containsKey('quantity')) p.quantity = d['quantity'];
    if (d.containsKey('expiration_time')) p.expirationTime = d['expiration_time'];
    if (d.containsKey('use_expiration_date')) {
      p.useExpirationDate = d['use_expiration_date'] == true ? 1 : 0;
    }

    // Sincronizar productosFilters si contiene ese producto
    final int fIdx = productosFilters.indexWhere((p) => p.productId == productId);
    if (fIdx != -1) productosFilters[fIdx] = p;

    debugPrint('🔄 InfoRapidaBloc: producto id=$productId actualizado en memoria vía WS.');
    emit(WsProductSyncedState(productId));
  }

  Future<UserConfigurationModel?> _fetchConfig() async {
    try {
      final userId = await PrefUtils.getUserId();
      return await db.configurationsRepository.getConfiguration(userId);
    } catch (_) {
      return null;
    }
  }

  void _onSortLocationsEvent(
      SortLocationsEvent event, Emitter<InfoRapidaState> emit) {
    try {
      debugPrint(
          'Ordenando ubicaciones por: ${event.criteria}, ascending: ${event.ascending}');
      emit(SortLocationsLoading());

      final locations = infoRapidaResult.result?.ubicaciones;

      if (locations != null) {
        // Función de comparación base
        int compare(dynamic a, dynamic b) {
          switch (event.criteria) {
            case 'lote':
              // Ordenar por Lote (alfabético)
              return (a.lote ?? '').compareTo(b.lote ?? '');

            case 'date':
              // Ordenar por Fecha de Entrada
              // Intentamos parsear la fecha, si falla usamos una fecha muy antigua
              final dateA =
                  DateTime.tryParse(a.fechaCaducidad ?? '') ?? DateTime(1900);
              final dateB =
                  DateTime.tryParse(b.fechaCaducidad ?? '') ?? DateTime(1900);
              return dateA.compareTo(dateB);

            case 'location':
              return (a.ubicacion ?? '').compareTo(b.ubicacion ?? '');
            case 'entrada':
              // Ordenar por Fecha de Entrada
              // Intentamos parsear la fecha, si falla usamos una fecha muy antigua
              final dateA =
                  DateTime.tryParse(a.fechaEntrada ?? '') ?? DateTime(1900);
              final dateB =
                  DateTime.tryParse(b.fechaEntrada ?? '') ?? DateTime(1900);
              return dateA.compareTo(dateB);
            default:
              // Ordenar por Nombre de Ubicación (alfabético) por defecto
              return (a.name ?? '').compareTo(b.name ?? '');
          }
        }

        // Aplicar el ordenamiento
        if (event.ascending) {
          locations.sort((a, b) => compare(a, b));
          isAscending = true;
        } else {
          locations.sort(
              (a, b) => compare(b, a)); // Invertimos a y b para descendente
          isAscending = false;
        }
      }

      emit(SortLocationsSuccess());
    } catch (e, s) {
      debugPrint('Error en el SortLocationsEvent: $e, $s');
      emit(SortLocationsFailure(e.toString()));
    }
  }
}
