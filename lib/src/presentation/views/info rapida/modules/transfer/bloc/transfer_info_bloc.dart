import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:wms_app/core/utils/formats_utils.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/data/info_rapida_repository.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/models/transfer_info_request.dart';

part 'transfer_info_event.dart';
part 'transfer_info_state.dart';

class TransferInfoBloc extends Bloc<TransferInfoEvent, TransferInfoState> {
  bool isLocationDestOk = true;
  bool locationDestIsOk = false;

  bool quantityIsOk = true;
  dynamic quantitySelected = 0;
  String scannedValue1 = '';
  String selectedAlmacen = '';

  String dateStartProduct = '';
  String dateStart = '';

  ResultUbicaciones selectedLocationDest = ResultUbicaciones();

  //*lista de ubicaciones
  List<ResultUbicaciones> ubicaciones = [];
  List<ResultUbicaciones> ubicacionesFilters = [];

  //*valores de scanvalue
  final InfoRapidaRepository repository = InfoRapidaRepository();

  TextEditingController searchControllerLocationDest = TextEditingController();

  DataBaseSqlite db = DataBaseSqlite();

  bool isKeyboardVisible = false;

  TransferInfoBloc() : super(TransferInfoInitial()) {
    on<TransferInfoEvent>((event, emit) {
    });

    //*evento para actualizar el valor del scan
    on<UpdateScannedValueEventTransfer>(_onUpdateScannedValueEvent);
    on<ClearScannedValueEventTransfer>(_onClearScannedValueEvent);
    //*metodo para cargar las ubicaciones
    on<LoadLocationsTransfer>(_onLoadLocations);
    on<ValidateFieldsEventTransfer>(_onValidateFields);

    on<ChangeLocationDestIsOkEventTransfer>(_onChangeLocationDestIsOkEvent);
    on<SendTransferInfo>(_onSetQuantity);
    add(LoadLocationsTransfer());
    //*activar el teclado
    on<ShowKeyboardEvent>(_onShowKeyboardEvent);
    //*metodo para buscar una ubicacion
    on<SearchLocationEvent>(_onSearchLocationEvent);
    //metodo para filtrar las ubicaciones por almacen
    on<FilterUbicacionesEvent>(_onFilterUbicacionesEvent);
    //evento para asignar el timepo de inicio de la transferencia
    on<SetDateStartEventTransfer>(_onSetDateStartEventTransfer);
  }

  void _onSetDateStartEventTransfer(
      SetDateStartEventTransfer event, Emitter<TransferInfoState> emit) {
    try {
      //actualizamos la fecha de inicio
      DateTime fechaActual = DateTime.now();
      //la convertimos en el formato  yyyy-MM-dd HH:mm:ss

      dateStart = formatoFecha(fechaActual);
      emit(SetDateStartStateTransfer(dateStart));
    } catch (e, s) {
      print("❌ Error en el SetDateStartEventTransfer $e ->$s");
    }
  }

  void _onFilterUbicacionesEvent(
      FilterUbicacionesEvent event, Emitter<TransferInfoState> emit) {
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

  void _onSearchLocationEvent(
      SearchLocationEvent event, Emitter<TransferInfoState> emit) async {
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

  //*metodo para ocultar y mostrar el teclado
  void _onShowKeyboardEvent(
      ShowKeyboardEvent event, Emitter<TransferInfoState> emit) {
    isKeyboardVisible = event.showKeyboard;
    emit(ShowKeyboardState(showKeyboard: isKeyboardVisible));
  }

  void _onSetQuantity(
      SendTransferInfo event, Emitter<TransferInfoState> emit) async {
    try {
      emit(SendTransferInfoLoadingTransfer());
      quantitySelected = event.quantity;

      final userid = await PrefUtils.getUserId();

      //calculamos la fecha de transaccion
      DateTime fechaTransaccion = DateTime.now();
      String fechaFormateada = formatoFecha(fechaTransaccion);

      final responseSend = await repository.sendProductTransferInfo(
          TransferInfoRequest(
            idAlmacen: event.request.idAlmacen,
            idMove: event.request.idMove,
            idProducto: event.request.idProducto,
            idLote: event.request.idLote,
            idUbicacionOrigen: event.request.idUbicacionOrigen,
            idUbicacionDestino: selectedLocationDest.id,
            cantidadEnviada: quantitySelected,
            idOperario: userid,
            timeLine: event.request.timeLine,
            fechaTransaccion: fechaFormateada,
            observacion: event.request.observacion,
            dateStart: dateStart,
            dateEnd:
                //'yyyy-MM-dd HH:mm:ss'
                formatoFecha(DateTime.now()),
          ),
          true);

      if (responseSend.result?.code == 200) {
        //limpiamos los valores
        clearFields();

        emit(SendTransferInfoSuccess(responseSend.result?.msg ?? "",
            responseSend.result?.idProducto ?? 0));
      } else {
        emit(SendTransferInfoFailureTransfer(responseSend.result?.msg ?? ""));
      }
    } catch (e, s) {
      print("❌ Error en el SetQuantity $e ->$s");
    }
  }

  void clearFields() {
    scannedValue1 = '';
    quantitySelected = 0;
    selectedLocationDest = ResultUbicaciones();
    locationDestIsOk = false;
    dateStartProduct = '';
    dateStart = '';
  }

  void _onChangeLocationDestIsOkEvent(ChangeLocationDestIsOkEventTransfer event,
      Emitter<TransferInfoState> emit) async {
    try {
      locationDestIsOk = event.locationDestIsOk;
      selectedLocationDest = event.location;

      //actualizamos la fecha de inicio
      DateTime fechaActual = DateTime.now();
      dateStartProduct = fechaActual.toString();

      emit(ChangeLocationDestIsOkStateTransfer(
        locationDestIsOk,
      ));
    } catch (e, s) {
      print("❌ Error en el ChangeLocationDestIsOkEvent $e ->$s");
    }
  }

  //*evento para actualizar el valor del scan
  void _onUpdateScannedValueEvent(
      UpdateScannedValueEventTransfer event, Emitter<TransferInfoState> emit) {
    try {
      switch (event.scan) {
        case 'muelle':
          scannedValue1 += event.scannedValue;
          emit(UpdateScannedValueStateTransfer(scannedValue1, event.scan));
          break;
        default:
          print('Scan type not recognized: ${event.scan}');
      }
    } catch (e, s) {
      print("❌ Error en _onUpdateScannedValueEvent: $e, $s");
    }
  }

//*evento para limpiar el valor del scan
  void _onClearScannedValueEvent(
      ClearScannedValueEventTransfer event, Emitter<TransferInfoState> emit) {
    try {
      switch (event.scan) {
        case 'muelle':
          scannedValue1 = '';
          emit(ClearScannedValueStateTransfer());
          break;
        default:
          print('Scan type not recognized: ${event.scan}');
      }
      emit(ClearScannedValueStateTransfer());
    } catch (e, s) {
      print("❌ Error en _onClearScannedValueEvent: $e, $s");
    }
  }

  void _onLoadLocations(
      LoadLocationsTransfer event, Emitter<TransferInfoState> emit) async {
    try {
      emit(LoadLocationsLoadingTransfer());
      final response = await db.ubicacionesRepository.getAllUbicaciones();
      ubicaciones.clear();
      ubicacionesFilters.clear();
      if (response.isNotEmpty) {
        ubicaciones = response;
        ubicacionesFilters = response;
        print('ubicaciones length: ${ubicaciones.length}');
        emit(LoadLocationsSuccessTransfer(ubicaciones));
      } else {
        emit(LoadLocationsFailureTransfer('No se encontraron ubicaciones'));
      }
    } catch (e, s) {
      emit(LoadLocationsFailureTransfer('Error al cargar las ubicaciones'));
      print('Error en el fetch de ubicaciones: $e=>$s');
    }
  }

  void _onValidateFields(
      ValidateFieldsEventTransfer event, Emitter<TransferInfoState> emit) {
    try {
      switch (event.field) {
        case 'muelle':
          isLocationDestOk = event.isOk;
          break;
      }
      emit(ValidateFieldsStateSuccessTransfer(event.isOk));
    } catch (e, s) {
      emit(ValidateFieldsStateErrorTransfer('Error al validar campos'));
      print("❌ Error en el ValidateFieldsEvent $e ->$s");
    }
  }
}
