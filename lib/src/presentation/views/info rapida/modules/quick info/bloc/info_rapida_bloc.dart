import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/features/user/data/models/user_configuration_model.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/data/info_rapida_repository.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/models/info_rapida_model.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/models/update_product_request.dart';
import 'package:wms_app/src/presentation/views/inventario/data/inventario_repository.dart';
import 'package:wms_app/src/presentation/views/inventario/models/response_products_model.dart';
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

  //*configuracion del usuario //permisos
  UserConfigurationModel configurations = UserConfigurationModel();

  //repositorio de inventario
  InventarioRepository inventarioRepository = InventarioRepository();

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
  }

  void _onToggleProductMassTransferEvent(
      ToggleProductMassTransferEvent event, Emitter<InfoRapidaState> emit) {
    print('isSelectedMassTransfer: ${event.isSelected}');
    print('product id: ${event.product.id}');

    //agregamos esos productos a la lista de productos para transferencia masiva
    if (event.isSelected) {
      //agregamos el producto a la lista
      //validamos si el producto ya existe en la lista
      if (!productosFiltersMassTransfer
          .any((prod) => prod.id == event.product.id)) {
        productosFiltersMassTransfer.add(event.product);
      }
    } else {
      //removemos el producto de la lista
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
                  cantidadEnviada: product.cantidad ?? 0,
                  idLote: product.loteId ?? 0,
                  timeLine: 2,
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
      print("❌ Error en el CreateTransferEvent $e ->$s");
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
      print("❌ Error en el ValidateFieldsEvent $e ->$s");
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
      print("❌ Error en el ChangeLocationIsOkEvent $e ->$s");
    }
  }

  //metodo para resetear la lista de productos
  void _onResetProductsFiltersMassTransferEvent(
      ResetProductsFiltersMassTransferEvent event,
      Emitter<InfoRapidaState> emit) {
    try {
      print('Reseteando la lista de productos filtrados');
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
      print('Error en el ResetProductsFiltersMassTransferEvent: $e, $s');
      emit(ResetProductsFiltersMassTransferFailure(e.toString()));
    }
  }

  //metodo para eliminar un producto de la lista de transferencias masivas
  void _onRemoveProductFromMassTransferEvent(
      RemoveProductFromMassTransferEvent event, Emitter<InfoRapidaState> emit) {
    try {
      print('Eliminando producto de la lista de transferencias masivas');
      emit(RemoveProductFromMassTransferLoading());
      productosFiltersMassTransfer
          .removeWhere((element) => element.id == event.idProduct);
      emit(RemoveProductFromMassTransferSuccess(productosFiltersMassTransfer));
    } catch (e, s) {
      print('Error en el RemoveProductFromMassTransferEvent: $e, $s');
      emit(RemoveProductFromMassTransferFailure(e.toString()));
    }
  }

  void _onViewProductImageEvent(
      ViewProductImageEvent event, Emitter<InfoRapidaState> emit) async {
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

  void _onSortProductsEvent(
      SortProductsEvent event, Emitter<InfoRapidaState> emit) {
    try {
      print('Ordenando productos, ascending: ${event.ascending}');
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
      print('Error en el SortProductsEvent: $e, $s');
      emit(SortProductsFailure(e.toString()));
    }
  }

  void _onToggleProductExpansionEvent(
      ToggleProductExpansionEvent event, Emitter<InfoRapidaState> emit) {
    print('isExpanded: $isExpanded');
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
      print('Error en el EditLocationEvent: $e, $s');
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
      print('Error en LoadConfigurationsUserPack.dart: $e =>$s');
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
      print('Error en el UpdateProductEvent: $e, $s');
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
      print('Error en el FilterUbicacionesEvent: $e, $s');
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
      print('productos: ${response.length}');
      if (response.isNotEmpty) {
        productos = response;
        productosFilters = productos;

        emit(GetProductsSuccess(response));
      } else {
        emit(GetProductsFailure('No se encontraron productos'));
      }
    } catch (e, s) {
      emit(GetProductsFailure('Error al cargar los productos'));
      print('Error en el fetch de productos: $e=>$s');
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
      print('Error en el SearchLocationEvent: $e, $s');
      emit(SearchFailure(e.toString()));
    }
  }

  void _onLoadLocations(
      GetListLocationsEvent event, Emitter<InfoRapidaState> emit) async {
    try {
      emit(LoadLocationsLoading());

      // Verificar si las ubicaciones ya están cargadas en UserBloc
      var userLocations = userBloc.ubicaciones;

      // Si están vacías, cargar las ubicaciones desde UserBloc
      if (userLocations.isEmpty) {
        print('Ubicaciones vacías, cargando desde UserBloc...');
        userBloc.add(LoadUserLocationsEvent());

        // Esperar a que se carguen las ubicaciones
        await for (final state in userBloc.stream) {
          if (state is UserLocationsLoaded) {
            userLocations = state.locations;
            print(
                'Ubicaciones cargadas desde UserBloc: ${userLocations.length}');
            break;
          } else if (state is UserLocationsError) {
            print('Error al cargar ubicaciones: ${state.message}');
            emit(LoadLocationsFailure(
                'Error al cargar ubicaciones: ${state.message}'));
            return;
          }
        }
      }

      // Convertir UserLocation a ResultUbicaciones
      final List<ResultUbicaciones> convertedLocations =
          userLocations.map((userLoc) {
        return ResultUbicaciones(
          id: userLoc.id,
          name: userLoc.name,
          idWarehouse: userLoc.idWarehouse,
          barcode: userLoc.barcode,
          warehouseName: userLoc.warehouseName,
        );
      }).toList();

      ubicaciones.clear();
      ubicacionesFilters.clear();
      print('ubicaciones length from UserBloc: ${convertedLocations.length}');

      if (convertedLocations.isNotEmpty) {
        ubicaciones = convertedLocations;
        ubicacionesFilters = ubicaciones;
        print('ubicaciones cargadas: ${ubicaciones.length}');
        emit(LoadLocationsSuccess(ubicaciones));
      } else {
        print('No se encontraron ubicaciones en UserBloc');
        emit(LoadLocationsFailure('No se encontraron ubicaciones'));
      }
    } catch (e, s) {
      emit(LoadLocationsFailure('Error al cargar las ubicaciones'));
      print('Error en el fetch de ubicaciones: $e=>$s');
    }
  }

  void _onIsEditEvent(IsEditEvent event, Emitter<InfoRapidaState> emit) {
    isEdit = event.isEdit;
    print('isEdit: $isEdit');
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
          return location.name?.toLowerCase().contains(query) ?? false;
        }).toList();
      }
      emit(SearchLocationSuccess(ubicacionesFilters));
    } catch (e, s) {
      print('Error en el SearchLocationEvent: $e, $s');
      emit(SearchFailure(e.toString()));
    }
  }

  void _onGetInfoRapida(
      GetInfoRapida event, Emitter<InfoRapidaState> emit) async {
    emit(InfoRapidaLoading());

    try {
      infoRapidaResult = InfoRapidaResult();

      InfoRapida infoRapida; // Defínelo fuera del if

      debugPrint('manual: ${event.isManual}');
      debugPrint('is product: ${event.isProduct}');
      debugPrint('barcode: ${event.barcode.trim()}');

      if (event.isManual) {
        infoRapida = await _infoRapidaRepository.getInfoQuickManual(
          false,
          event.barcode.trim(),
          event.isProduct,
        );
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

  void _onSortLocationsEvent(
      SortLocationsEvent event, Emitter<InfoRapidaState> emit) {
    try {
      print(
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
      print('Error en el SortLocationsEvent: $e, $s');
      emit(SortLocationsFailure(e.toString()));
    }
  }
}
