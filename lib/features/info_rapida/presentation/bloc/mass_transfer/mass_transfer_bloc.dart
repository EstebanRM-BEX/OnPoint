import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/features/info_rapida/domain/entities/catalogo_info.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida_params.dart';
import 'package:wms_app/features/info_rapida/domain/entities/transfer_results.dart';
import 'package:wms_app/features/info_rapida/domain/failures/info_rapida_failures.dart';
import 'package:wms_app/features/info_rapida/domain/rules/propietario_rules.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/crear_transferencia_masiva_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/get_catalogo_ubicaciones_usecase.dart';

part 'mass_transfer_event.dart';
part 'mass_transfer_state.dart';

@injectable
class MassTransferBloc extends Bloc<MassTransferEvent, MassTransferState> {
  final CrearTransferenciaMasivaUseCase crearTransferenciaMasiva;
  final GetCatalogoUbicacionesUseCase getCatalogoUbicaciones;

  MassTransferBloc({
    required this.crearTransferenciaMasiva,
    required this.getCatalogoUbicaciones,
  }) : super(const MassTransferState()) {
    on<MassTransferInicializado>(_onInicializado);
    on<CargarUbicacionesDestinoMassEvent>(_onCargarUbicacionesDestino);
    on<BuscarUbicacionDestinoMassEvent>(
      _onBuscarUbicacionDestino,
      transformer: restartable(),
    );
    on<FiltrarUbicacionesDestinoMassAlmacenEvent>(_onFiltrarAlmacen);
    on<SeleccionarUbicacionDestinoMassEvent>(_onSeleccionarUbicacionDestino);
    on<EscanearUbicacionDestinoMassEvent>(_onEscanearUbicacionDestino);
    on<ActualizarCantidadItemMassEvent>(_onActualizarCantidadItem);
    on<RemoverItemMassEvent>(_onRemoverItem);
    on<ConfirmarTransferenciaMasivaEvent>(
      _onConfirmarTransferenciaMasiva,
      transformer: droppable(),
    );
    on<LimpiarMensajeMassTransferEvent>(_onLimpiarMensaje);
  }

  Future<void> _onInicializado(
    MassTransferInicializado event,
    Emitter<MassTransferState> emit,
  ) async {
    final nowFormatted =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    final lineas = event.productosSeleccionados.map((p) {
      final disp = p.cantidad > 0 ? p.cantidad : p.cantidadMano;
      return ItemTransferenciaLinea(
        producto: p,
        cantidadATransferir: disp,
        cantidadValida: disp > 0,
      );
    }).toList();

    emit(state.copyWith(
      status: MassTransferStatus.ready,
      idAlmacen: event.idAlmacen,
      idUbicacionOrigen: event.idUbicacionOrigen,
      nombreUbicacionOrigen: event.nombreUbicacionOrigen,
      items: lineas,
      dateStart: nowFormatted,
      ubicacionDestino: () => null,
      ubicacionDestinoValida: false,
      mensajeError: () => null,
      failure: () => null,
    ));

    await _cargarDestinos(event.idUbicacionOrigen, emit);
  }

  Future<void> _onCargarUbicacionesDestino(
    CargarUbicacionesDestinoMassEvent event,
    Emitter<MassTransferState> emit,
  ) async {
    await _cargarDestinos(state.idUbicacionOrigen, emit);
  }

  Future<void> _cargarDestinos(
    int idOrigen,
    Emitter<MassTransferState> emit,
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
    BuscarUbicacionDestinoMassEvent event,
    Emitter<MassTransferState> emit,
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
    FiltrarUbicacionesDestinoMassAlmacenEvent event,
    Emitter<MassTransferState> emit,
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
    SeleccionarUbicacionDestinoMassEvent event,
    Emitter<MassTransferState> emit,
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
    EscanearUbicacionDestinoMassEvent event,
    Emitter<MassTransferState> emit,
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

  void _onActualizarCantidadItem(
    ActualizarCantidadItemMassEvent event,
    Emitter<MassTransferState> emit,
  ) {
    final nuevasLineas = state.items.map((linea) {
      if (linea.producto.id == event.productoId &&
          linea.producto.loteId == event.loteId) {
        final disp = linea.producto.cantidad > 0
            ? linea.producto.cantidad
            : linea.producto.cantidadMano;
        final valida = event.cantidad > 0 && event.cantidad <= disp;
        return linea.copyWith(
          cantidadATransferir: event.cantidad,
          cantidadValida: valida,
        );
      }
      return linea;
    }).toList();

    emit(state.copyWith(items: nuevasLineas));
  }

  void _onRemoverItem(
    RemoverItemMassEvent event,
    Emitter<MassTransferState> emit,
  ) {
    final nuevasLineas = state.items.where((linea) {
      final coincide = linea.producto.id == event.productoId &&
          linea.producto.loteId == event.loteId;
      return !coincide;
    }).toList();

    emit(state.copyWith(items: nuevasLineas));
  }

  Future<void> _onConfirmarTransferenciaMasiva(
    ConfirmarTransferenciaMasivaEvent event,
    Emitter<MassTransferState> emit,
  ) async {
    if (state.items.isEmpty) {
      final msg = 'No hay productos seleccionados para transferir';
      emit(state.copyWith(
        mensajeError: () => msg,
        failure: () => InfoRapidaValidationFailure(msg),
      ));
      return;
    }

    if (!state.ubicacionDestinoValida || state.ubicacionDestino == null) {
      final msg = 'Selecciona una ubicación destino válida';
      emit(state.copyWith(
        mensajeError: () => msg,
        failure: () => InfoRapidaValidationFailure(msg),
      ));
      return;
    }

    if (!state.todosItemsValidos) {
      final msg = 'Verifica que todas las cantidades sean mayores a 0 y válidas';
      emit(state.copyWith(
        mensajeError: () => msg,
        failure: () => InfoRapidaValidationFailure(msg),
      ));
      return;
    }

    // Validación de compatibilidad de propietarios
    final primerItem = state.items.first.producto;
    final baseKey = PropietarioRules.normalizeKey(
      tieneManejoPropietario: primerItem.manejoPropietario,
      propietario: primerItem.propietario,
    );

    for (final item in state.items) {
      final itemKey = PropietarioRules.normalizeKey(
        tieneManejoPropietario: item.producto.manejoPropietario,
        propietario: item.producto.propietario,
      );

      final errorMsg = PropietarioRules.validarCompatibilidad(
        keyExistente: baseKey,
        keyNuevo: itemKey,
      );

      if (errorMsg != null) {
        emit(state.copyWith(
          mensajeError: () => errorMsg,
          failure: () => PropietarioMismatchFailure(errorMsg),
        ));
        return;
      }
    }

    emit(state.copyWith(
      status: MassTransferStatus.loading,
      mensajeError: () => null,
      failure: () => null,
    ));

    final userId = await PrefUtils.getUserId();
    final nowFormatted =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    final itemsParams = state.items.map((it) {
      return ItemTransferenciaParams(
        idProducto: it.producto.id,
        cantidadEnviada: it.cantidadATransferir,
        idLote: it.producto.loteId ?? 0,
        timeLine: 0,
        idPropietario: it.producto.idPropietario ?? 0,
      );
    }).toList();

    final params = CrearTransferenciaMasivaParams(
      dateStart: state.dateStart ?? nowFormatted,
      dateEnd: nowFormatted,
      idAlmacen: state.idAlmacen,
      idUbicacionOrigen: state.idUbicacionOrigen,
      idUbicacionDestino: state.ubicacionDestino!.id,
      idOperario: userId,
      fechaTransaccion: nowFormatted,
      listItems: itemsParams,
    );

    final result = await crearTransferenciaMasiva(params);

    result.match(
      (failure) {
        emit(state.copyWith(
          status: MassTransferStatus.failure,
          mensajeError: () => failure.message,
          failure: () => failure,
        ));
      },
      (resultado) {
        emit(state.copyWith(
          status: MassTransferStatus.success,
          resultadoTransferencia: () => resultado,
          dateEnd: nowFormatted,
          mensajeError: () => null,
          failure: () => null,
        ));
      },
    );
  }

  void _onLimpiarMensaje(
    LimpiarMensajeMassTransferEvent event,
    Emitter<MassTransferState> emit,
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
