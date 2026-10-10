// ignore_for_file: unnecessary_type_check

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:wms_app/features/user/data/models/user_configuration_model.dart';
import 'package:wms_app/features/user/domain/entities/user_configuration.dart';
import 'package:wms_app/core/utils/formats_utils.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/core/services/configuracion_cache_service.dart';
import 'package:wms_app/core/services/terceros_download_service.dart';
import 'package:wms_app/core/services/ubicaciones_cache_service.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/devoluciones/data/devoluciones_repository.dart';
import 'package:wms_app/src/presentation/views/devoluciones/models/product_devolucion_model.dart';
import 'package:wms_app/src/presentation/views/devoluciones/models/request_send_devolucion_model.dart';
import 'package:wms_app/src/presentation/views/devoluciones/models/response_devolucion_model.dart';
import 'package:wms_app/src/presentation/views/devoluciones/models/response_terceros_model.dart';
import 'package:wms_app/src/presentation/providers/db/models/response_products_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_lotes_product_model.dart';
import 'package:wms_app/core/bloc/safe_bloc_mixin.dart';

part 'devoluciones_event.dart';
part 'devoluciones_state.dart';

class DevolucionesBloc extends Bloc<DevolucionesEvent, DevolucionesState>
    with SafeBlocMixin<DevolucionesEvent, DevolucionesState> {
  //controller
  TextEditingController searchControllerLocation = TextEditingController();
  TextEditingController searchControllerProducts = TextEditingController();
  TextEditingController searchControllerTerceros = TextEditingController();
  TextEditingController searchControllerLote = TextEditingController();
  TextEditingController newLoteController = TextEditingController();
  TextEditingController dateLoteController = TextEditingController();
  TextEditingController searchControllerLocationDest = TextEditingController();
  TextEditingController segundaUnidadController = TextEditingController();
  String scannedValue1 = ''; //foco
  String scannedValue2 = ''; //cantidad
  String scannedValue3 = ''; //location
  String scannedValue4 = ''; //contacto

  String selectedAlmacen = '';

  bool locationIsOk = false;
  bool almacenIsOk = false;
  bool contactoIsOk = false;
  bool propietarioIsOk = false;
  bool productIsOk = false;

  //configuracion del usuario //permisos
  UserConfigurationModel configurations = UserConfigurationModel();

  //*productos para elegir: páginas de una consulta a SQLite (una fila por
  //producto). El catálogo completo ya no se carga en memoria: con él la app
  //moría por OutOfMemoryError en PDAs (ver
  //docs/plan_fix_oom_catalogo_productos.md).
  List<Product> productosFilters = [];
  bool hayMasProductos = false;
  static const _paginaProductos = 50;
  String _queryProductos = '';
  // Sube con cada búsqueda nueva: una página que llega tarde no se mezcla
  // con los resultados de otra búsqueda.
  int _busquedaProductos = 0;

  List<ProductDevolucion> productosDevolucion = [];

  Product currentProduct = Product();
  Terceros currentTercero = Terceros();
  Terceros currentPropietario = Terceros();
  AllowedWarehouse currentWarehouse = const AllowedWarehouse();
  ResultUbicaciones currentLocation = ResultUbicaciones();

  List<AllowedWarehouse> allowedWarehouses = [];
  List<AllowedWarehouse> allowedWarehousesFilters = [];
  TextEditingController searchControllerAlmacen = TextEditingController();

  LotesProduct lotesProductCurrent = LotesProduct();

  //*base de datos
  DataBaseSqlite db = DataBaseSqlite();

  dynamic quantitySelected = 0;

  bool viewQuantity = false;
  bool isDialogVisible = false;

  //*terceros (contacto y propietario): páginas de una consulta a SQLite.
  //Son ~322 mil filas: ya no se cargan completas en memoria.
  List<Terceros> tercerosFilters = [];
  bool hayMasTerceros = false;
  static const _paginaTerceros = 50;
  String _queryTerceros = '';
  // Sube con cada búsqueda nueva: una página que llega tarde no se mezcla
  // con los resultados de otra búsqueda.
  int _busquedaTerceros = 0;

  /// Hay terceros descargados en SQLite (lo confirma
  /// [LoadTercerosFromDBEvent] o la descarga).
  bool hayTercerosLocales = false;

  bool isKeyboardVisible = false;

  //*lista de ubicaciones
  List<ResultUbicaciones> ubicaciones = [];
  List<ResultUbicaciones> ubicacionesFilters = [];

  //lista de lotes de un producto
  List<LotesProduct> listLotesProduct = [];
  List<LotesProduct> listLotesProductFilters = [];

  int tercerosCount = 0;
  // Propiedad persistente (no solo el estado transitorio) para que el
  // resumen operativo del Home no dependa de en qué momento exacto se
  // suscribe su BlocBuilder — mismo patrón que InventarioBloc.isLoading.
  bool isLoadingTerceros = false;

  /// [InitializeDevolucionesData] ya cargó los datos de este flujo. Las
  /// sub-pantallas (almacén, contacto, propietario, ubicación) vuelven con
  /// pushReplacementNamed, que recrea index.dart y vuelve a disparar el
  /// evento en su initState: sin esta bandera se recargaba todo y salía
  /// "Cargando terceros..." en cada regreso.
  bool _datosInicializados = false;

  DevolucionesRepository devolucionesRepository = DevolucionesRepository();
  final TercerosDownloadService _tercerosDownload = TercerosDownloadService();

  DevolucionesBloc() : super(DevolucionesInitial()) {
    on<DevolucionesEvent>((event, emit) {});

    // sequential: cada escaneo consulta SQLite; se resuelven en orden.
    on<GetProductEvent>(_onGetProductEvent, transformer: sequential());
    on<GetProductsList>(_onGetProductsBD);
    //evento para añadir un producto a la lista de devoluciones
    on<Addproduct>(_onAddProductEvent);
    //evento para eliminar un producto de la lista de devoluciones
    on<RemoveProduct>(_onRemoveProductEvent);
    //evento para pedir la cantidad del producto
    on<SetQuantityEvent>(_onSetQuantityEvent);

    ///evento para pedir el lote del producto
    on<SetLoteEvent>(_onSetLoteEvent);
    //*evento para ver la cantidad
    on<ShowQuantityEvent>(_onShowQuantityEvent);
    on<LoadCurrentProductEvent>(_onLoaadCurrentProductEvent);
    //evento para actualizar el producto
    on<UpdateProductInfoEvent>(_onUpdateProductInfoEvent);
    //evento para cargar todos los terceros
    //*activar el teclado
    //evento para seleccionar un tercero
    on<SelectTerceroEvent>(_onSelectTerceroEvent);
    //evento para buscar un tercero
    // restartable: cada tecla cancela la búsqueda anterior (debounce en el
    // handler).
    on<SearchTerceroEvent>(
      _onSearchTerceroEvent,
      transformer: restartable(),
    );
    on<LoadMoreTercerosEvent>(
      _onLoadMoreTercerosEvent,
      transformer: droppable(),
    );
    // evento para filtrar los terceros
    // on<FilterTercerosEvent>(_onFilterTercerosEvent);

    //*evento para cargar las ubicaciones
    on<LoadLocationsEvent>(_onLoadLocations);

    //*metodo para buscar una ubicacion
    on<SearchLocationEvent>(_onSearchLocationEvent);

    on<FilterUbicacionesEvent>(_onFilterUbicacionesEvent);

    //evento para seleccionar una ubicacion
    on<SelectLocationEvent>(_onSelectLocationEvent);

    on<SelectecLoteEvent>(_onChangeLoteIsOkEvent);
    //metodo para buscar un lote
    on<SearchLotevent>(_onSearchLoteEvent);

    //*metodo para crear un lote a un producto
    on<CreateLoteProduct>(_onCreateLoteProduct);

    //*metodo para obtener todos los lotes de un producto
    on<GetLotesProduct>(_onGetLotesProduct);

    //evento para limpiar los campos
    on<ClearValueEvent>(_onClearValueEvent);

    //*metodo para bucar un producto. restartable: cada tecla cancela la
    //búsqueda anterior (debounce en el handler).
    on<SearchProductEvent>(_onSearchProductEvent, transformer: restartable());
    on<LoadMoreProductsDevolucionEvent>(
      _onLoadMoreProductsEvent,
      transformer: droppable(),
    );

    //evento apra evniar la devolucion
    on<SendDevolucionEvent>(_onSendDevolucionEvent);

    on<ChangeStateIsDialogVisibleEvent>(_onChangeStateIsDialogVisibleEvent);

    on<LoadConfigurationsUser>(_onLoadConfigurationsUserEvent);

    on<InitializeDevolucionesData>(_onInitializeDevolucionesData);

    //metodo para descargar todos los terceros
    // droppable: InitializeDevolucionesData se dispara dos veces (diálogo del
    // home + initState de la pantalla) y, con la BD vacía, ambas cargas
    // lanzaban su propia descarga: dos descargas de ~45 MB a la vez que
    // duplican el pico de memoria (la app moría descargando terceros).
    on<DownloadAllTercerosEvent>(
      _onDownloadAllTercerosEvent,
      transformer: droppable(),
    );

    on<LoadTercerosCountEvent>(_onLoadTercerosCountEvent);
    //metodo para cargar los terceros desde la bd
    // droppable: leer 322 mil filas de SQLite dos veces en paralelo no aporta.
    on<LoadTercerosFromDBEvent>(
      _onLoadTercerosFromDBEvent,
      transformer: droppable(),
    );
    on<SelectPropietarioEvent>(_onSelectPropietarioEvent);
    on<ResetPropietarioEvent>(_onResetPropietarioEvent);
    on<LoadAllowedWarehousesEvent>(_onLoadAllowedWarehousesEvent);
    on<SelectWarehouseEvent>(_onSelectWarehouseEvent);
  }

  // ── Ciclo de vida ────────────────────────────────────────────────────────
  // El bloc se crea al entrar a una devolución y viaja como argumento entre
  // sus pantallas (pushReplacementNamed), así que ninguna pantalla puede
  // cerrarlo sola en su dispose. Cada DevolucionesScope se registra aquí y
  // el bloc se cierra cuando ya no queda ninguna (ver [detachScope]).
  int _scopeRefs = 0;

  void attachScope() => _scopeRefs++;

  /// Se llama al descartarse una pantalla del flujo. Si no queda ninguna
  /// activa tras un breve margen (la siguiente pantalla del flujo se monta
  /// mientras la anterior aún se está descartando), se sale del módulo.
  void detachScope() {
    _scopeRefs--;
    if (_scopeRefs > 0) return;
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      // isClosing (no isClosed): en bloc 9.2.0 isClosed sigue en false
      // mientras close() termina, y un segundo close() volvería a hacer
      // dispose de los controllers.
      if (_scopeRefs <= 0 && !isClosing) close();
    });
  }

  @override
  Future<void> close() {
    searchControllerLocation.dispose();
    searchControllerProducts.dispose();
    searchControllerTerceros.dispose();
    searchControllerLote.dispose();
    newLoteController.dispose();
    dateLoteController.dispose();
    searchControllerLocationDest.dispose();
    segundaUnidadController.dispose();
    searchControllerAlmacen.dispose();

    // Listas fuera de memoria al salir del módulo. Ubicaciones NO se
    // invalidan: es un caché compartido (Info Rápida, Conteo, etc.).
    tercerosFilters = [];
    productosFilters = [];
    ubicaciones = [];
    ubicacionesFilters = [];
    listLotesProduct = [];
    listLotesProductFilters = [];

    return super.close();
  }

  /// Revisa que haya terceros descargados en SQLite; si no hay, los
  /// descarga (una sola vez; después se consultan por página). Ya no se
  /// cargan en memoria: son ~322 mil filas.
  void _onLoadTercerosFromDBEvent(
    LoadTercerosFromDBEvent event,
    Emitter<DevolucionesState> emit,
  ) async {
    isLoadingTerceros = true;
    try {
      hayTercerosLocales = await db.tercerosRepository.hayTerceros();
      if (hayTercerosLocales) {
        emit(LoadTercerosFromDBSuccess(const []));
        return;
      }
      emit(
        LoadTercerosFromDBFailure(
          'No se encontraron terceros en la base de datos',
        ),
      );
      // Los terceros ya no se precargan al iniciar sesión: la primera vez
      // que se entra a Devoluciones la BD está vacía, así que se descargan
      // aquí (una sola vez; después se leen de SQLite).
      if (!isClosing) add(DownloadAllTercerosEvent());
    } catch (e, s) {
      debugPrint("❌ Error en _onLoadTercerosFromDBEvent: $e, $s");
      emit(
        LoadTercerosFromDBFailure(
          'Error al cargar terceros desde la base de datos: $e',
        ),
      );
    } finally {
      isLoadingTerceros = false;
    }
  }

  void _onDownloadAllTercerosEvent(
    DownloadAllTercerosEvent event,
    Emitter<DevolucionesState> emit,
  ) async {
    isLoadingTerceros = true;
    try {
      emit(DownloadAllTercerosLoading());

      // La lista descargada solo se usa para guardarla en SQLite: no se
      // retiene (ni en el bloc ni en el estado).
      final apiTerceros = await _tercerosDownload.download();
      tercerosCount = apiTerceros.length;
      hayTercerosLocales = true;

      emit(DownloadAllTercerosSuccess(const []));
    } on TercerosDownloadException catch (e) {
      emit(DownloadAllTercerosFailure(e.message));
    } catch (e, s) {
      debugPrint("❌ Error en _onDownloadAllTercerosEvent: $e, $s");
      emit(DownloadAllTercerosFailure('Error al descargar terceros: $e'));
    } finally {
      isLoadingTerceros = false;
    }
  }

  void _onLoadTercerosCountEvent(
    LoadTercerosCountEvent event,
    Emitter<DevolucionesState> emit,
  ) async {
    try {
      tercerosCount = await db.getTercerosCount();
      emit(LoadTercerosCountSuccess(tercerosCount));
    } catch (e) {
      debugPrint("❌ Error en _onLoadTercerosCountEvent: $e");
    }
  }

  void _onInitializeDevolucionesData(
    InitializeDevolucionesData event,
    Emitter<DevolucionesState> emit,
  ) async {
    // El bloc vive todo el flujo: los datos ya están cargados.
    if (_datosInicializados) return;
    _datosInicializados = true;
    try {
      // 1. Cargamos configuración
      add(LoadConfigurationsUser());

      // 2. Cargamos Ubicaciones desde BD
      add(LoadLocationsEvent());

      // 3. Productos ya agregados a la devolución (el catálogo se consulta
      // en SQLite al buscar o escanear, no se carga en memoria).
      add(GetProductsList());

      // 4. Terceros: solo se revisa que estén en SQLite (si no, se
      // descargan); se consultan por página al buscar o escanear.
      add(LoadTercerosFromDBEvent());
      add(LoadAllowedWarehousesEvent());
    } catch (e, s) {
      debugPrint("❌ Error en _onInitializeDevolucionesData: $e, $s");
    }
  }

  //* evento para cargar la configuracion del usuario
  void _onLoadConfigurationsUserEvent(
    LoadConfigurationsUser event,
    Emitter<DevolucionesState> emit,
  ) async {
    try {
      int userId = await PrefUtils.getUserId();
      final response = await getIt<ConfiguracionCacheService>()
          .getConfiguration(userId);

      if (response != null) {
        emit(ConfigurationDevLoaded(response));
        configurations = response;
      } else {
        emit(ConfigurationError('Error al cargar LoadConfigurationsUser'));
      }
    } catch (e, s) {
      debugPrint('❌ Error en LoadConfigurationsUser $e =>$s');
    }
  }

  void _onChangeStateIsDialogVisibleEvent(
    ChangeStateIsDialogVisibleEvent event,
    Emitter<DevolucionesState> emit,
  ) {
    isDialogVisible = event.isVisible;
    emit(ChangeStateIsDialogVisibleState(isDialogVisible));
  }

  void _onSendDevolucionEvent(
    SendDevolucionEvent event,
    Emitter<DevolucionesState> emit,
  ) async {
    try {
      emit(SendDevolucionLoading());

      final userid = await PrefUtils.getUserId();

      DateTime fechaTransaccion = DateTime.now();
      String fechaFormateada = formatoFecha(fechaTransaccion);

      final RequestSendDevolucionModel request = RequestSendDevolucionModel(
        idAlmacen: currentWarehouse.id ?? 0,
        idProveedor: currentTercero.id ?? 0,
        idUbicacionDestino: currentLocation.id ?? 0,
        idResponsable: userid,
        fechaInicio: fechaFormateada,
        fechaFin: fechaFormateada,
        idPropietario: currentPropietario.id ?? 0,
        listItems: productosDevolucion.map((product) {
          return ProductRequest(
            idProducto: product.productId ?? 0,
            idLote: product.lotId == 0 || product.lotId == null
                ? ""
                : product.lotId,
            ubicacionDestino: currentLocation.id ?? 0,
            cantidadEnviada: product.quantity ?? 0,
            idOperario: userid,
            timeLine: 1,
            fechaTransaccion: fechaFormateada,
            observacion: 'Sin novedad',
            quantitySegundaUnidad: product.quantitySegundaUnidad ?? 0.0,
          );
        }).toList(),
      );

      debugPrint("request: ${request.toJson()}");

      //enviamos la devolucion
      final response = await devolucionesRepository.sendDevolucion(
        request,
        true,
      );

      if (response.result?.code == 200) {
        // La devolución ya existe en Odoo: la tabla local se vacía acá y no
        // solo en ClearValueEvent. Si el operario salió durante el envío, el
        // add() se descarta con el bloc cerrándose y los productos quedaban
        // en SQLite: al volver a entrar aparecían de nuevo y se podían
        // enviar dos veces.
        await db.devolucionRepository.deleteAllProductosDevoluciones();
        //limpiamos los campos
        if (!isClosing) add(ClearValueEvent());
        emit(SendDevolucionSuccess(response));
      } else {
        if (response.result?.code == 403) {
          //emitimos un error de autorizacion
          emit(DeviceNotAuthorized());
          return;
        }

        emit(
          SendDevolucionFailure(
            response.result?.msg ?? 'Error desconocido al enviar la devolución',
          ),
        );
      }
    } catch (e, s) {
      debugPrint("❌ Error en _onSendDevolucionEvent: $e, $s");
      emit(SendDevolucionFailure('Error al enviar la devolución'));
    }
  }

  Future<List<Product>> _paginaDeProductos(String query, int offset) =>
      db.productoInventarioRepository.buscar(
        query: query,
        limit: _paginaProductos,
        offset: offset,
      );

  void _onSearchProductEvent(
    SearchProductEvent event,
    Emitter<DevolucionesState> emit,
  ) async {
    try {
      final busqueda = ++_busquedaProductos;
      emit(SearchLoading());
      // Debounce: si llega otra tecla, restartable cierra este emitter.
      if (event.query.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 250));
        if (emit.isDone) return;
      }

      final pagina = await _paginaDeProductos(event.query, 0);
      if (emit.isDone || busqueda != _busquedaProductos) return;

      _queryProductos = event.query;
      productosFilters = pagina;
      hayMasProductos = pagina.length == _paginaProductos;
      emit(SearchProductSuccess(productosFilters));
    } catch (e, s) {
      debugPrint('Error en el SearchProductEvent: $e, $s');
      emit(SearchFailure(e.toString()));
    }
  }

  void _onLoadMoreProductsEvent(
    LoadMoreProductsDevolucionEvent event,
    Emitter<DevolucionesState> emit,
  ) async {
    if (!hayMasProductos) return;
    final busqueda = _busquedaProductos;
    try {
      final pagina = await _paginaDeProductos(
        _queryProductos,
        productosFilters.length,
      );
      if (busqueda != _busquedaProductos) return;
      productosFilters = [...productosFilters, ...pagina];
      hayMasProductos = pagina.length == _paginaProductos;
      emit(SearchProductSuccess(productosFilters));
    } catch (e, s) {
      debugPrint('Error en LoadMoreProductsDevolucionEvent: $e, $s');
    }
  }

  //*metodo para limpiar los campos de busqueda
  void _onClearValueEvent(
    ClearValueEvent event,
    Emitter<DevolucionesState> emit,
  ) async {
    try {
      searchControllerLocation.clear();
      searchControllerProducts.clear();
      searchControllerTerceros.clear();
      searchControllerLote.clear();
      newLoteController.clear();
      dateLoteController.clear();
      searchControllerLocationDest.clear();
      segundaUnidadController.clear();
      scannedValue1 = '';
      scannedValue2 = '';
      viewQuantity = false;
      isKeyboardVisible = false;
      productIsOk = false;
      locationIsOk = false;
      almacenIsOk = false;
      contactoIsOk = false;
      propietarioIsOk = false;
      currentProduct = Product();
      currentTercero = Terceros();
      currentPropietario = Terceros();
      currentWarehouse = const AllowedWarehouse();
      currentLocation = ResultUbicaciones();
      lotesProductCurrent = LotesProduct();
      quantitySelected = 0;
      productosDevolucion.clear();
      _busquedaProductos++;
      productosFilters = [];
      hayMasProductos = false;
      listLotesProductFilters = listLotesProduct;
      ubicacionesFilters = ubicaciones;
      _busquedaTerceros++;
      tercerosFilters = [];
      hayMasTerceros = false;
      isDialogVisible = false;

      //limpiamos la tbla de productos devoluciones
      await db.devolucionRepository.deleteAllProductosDevoluciones();
      emit(ClearValueState());
    } catch (e, s) {
      debugPrint("❌ Error en _onClearScannedValueEvent: $e, $s");
    }
  }

  //*metodo para obtener todos los lotes de un producto
  void _onGetLotesProduct(
    GetLotesProduct event,
    Emitter<DevolucionesState> emit,
  ) async {
    try {
      emit(GetLotesProductLoading());
      final response = await devolucionesRepository.fetchAllLotesProduct(
        false,
        currentProduct.productId ?? 0,
      );

      if (response != null && response is List) {
        listLotesProduct = response;
        listLotesProductFilters = response;
        emit(GetLotesProductSuccess(response));
      } else {
        emit(GetLotesProductFailure('Error al obtener los lotes del producto'));
      }
    } catch (e, s) {
      emit(GetLotesProductFailure('Error al obtener los lotes del producto'));
      debugPrint('Error en el _onGetLotesProduct: $e, $s');
    }
  }

  //metodo pea crar un lote a un producto
  void _onCreateLoteProduct(
    CreateLoteProduct event,
    Emitter<DevolucionesState> emit,
  ) async {
    try {
      emit(CreateLoteProductLoading());

      final response = await devolucionesRepository.createLote(
        true,
        currentProduct.productId ?? 0,
        event.nameLote ?? "",
        event.fechaCaducidad ?? "",
        event.priorityExpiration,
      );

      if (response != null) {
        if (response.result?.code == 200) {
          // 1. Capturamos el nuevo lote de la respuesta
          final newLote = response.result?.result ?? LotesProduct();

          // 2. Agregamos el nuevo lote a la lista PRINCIPAL (Maestra)
          listLotesProduct.add(newLote);

          // 3. Actualizamos la lista de FILTROS creando una copia nueva de la principal
          // Esto garantiza que ambas listas tengan los mismos datos sin duplicar referencias
          listLotesProductFilters = List.from(listLotesProduct);

          // 4. Actualizamos el lote seleccionado actual
          lotesProductCurrent = newLote;

          // 5. Limpieza de controladores
          dateLoteController.clear();
          newLoteController.clear();

          // Recomendado: Limpiar el buscador para que coincida con la lista completa
          // searchControllerLote.clear();

          emit(CreateLoteProductSuccess(lotesProductCurrent));
        } else {
          emit(
            CreateLoteProductFailure(
              response.result?.msg ?? 'Error al crear el lote',
              response.result?.code ?? 0,
            ),
          );
        }
      } else {
        emit(CreateLoteProductFailure('Error al crear el lote', 400));
      }
    } catch (e, s) {
      emit(CreateLoteProductFailure('Error al crear el lote', 400));
      debugPrint('Error en el _onCreateLoteProduct: $e, $s');
    }
  }

  void _onSearchLoteEvent(
    SearchLotevent event,
    Emitter<DevolucionesState> emit,
  ) async {
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
      debugPrint('Error en el SearchLocationEvent: $e, $s');
      emit(SearchFailure(e.toString()));
    }
  }

  void _onChangeLoteIsOkEvent(
    SelectecLoteEvent event,
    Emitter<DevolucionesState> emit,
  ) async {
    //agregamos el lote al producto
    lotesProductCurrent = event.lote;
    dateLoteController.clear();
    newLoteController.clear();
    searchControllerLote.clear();

    debugPrint('Lote seleccionado: ${lotesProductCurrent.toMap()}');
    emit(SelectecLoteState(lotesProductCurrent));
  }

  //*metodo para seleccionar una ubicacion
  void _onSelectLocationEvent(
    SelectLocationEvent event,
    Emitter<DevolucionesState> emit,
  ) {
    try {
      currentLocation = event.location;
      searchControllerLocationDest.clear();
      scannedValue3 = '';
      locationIsOk = true;
      debugPrint('Ubicación seleccionada: ${currentLocation.toMap()}');
      emit(SelectLocationState(currentLocation));
    } catch (e, s) {
      debugPrint("❌ Error en _onSelectLocationEvent: $e, $s");
    }
  }

  //*metodo para filtrar las ubicaciones
  void _onFilterUbicacionesEvent(
    FilterUbicacionesEvent event,
    Emitter<DevolucionesState> emit,
  ) {
    try {
      debugPrint('Filtrando ubicaciones por almacen: ${event.almacen}');
      emit(FilterLocationsLoading());
      selectedAlmacen = '';
      ubicacionesFilters = [];
      ubicacionesFilters = ubicaciones;
      final query = event.almacen.toLowerCase();
      if (query.isEmpty) {
        ubicacionesFilters = ubicaciones;
      } else {
        ubicacionesFilters = ubicaciones.where((location) {
          return location.warehouseName?.toLowerCase().contains(query) ?? false;
        }).toList();
      }
      emit(FilterLocationsSuccess(ubicacionesFilters));
    } catch (e, s) {
      debugPrint('Error en el FilterUbicacionesEvent: $e, $s');
      emit(FilterLocationsFailure(e.toString()));
    }
  }

  void _onSearchLocationEvent(
    SearchLocationEvent event,
    Emitter<DevolucionesState> emit,
  ) async {
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
      debugPrint('Error en el SearchLocationEvent: $e, $s');
      emit(SearchFailure(e.toString()));
    }
  }

  void _onLoadLocations(
    LoadLocationsEvent event,
    Emitter<DevolucionesState> emit,
  ) async {
    try {
      emit(LoadingLocationsState());
      final response = await getIt<UbicacionesCacheService>().getAll();
      ubicaciones = response;
      ubicacionesFilters = response;
      if (response.isNotEmpty) {
        debugPrint('ubicaciones length: ${ubicaciones.length}');
        emit(LoadLocationsSuccessState(ubicaciones));
      } else {
        emit(LoadLocationsFailureState('No se encontraron ubicaciones'));
      }
    } catch (e, s) {
      emit(LoadLocationsFailureState('Error al cargar las ubicaciones'));
      debugPrint('Error en el fetch de ubicaciones: $e=>$s');
    }
  }

  //*metodo para buscar un tercero
  /// Tercero (contacto o propietario) por documento escaneado: consulta
  /// indexada en SQLite. `null` si no existe.
  Future<Terceros?> buscarTerceroPorDocumento(String documento) =>
      db.tercerosRepository.getByDocumento(documento);

  Future<List<Terceros>> _paginaDeTerceros(String query, int offset) =>
      db.tercerosRepository.buscar(
        query: query,
        limit: _paginaTerceros,
        offset: offset,
      );

  void _onSearchTerceroEvent(
    SearchTerceroEvent event,
    Emitter<DevolucionesState> emit,
  ) async {
    try {
      final busqueda = ++_busquedaTerceros;
      emit(SearchLoading());
      selectedAlmacen = '';
      // Debounce: si llega otra tecla, restartable cierra este emitter.
      if (event.query.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 250));
        if (emit.isDone) return;
      }

      final pagina = await _paginaDeTerceros(event.query, 0);
      if (emit.isDone || busqueda != _busquedaTerceros) return;

      _queryTerceros = event.query;
      tercerosFilters = pagina;
      hayMasTerceros = pagina.length == _paginaTerceros;
      emit(SearchTerceroSuccess(tercerosFilters));
    } catch (e, s) {
      debugPrint('Error en el SearchTerceroEvent: $e, $s');
      emit(SearchFailure(e.toString()));
    }
  }

  void _onLoadMoreTercerosEvent(
    LoadMoreTercerosEvent event,
    Emitter<DevolucionesState> emit,
  ) async {
    if (!hayMasTerceros) return;
    final busqueda = _busquedaTerceros;
    try {
      final pagina = await _paginaDeTerceros(
        _queryTerceros,
        tercerosFilters.length,
      );
      if (busqueda != _busquedaTerceros) return;
      tercerosFilters = [...tercerosFilters, ...pagina];
      hayMasTerceros = pagina.length == _paginaTerceros;
      emit(SearchTerceroSuccess(tercerosFilters));
    } catch (e, s) {
      debugPrint('Error en LoadMoreTercerosEvent: $e, $s');
    }
  }

  //*metodo para seleccionar un tercero
  void _onSelectTerceroEvent(
    SelectTerceroEvent event,
    Emitter<DevolucionesState> emit,
  ) {
    try {
      currentTercero = event.tercero;
      contactoIsOk = true;
      scannedValue4 = '';
      debugPrint('Tercero seleccionado: ${currentTercero.toMap()}');
      emit(SelectTerceroState(currentTercero));
    } catch (e, s) {
      debugPrint("❌ Error en _onSelectTerceroEvent: $e, $s");
    }
  }

  void _onSelectPropietarioEvent(
    SelectPropietarioEvent event,
    Emitter<DevolucionesState> emit,
  ) {
    try {
      currentPropietario = event.propietario;
      propietarioIsOk = true;
      productIsOk = true;
      debugPrint('Propietario seleccionado: ${currentPropietario.toMap()}');
      emit(SelectPropietarioState(currentPropietario));
    } catch (e, s) {
      debugPrint("❌ Error en _onSelectPropietarioEvent: $e, $s");
    }
  }

  void _onLoadAllowedWarehousesEvent(
    LoadAllowedWarehousesEvent event,
    Emitter<DevolucionesState> emit,
  ) async {
    try {
      emit(LoadAllowedWarehousesLoading());
      final response = await db.warehouseRepository.getAllowedWarehouse();
      allowedWarehouses = response;
      allowedWarehousesFilters = List.from(response);
      if (response.isNotEmpty) {
        emit(LoadAllowedWarehousesSuccess(response));
      } else {
        emit(LoadAllowedWarehousesFailure('No se encontraron almacenes'));
      }
    } catch (e, s) {
      debugPrint("❌ Error en _onLoadAllowedWarehousesEvent: $e, $s");
      emit(LoadAllowedWarehousesFailure('Error al cargar los almacenes'));
    }
  }

  void _onSelectWarehouseEvent(
    SelectWarehouseEvent event,
    Emitter<DevolucionesState> emit,
  ) {
    try {
      currentWarehouse = event.warehouse;
      almacenIsOk = true;
      searchControllerAlmacen.clear();
      allowedWarehousesFilters = List.from(allowedWarehouses);
      debugPrint(
        'Almacén seleccionado: ${currentWarehouse.id} - ${currentWarehouse.name}',
      );
      emit(SelectWarehouseState(currentWarehouse));
    } catch (e, s) {
      debugPrint("❌ Error en _onSelectWarehouseEvent: $e, $s");
    }
  }

  void _onResetPropietarioEvent(
    ResetPropietarioEvent event,
    Emitter<DevolucionesState> emit,
  ) {
    try {
      currentPropietario = Terceros();
      propietarioIsOk = false;
      productIsOk = false;
      isDialogVisible = false;
      emit(ResetPropietarioState());
    } catch (e, s) {
      debugPrint("❌ Error en _onResetPropietarioEvent: $e, $s");
    }
  }

  void _onUpdateProductInfoEvent(
    UpdateProductInfoEvent event,
    Emitter<DevolucionesState> emit,
  ) async {
    try {
      final qSegunda =
          double.tryParse(segundaUnidadController.text.trim()) ?? 0.0;
      //actualizamso el producto actual en la bd
      await db.devolucionRepository.updateProductoDevolucion(
        ProductDevolucion(
          productId: currentProduct.productId,
          barcode: currentProduct.barcode,
          name: currentProduct.name,
          quantity: event.isIncrement
              ? (currentProduct.quantity ?? 0) + (event.quantityManual ?? 0)
              : quantitySelected,
          code: currentProduct.code,
          category: currentProduct.category,
          lotId: lotesProductCurrent.id ?? 0,
          lotName: lotesProductCurrent.name ?? "",
          otherBarcodes: currentProduct.otherBarcodes,
          productPacking: currentProduct.productPacking,
          tracking: currentProduct.tracking,
          useExpirationDate: currentProduct.useExpirationDate,
          expirationTime: currentProduct.expirationTime,
          weight: currentProduct.weight,
          weightUomName: currentProduct.weightUomName,
          volume: currentProduct.volume,
          volumeUomName: currentProduct.volumeUomName,
          uom: currentProduct.uom,
          locationId: currentProduct.locationId,
          locationName: currentProduct.locationName,
          manejaSegundaUnidad: currentProduct.manejaSegundaUnidad,
          uomSegundaUnidad: currentProduct.uomSegundaUnidad,
          quantitySegundaUnidad: qSegunda,
        ),
      );
      //acutalizamos el producto actual en la lista de devoluciones
      final index = productosDevolucion.indexWhere(
        (p) => p.productId == currentProduct.productId,
      );
      if (index != -1) {
        productosDevolucion[index] = ProductDevolucion(
          productId: currentProduct.productId,
          barcode: currentProduct.barcode,
          name: currentProduct.name,
          quantity: event.isIncrement
              ? (currentProduct.quantity ?? 0) + (event.quantityManual ?? 0)
              : quantitySelected,
          code: currentProduct.code,
          category: currentProduct.category,
          lotId: lotesProductCurrent.id ?? 0,
          lotName: lotesProductCurrent.name ?? "",
          otherBarcodes: currentProduct.otherBarcodes,
          productPacking: currentProduct.productPacking,
          tracking: currentProduct.tracking,
          useExpirationDate: currentProduct.useExpirationDate,
          expirationTime: currentProduct.expirationTime,
          weight: currentProduct.weight,
          weightUomName: currentProduct.weightUomName,
          volume: currentProduct.volume,
          volumeUomName: currentProduct.volumeUomName,
          uom: currentProduct.uom,
          locationId: currentProduct.locationId,
          locationName: currentProduct.locationName,
          manejaSegundaUnidad: currentProduct.manejaSegundaUnidad,
          uomSegundaUnidad: currentProduct.uomSegundaUnidad,
          quantitySegundaUnidad: qSegunda,
        );
      }
      if (!isClosing) add(GetProductsList());

      emit(UpdateProductInfoState());
    } catch (e, s) {
      debugPrint("❌ Error en _onUpdateProductInfoEvent: $e, $s");
    }
  }

  void _onLoaadCurrentProductEvent(
    LoadCurrentProductEvent event,
    Emitter<DevolucionesState> emit,
  ) {
    try {
      currentProduct = event.product;
      quantitySelected = event.product.quantity ?? 0;
      if (event.product.tracking == 'lot') {
        lotesProductCurrent = LotesProduct(
          id: event.product.lotId,
          name: event.product.lotName,
          productId: event.product.productId,
          productName: event.product.name,
        );
        add(GetLotesProduct());
      }
      debugPrint('Producto actual cargado: ${currentProduct.toMap()}');
      emit(LoadCurrentProductState(currentProduct));
    } catch (e, s) {
      debugPrint("❌ Error en _onLoaadCurrentProductEvent: $e, $s");
    }
  }

  //*evento para ver la cantidad
  void _onShowQuantityEvent(
    ShowQuantityEvent event,
    Emitter<DevolucionesState> emit,
  ) {
    try {
      viewQuantity = !viewQuantity;
      emit(ShowQuantityState(viewQuantity));
    } catch (e, s) {
      debugPrint("❌ Error en _onShowQuantityEvent: $e, $s");
    }
  }

  void _onSetQuantityEvent(
    SetQuantityEvent event,
    Emitter<DevolucionesState> emit,
  ) {
    quantitySelected += 1;
    debugPrint('Cantidad seleccionada: $quantitySelected');
    emit(SetQuantityState());
  }

  void _onSetLoteEvent(SetLoteEvent event, Emitter<DevolucionesState> emit) {}

  void _onAddProductEvent(
    Addproduct event,
    Emitter<DevolucionesState> emit,
  ) async {
    //validamos que este producto no este ya en la lista de devoluciones

    if (productosDevolucion.any(
      (p) =>
          p.productId == event.product.productId &&
          p.lotId == event.product.lotId,
    )) {
      debugPrint('❌ El producto ya está en la lista de devoluciones');
      emit(
        AddProductFailure(
          'El producto ${event.product.name} ${event.product.tracking == 'lot' ? ' con lote ${event.product.lotName}' : ''} ya está en la lista de devoluciones. Para agregar el mismo producto con el mismo lote  debe realizarlo desde la opción de editar',
        ),
      );
      return;
    } else {
      //insertamos el producto en la base de datos

      await db.devolucionRepository.insertProductoDevolucion(event.product);
      productosDevolucion.add(event.product);
      debugPrint('Producto añadido: ${event.product.toMap()}');
      emit(AddProductSuccess(event.product));
    }
  }

  void _onRemoveProductEvent(
    RemoveProduct event,
    Emitter<DevolucionesState> emit,
  ) async {
    try {
      await db.devolucionRepository.deleteProductoDevolucion(
        event.product.productId ?? 0,
        event.product.lotId ?? 0,
      );
      productosDevolucion.removeWhere(
        (p) =>
            p.productId == event.product.productId &&
            p.lotId == event.product.lotId,
      );
      //eliminamos el producto de la base de datos
      debugPrint('Producto eliminado: ${event.product.toMap()}');
      emit(RemoveProductSuccess());
    } catch (e, s) {
      debugPrint("❌ Error en _onRemoveProductEvent: $e, $s");
    }
  }

  /// Producto elegido en la lista (por id) o escaneado (barcode, código o
  /// código alterno): consulta indexada en SQLite, sin catálogo en memoria.
  void _onGetProductEvent(
    GetProductEvent event,
    Emitter<DevolucionesState> emit,
  ) async {
    if (isDialogVisible) {
      debugPrint('Dialogo ya visible, no se puede buscar otro producto');
      return;
    }

    emit(GetProductLoading());

    lotesProductCurrent = LotesProduct();
    final repo = db.productoInventarioRepository;
    final product = event.isManual
        ? await repo.getProductById(event.idProduct)
        : await repo.getByCodigo(event.barcode);

    if (product == null) {
      debugPrint('❌ Producto no encontrado: ${event.barcode}');
      emit(GetProductFailure('Producto no encontrado'));
      if (event.isManual) scannedValue1 = '';
      return;
    }

    debugPrint('Producto encontrado: ${product.toMap()}');

    // Obtener todos los productos en devolución con el mismo productId
    final productosRelacionados = productosDevolucion
        .where((p) => p.productId == product.productId)
        .toList();
    if (productosRelacionados.isNotEmpty) {
      emit(
        GetProductExists(productosRelacionados.first, productosRelacionados),
      );
      return;
    }

    // Verificar si requiere lotes
    if (product.tracking == 'lot') {
      add(GetLotesProduct());
    }

    // Actualizar el producto actual
    currentProduct = product;
    viewQuantity = false;
    quantitySelected = 0;

    emit(GetProductSuccess(currentProduct, true));
  }

  /// Recarga los productos ya agregados a la devolución y avisa si no hay
  /// catálogo descargado. El catálogo ya no se carga en memoria: se consulta
  /// en SQLite al buscar o escanear.
  void _onGetProductsBD(
    GetProductsList event,
    Emitter<DevolucionesState> emit,
  ) async {
    try {
      emit(GetProductsLoading());
      productosDevolucion = await db.devolucionRepository
          .getAllProductosDevoluciones();
      debugPrint('productosDevolucion: ${productosDevolucion.length}');

      final catalogo = await db.productoInventarioRepository.buscar(limit: 1);
      if (catalogo.isNotEmpty) {
        emit(GetProductsSuccessDevo(const []));
      } else {
        emit(GetProductsFailure('No se encontraron productos'));
      }
    } catch (e, s) {
      emit(GetProductsFailure('Error al cargar los productos'));
      debugPrint('Error en el fetch de productos: $e=>$s');
    }
  }
}
