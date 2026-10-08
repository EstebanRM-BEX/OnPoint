import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/features/info_rapida/domain/entities/catalogo_info.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida_params.dart';
import 'package:wms_app/features/info_rapida/domain/entities/transfer_results.dart';
import 'package:wms_app/features/info_rapida/domain/failures/info_rapida_failures.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/crear_transferencia_individual_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/get_catalogo_ubicaciones_usecase.dart';

part 'transfer_info_event.dart';
part 'transfer_info_state.dart';

@injectable
class TransferInfoBloc extends Bloc<TransferInfoEvent, TransferInfoState> {
  final CrearTransferenciaIndividualUseCase crearTransferencia;
  final GetCatalogoUbicacionesUseCase getCatalogoUbicaciones;

  TransferInfoBloc({
    required this.crearTransferencia,
    required this.getCatalogoUbicaciones,
  }) : super(const TransferInfoState()) {
    on<TransferInfoInicializado>(_onInicializado);
    on<CargarUbicacionesDestinoTransferEvent>(_onCargarUbicacionesDestino);
    on<BuscarUbicacionDestinoTransferEvent>(
      _onBuscarUbicacionDestino,
      transformer: restartable(),
    );
    on<FiltrarUbicacionesDestinoAlmacenEvent>(_onFiltrarAlmacen);
    on<SeleccionarUbicacionDestinoEvent>(_onSeleccionarUbicacionDestino);
    on<EscanearUbicacionDestinoEvent>(_onEscanearUbicacionDestino);
    on<CambiarCantidadTransferEvent>(_onCambiarCantidad);
    on<CambiarObservacionTransferEvent>(_onCambiarObservacion);
    on<ConfirmarTransferenciaIndividualEvent>(
      _onConfirmarTransferencia,
      transformer: droppable(),
    );
    on<LimpiarMensajeTransferEvent>(_onLimpiarMensaje);
  }

  Future<void> _onInicializado(
    TransferInfoInicializado event,
    Emitter<TransferInfoState> emit,
  ) async {
    final nowFormatted =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    emit(state.copyWith(
      status: TransferInfoStatus.ready,
      idAlmacen: event.idAlmacen,
      idMove: event.idMove,
      idProducto: event.idProducto,
      nombreProducto: event.nombreProducto,
      idLote: event.idLote,
      nombreLote: event.nombreLote,
      idUbicacionOrigen: event.idUbicacionOrigen,
      nombreUbicacionOrigen: event.nombreUbicacionOrigen,
      cantidadDisponible: event.cantidadDisponible,
      idPropietario: () => event.idPropietario,
      propietario: () => event.propietario,
      manejoPropietario: () => event.manejoPropietario,
      dateStart: nowFormatted,
      cantidadATransferir: 0.0,
      cantidadValida: false,
      ubicacionDestino: () => null,
      ubicacionDestinoValida: false,
      observacion: '',
      mensajeError: () => null,
      failure: () => null,
    ));

    await _cargarDestinos(event.idUbicacionOrigen, emit);
  }

  Future<void> _onCargarUbicacionesDestino(
    CargarUbicacionesDestinoTransferEvent event,
    Emitter<TransferInfoState> emit,
  ) async {
    await _cargarDestinos(state.idUbicacionOrigen, emit);
  }

  Future<void> _cargarDestinos(
    int idOrigen,
    Emitter<TransferInfoState> emit,
  ) async {
    final result = await getCatalogoUbicaciones(
      const GetCatalogoUbicacionesParams(),
    );

    result.match(
      (failure) {
        emit(state.copyWith(
          mensajeError: () => failure.message,
          failure: () => failure,
        ));
      },
      (ubicaciones) {
        final destinosValidos =
            ubicaciones.where((u) => u.id != idOrigen).toList();

        final almacenes = destinosValidos
            .map((u) => u.warehouseName?.trim())
            .where((w) => w != null && w.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList()
          ..sort();

        final filtradas = _filtrarUbicaciones(
          destinosValidos,
          query: state.queryUbicacionDestino,
          almacen: state.almacenDestinoFiltro,
        );

        emit(state.copyWith(
          ubicacionesDestino: destinosValidos,
          ubicacionesDestinoFiltradas: filtradas,
          almacenesDisponibles: almacenes,
        ));
      },
    );
  }

  void _onBuscarUbicacionDestino(
    BuscarUbicacionDestinoTransferEvent event,
    Emitter<TransferInfoState> emit,
  ) {
    final filtradas = _filtrarUbicaciones(
      state.ubicacionesDestino,
      query: event.query,
      almacen: state.almacenDestinoFiltro,
    );

    emit(state.copyWith(
      queryUbicacionDestino: event.query,
      ubicacionesDestinoFiltradas: filtradas,
    ));
  }

  void _onFiltrarAlmacen(
    FiltrarUbicacionesDestinoAlmacenEvent event,
    Emitter<TransferInfoState> emit,
  ) {
    final filtradas = _filtrarUbicaciones(
      state.ubicacionesDestino,
      query: state.queryUbicacionDestino,
      almacen: event.almacen,
    );

    emit(state.copyWith(
      almacenDestinoFiltro: () => event.almacen,
      ubicacionesDestinoFiltradas: filtradas,
    ));
  }

  void _onSeleccionarUbicacionDestino(
    SeleccionarUbicacionDestinoEvent event,
    Emitter<TransferInfoState> emit,
  ) {
    if (event.ubicacion.id == state.idUbicacionOrigen) {
      emit(state.copyWith(
        ubicacionDestino: () => null,
        ubicacionDestinoValida: false,
        mensajeError: () =>
            'La ubicación destino no puede ser la misma de origen',
        failure: () => const InfoRapidaValidationFailure(
          'La ubicación destino no puede ser la misma de origen',
        ),
      ));
      return;
    }

    emit(state.copyWith(
      ubicacionDestino: () => event.ubicacion,
      ubicacionDestinoValida: true,
      mensajeError: () => null,
      failure: () => null,
    ));
  }

  void _onEscanearUbicacionDestino(
    EscanearUbicacionDestinoEvent event,
    Emitter<TransferInfoState> emit,
  ) {
    final cleanBarcode = event.barcode.trim().toLowerCase();
    if (cleanBarcode.isEmpty) return;

    final encontrada = state.ubicacionesDestino.cast<UbicacionCatalogo?>().firstWhere(
          (u) => (u?.barcode ?? '').toLowerCase() == cleanBarcode,
          orElse: () => null,
        );

    if (encontrada == null) {
      emit(state.copyWith(
        mensajeError: () => 'Ubicación con código "$cleanBarcode" no encontrada',
        failure: () => InfoRapidaValidationFailure(
          'Ubicación con código "$cleanBarcode" no encontrada',
        ),
      ));
      return;
    }

    if (encontrada.id == state.idUbicacionOrigen) {
      emit(state.copyWith(
        ubicacionDestino: () => null,
        ubicacionDestinoValida: false,
        mensajeError: () =>
            'La ubicación destino no puede ser la misma de origen',
        failure: () => const InfoRapidaValidationFailure(
          'La ubicación destino no puede ser la misma de origen',
        ),
      ));
      return;
    }

    emit(state.copyWith(
      ubicacionDestino: () => encontrada,
      ubicacionDestinoValida: true,
      mensajeError: () => null,
      failure: () => null,
    ));
  }

  void _onCambiarCantidad(
    CambiarCantidadTransferEvent event,
    Emitter<TransferInfoState> emit,
  ) {
    final qty = event.cantidad;
    final esValida = qty > 0 && qty <= state.cantidadDisponible;

    String? errorMsg;
    Failure? failure;
    if (qty <= 0) {
      errorMsg = 'La cantidad a transferir debe ser mayor a 0';
      failure = InfoRapidaValidationFailure(errorMsg);
    } else if (qty > state.cantidadDisponible) {
      errorMsg =
          'La cantidad no puede superar la disponible (${state.cantidadDisponible})';
      failure = InfoRapidaValidationFailure(errorMsg);
    }

    emit(state.copyWith(
      cantidadATransferir: qty,
      cantidadValida: esValida,
      mensajeError: () => errorMsg,
      failure: () => failure,
    ));
  }

  void _onCambiarObservacion(
    CambiarObservacionTransferEvent event,
    Emitter<TransferInfoState> emit,
  ) {
    emit(state.copyWith(observacion: event.observacion));
  }

  Future<void> _onConfirmarTransferencia(
    ConfirmarTransferenciaIndividualEvent event,
    Emitter<TransferInfoState> emit,
  ) async {
    if (!state.puedeTransferir) {
      final msg = 'Verifica la ubicación destino y la cantidad antes de transferir';
      emit(state.copyWith(
        mensajeError: () => msg,
        failure: () => InfoRapidaValidationFailure(msg),
      ));
      return;
    }

    emit(state.copyWith(
      status: TransferInfoStatus.loading,
      mensajeError: () => null,
      failure: () => null,
    ));

    final userId = await PrefUtils.getUserId();
    final nowFormatted =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    final params = CrearTransferenciaIndividualParams(
      idAlmacen: state.idAlmacen,
      idMove: state.idMove,
      idProducto: state.idProducto,
      idLote: state.idLote,
      idUbicacionOrigen: state.idUbicacionOrigen,
      idUbicacionDestino: state.ubicacionDestino?.id,
      cantidadEnviada: state.cantidadATransferir,
      idOperario: userId,
      fechaTransaccion: nowFormatted,
      observacion: state.observacion,
      idPropietario: state.idPropietario ?? 0,
      dateStart: state.dateStart,
      dateEnd: nowFormatted,
    );

    final result = await crearTransferencia(params);

    result.match(
      (failure) {
        emit(state.copyWith(
          status: TransferInfoStatus.failure,
          mensajeError: () => failure.message,
          failure: () => failure,
        ));
      },
      (resultado) {
        emit(state.copyWith(
          status: TransferInfoStatus.success,
          resultadoTransferencia: () => resultado,
          dateEnd: nowFormatted,
          mensajeError: () => null,
          failure: () => null,
        ));
      },
    );
  }

  void _onLimpiarMensaje(
    LimpiarMensajeTransferEvent event,
    Emitter<TransferInfoState> emit,
  ) {
    emit(state.copyWith(
      mensajeError: () => null,
      failure: () => null,
    ));
  }

  List<UbicacionCatalogo> _filtrarUbicaciones(
    List<UbicacionCatalogo> items, {
    required String query,
    required String? almacen,
  }) {
    var resultado = items;

    if (almacen != null && almacen.trim().isNotEmpty) {
      final cleanAlmacen = almacen.trim().toLowerCase();
      resultado = resultado.where((u) {
        return (u.warehouseName ?? '').trim().toLowerCase() == cleanAlmacen;
      }).toList();
    }

    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isNotEmpty) {
      resultado = resultado.where((u) {
        final matchesName = u.name.toLowerCase().contains(cleanQuery);
        final matchesBarcode = (u.barcode ?? '').toLowerCase().contains(cleanQuery);
        return matchesName || matchesBarcode;
      }).toList();
    }

    return resultado;
  }
}
