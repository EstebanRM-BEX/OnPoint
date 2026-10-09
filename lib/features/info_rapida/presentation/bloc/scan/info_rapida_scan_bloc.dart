import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:wms_app/core/bloc/safe_bloc_mixin.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/info_rapida/domain/entities/config_info_rapida_usuario.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/domain/entities/recent_query.dart';
import 'package:wms_app/features/info_rapida/domain/failures/info_rapida_failures.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/borrar_consultas_recientes_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/consultar_por_barcode_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/consultar_por_id_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/get_configuracion_usuario_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/get_consultas_recientes_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/guardar_consulta_reciente_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/precargar_catalogos_usecase.dart';

part 'info_rapida_scan_event.dart';
part 'info_rapida_scan_state.dart';

@injectable
class InfoRapidaScanBloc
    extends Bloc<InfoRapidaScanEvent, InfoRapidaScanState>
    with SafeBlocMixin<InfoRapidaScanEvent, InfoRapidaScanState> {
  final ConsultarPorBarcodeUseCase consultarPorBarcode;
  final ConsultarPorIdUseCase consultarPorId;
  final GetConsultasRecientesUseCase getConsultasRecientes;
  final GuardarConsultaRecienteUseCase guardarConsultaReciente;
  final BorrarConsultasRecientesUseCase borrarConsultasRecientes;
  final GetConfiguracionUsuarioUseCase getConfiguracionUsuario;
  final PrecargarCatalogosUseCase precargarCatalogos;

  InfoRapidaScanBloc({
    required this.consultarPorBarcode,
    required this.consultarPorId,
    required this.getConsultasRecientes,
    required this.guardarConsultaReciente,
    required this.borrarConsultasRecientes,
    required this.getConfiguracionUsuario,
    required this.precargarCatalogos,
  }) : super(const InfoRapidaScanState()) {
    on<InfoRapidaScanIniciado>(_onIniciado);
    on<ConsultarPorBarcodeEvent>(
      _onConsultarPorBarcode,
      transformer: restartable(),
    );
    on<ConsultarPorIdEvent>(
      _onConsultarPorId,
      transformer: restartable(),
    );
    on<ConsultaRecienteSeleccionada>(
      _onConsultaRecienteSeleccionada,
      transformer: restartable(),
    );
    on<RecargarConsultasRecientesEvent>(
      _onRecargarRecientes,
      transformer: restartable(),
    );
    on<BorrarHistorialConsultasEvent>(_onBorrarHistorial);
    on<LimpiarResultadoScanEvent>(_onLimpiarResultado);
  }

  Future<void> _onIniciado(
    InfoRapidaScanIniciado event,
    Emitter<InfoRapidaScanState> emit,
  ) async {
    final configResult = await getConfiguracionUsuario(
      const GetConfiguracionUsuarioParams(),
    );
    final config = configResult.match(
      (_) => const ConfigInfoRapidaUsuario(),
      (c) => c,
    );

    final recientesResult = await getConsultasRecientes(NoParams());
    final recientes = recientesResult.match(
      (_) => <RecentQuery>[],
      (r) => r,
    );

    emit(state.copyWith(
      configuracion: config,
      consultasRecientes: recientes,
    ));

    // Al entrar se cargan las ubicaciones en memoria (los productos se
    // consultan en SQLite al buscar). Si ya estaban responde al instante y no
    // se muestra el "Cargando…".
    final precarga = precargarCatalogos(NoParams());
    final rapida = await Future.any([
      precarga.then((_) => true),
      Future.delayed(const Duration(milliseconds: 150), () => false),
    ]);
    if (rapida) return;

    emit(state.copyWith(cargandoCatalogos: true));
    await precarga;
    emit(state.copyWith(cargandoCatalogos: false));
  }

  Future<void> _onConsultarPorBarcode(
    ConsultarPorBarcodeEvent event,
    Emitter<InfoRapidaScanState> emit,
  ) async {
    await _ejecutarConsultaPorBarcode(
      barcode: event.barcode,
      emit: emit,
    );
  }

  Future<void> _onConsultarPorId(
    ConsultarPorIdEvent event,
    Emitter<InfoRapidaScanState> emit,
  ) async {
    await _ejecutarConsultaPorId(
      id: event.id,
      isProduct: event.isProduct,
      guardarEnRecientes: event.guardarEnRecientes,
      emit: emit,
    );
  }

  Future<void> _onConsultaRecienteSeleccionada(
    ConsultaRecienteSeleccionada event,
    Emitter<InfoRapidaScanState> emit,
  ) async {
    final query = event.query;
    if (query.isManual) {
      final id = int.tryParse(query.query);
      if (id != null) {
        await _ejecutarConsultaPorId(
          id: id,
          isProduct: query.isProduct,
          emit: emit,
        );
      }
    } else {
      await _ejecutarConsultaPorBarcode(
        barcode: query.query,
        emit: emit,
      );
    }
  }

  Future<void> _ejecutarConsultaPorBarcode({
    required String barcode,
    required Emitter<InfoRapidaScanState> emit,
  }) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) return;

    emit(state.copyWith(
      status: InfoRapidaScanStatus.loading,
      ultimoBarcodeConsultado: () => cleanBarcode,
      mensajeError: () => null,
      failure: () => null,
    ));

    final result = await consultarPorBarcode(
      ConsultarPorBarcodeParams(barcode: cleanBarcode),
    );

    await result.match(
      (failure) async {
        emit(state.copyWith(
          status: InfoRapidaScanStatus.failure,
          mensajeError: () => failure.message,
          failure: () => failure,
        ));
      },
      (info) async {
        await _guardarEnRecientes(info, query: cleanBarcode, isManual: false);
        final recientesActualizados = await _obtenerRecientesActualizados();

        emit(state.copyWith(
          status: InfoRapidaScanStatus.success,
          resultado: () => info,
          consultasRecientes: recientesActualizados,
          mensajeError: () => null,
          failure: () => null,
        ));
      },
    );
  }

  Future<void> _ejecutarConsultaPorId({
    required int id,
    required bool isProduct,
    required Emitter<InfoRapidaScanState> emit,
    bool guardarEnRecientes = true,
  }) async {
    emit(state.copyWith(
      status: InfoRapidaScanStatus.loading,
      mensajeError: () => null,
      failure: () => null,
    ));

    final result = await consultarPorId(
      ConsultarPorIdParams(id: id, isProduct: isProduct),
    );

    await result.match(
      (failure) async {
        emit(state.copyWith(
          status: InfoRapidaScanStatus.failure,
          mensajeError: () => failure.message,
          failure: () => failure,
        ));
      },
      (info) async {
        if (guardarEnRecientes) {
          await _guardarEnRecientes(
            info,
            query: id.toString(),
            isManual: true,
            isProduct: isProduct,
          );
        }
        final recientesActualizados = guardarEnRecientes
            ? await _obtenerRecientesActualizados()
            : state.consultasRecientes;

        emit(state.copyWith(
          status: InfoRapidaScanStatus.success,
          resultado: () => info,
          consultasRecientes: recientesActualizados,
          mensajeError: () => null,
          failure: () => null,
        ));
      },
    );
  }

  Future<void> _onRecargarRecientes(
    RecargarConsultasRecientesEvent event,
    Emitter<InfoRapidaScanState> emit,
  ) async {
    emit(state.copyWith(
      consultasRecientes: await _obtenerRecientesActualizados(),
    ));
  }

  Future<void> _onBorrarHistorial(
    BorrarHistorialConsultasEvent event,
    Emitter<InfoRapidaScanState> emit,
  ) async {
    await borrarConsultasRecientes(NoParams());
    emit(state.copyWith(
      consultasRecientes: const [],
    ));
  }

  void _onLimpiarResultado(
    LimpiarResultadoScanEvent event,
    Emitter<InfoRapidaScanState> emit,
  ) {
    emit(state.copyWith(
      status: InfoRapidaScanStatus.initial,
      resultado: () => null,
      mensajeError: () => null,
      failure: () => null,
    ));
  }

  Future<void> _guardarEnRecientes(
    InfoRapida info, {
    required String query,
    required bool isManual,
    bool isProduct = true,
  }) async {
    final recent = RecentQuery.fromInfo(
      query: query,
      isManual: isManual,
      info: info,
    );

    await guardarConsultaReciente(GuardarConsultaRecienteParams(query: recent));
  }

  Future<List<RecentQuery>> _obtenerRecientesActualizados() async {
    final result = await getConsultasRecientes(NoParams());
    return result.match(
      (_) => state.consultasRecientes,
      (r) => r,
    );
  }
}
