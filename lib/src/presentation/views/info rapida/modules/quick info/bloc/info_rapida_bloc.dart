import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:wms_app/src/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/data/info_rapida_repository.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/models/info_rapida_model.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/models/update_product_request.dart';
import 'package:wms_app/src/presentation/views/inventario/data/inventario_repository.dart';
import 'package:wms_app/src/presentation/views/inventario/models/response_products_model.dart';
import 'package:wms_app/src/presentation/views/user/models/configuration.dart';

part 'info_rapida_event.dart';
part 'info_rapida_state.dart';

class InfoRapidaBloc extends Bloc<InfoRapidaEvent, InfoRapidaState> {
  final InfoRapidaRepository _infoRapidaRepository = InfoRapidaRepository();

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

  //*base de datos
  DataBaseSqlite db = DataBaseSqlite();

  bool isKeyboardVisible = false;
  bool isEdit = false;
  bool isNumericKeyboardType = false;
  bool isExpanded = false;

  bool isAscending = true;

  TextEditingController? controllerActivo;

  //*configuracion del usuario //permisos
  Configurations configurations = Configurations();

  //repositorio de inventario
  InventarioRepository inventarioRepository = InventarioRepository();

  InfoRapidaBloc() : super(InfoRapidaInitial()) {
    on<InfoRapidaEvent>((event, emit) {});

    //*evento para actualizar el valor del scan
    on<UpdateScannedValueEvent>(_onUpdateScannedValueEvent);
    on<ClearScannedValueEvent>(_onClearScannedValueEvent);

    on<GetInfoRapida>(_onGetInfoRapida);

    //metodo para buscar una ubicacion
    on<SearchLocationEvent>(_onSearchLocationEvent);

    //*activar el teclado
    on<ShowKeyboardInfoEvent>(_onShowKeyboardEvent);
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

    //metodo para ordenar de formar ascendente o descendente las ubicaciones
    on<SortLocationsEvent>(_onSortLocationsEvent);

    //metodo para ordenar de forma ascendente o descendente los productos
    on<SortProductsEvent>(_onSortProductsEvent);

    //metodo para ver la url de un producto
    on<ViewProductImageEvent>(_onViewProductImageEvent);
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
        await db.ubicacionesRepository
            .insertOrUpdateSingle(
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
      final response = await db.ubicacionesRepository.getAllUbicaciones();
      ubicaciones.clear();
      ubicacionesFilters.clear();
      print('ubicaciones length: ${ubicaciones.length}');
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

  void _onShowKeyboardEvent(
      ShowKeyboardInfoEvent event, Emitter<InfoRapidaState> emit) {
    isKeyboardVisible = event.showKeyboard;
    isNumericKeyboardType = event.isNumeric;
    controllerActivo = event.controllerActivo;
    emit(ShowKeyboardState(showKeyboard: isKeyboardVisible));
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

      print('manual: ${event.isManual}');
      print('is product: ${event.isProduct}');
      print('barcode: ${event.barcode.trim()}');

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

      add(ClearScannedValueEvent());
    } catch (e) {
      emit(InfoRapidaError());
    }
  }

  void _onUpdateScannedValueEvent(
      UpdateScannedValueEvent event, Emitter<InfoRapidaState> emit) {
    scannedValue1 += event.scannedValue.trim();
    print('scannedValue1: $scannedValue1');
    emit(UpdateScannedValueState(scannedValue1));
  }

  void _onClearScannedValueEvent(
      ClearScannedValueEvent event, Emitter<InfoRapidaState> emit) {
    scannedValue1 = '';
    emit(ClearScannedValueState());
  }



void _onSortLocationsEvent(
      SortLocationsEvent event, Emitter<InfoRapidaState> emit) {
    try {
      print('Ordenando ubicaciones por: ${event.criteria}, ascending: ${event.ascending}');
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
              final dateA = DateTime.tryParse(a.fechaCaducidad ?? '') ?? DateTime(1900);
              final dateB = DateTime.tryParse(b.fechaCaducidad ?? '') ?? DateTime(1900);
              return dateA.compareTo(dateB);
              
            case 'location':
            default:
              // Por defecto ordenar por nombre de ubicación
              return (a.ubicacion ?? '').compareTo(b.ubicacion ?? '');
          }
        }

        // Aplicar el ordenamiento
        if (event.ascending) {
          locations.sort((a, b) => compare(a, b));
          isAscending = true;
        } else {
          locations.sort((a, b) => compare(b, a)); // Invertimos a y b para descendente
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
