part of 'info_rapida_scan_bloc.dart';

enum InfoRapidaScanStatus { initial, loading, success, failure }

class InfoRapidaScanState extends Equatable {
  final InfoRapidaScanStatus status;
  final InfoRapida? resultado;
  final List<RecentQuery> consultasRecientes;
  final ConfigInfoRapidaUsuario configuracion;
  final String? mensajeError;
  final Failure? failure;
  final String? ultimoBarcodeConsultado;

  const InfoRapidaScanState({
    this.status = InfoRapidaScanStatus.initial,
    this.resultado,
    this.consultasRecientes = const [],
    this.configuracion = const ConfigInfoRapidaUsuario(),
    this.mensajeError,
    this.failure,
    this.ultimoBarcodeConsultado,
  });

  bool get isLoading => status == InfoRapidaScanStatus.loading;
  bool get isSuccess => status == InfoRapidaScanStatus.success;
  bool get isFailure => status == InfoRapidaScanStatus.failure;

  /// Tipos de fallo reconocibles directamente por la UI para diálogos o navegaciones
  bool get isDispositivoNoAutorizado => failure is DispositivoNoAutorizadoFailure;
  bool get isSesionExpirada => failure is SesionExpiradaFailure;
  bool get isActualizarVersion => failure is ActualizarVersionFailure;
  bool get isNoEncontrado => failure is NoEncontradoFailure;
  bool get isSinConexion => failure is SinConexionFailure;

  InfoRapidaScanState copyWith({
    InfoRapidaScanStatus? status,
    InfoRapida? Function()? resultado,
    List<RecentQuery>? consultasRecientes,
    ConfigInfoRapidaUsuario? configuracion,
    String? Function()? mensajeError,
    Failure? Function()? failure,
    String? Function()? ultimoBarcodeConsultado,
  }) {
    return InfoRapidaScanState(
      status: status ?? this.status,
      resultado: resultado != null ? resultado() : this.resultado,
      consultasRecientes: consultasRecientes ?? this.consultasRecientes,
      configuracion: configuracion ?? this.configuracion,
      mensajeError: mensajeError != null ? mensajeError() : this.mensajeError,
      failure: failure != null ? failure() : this.failure,
      ultimoBarcodeConsultado: ultimoBarcodeConsultado != null
          ? ultimoBarcodeConsultado()
          : this.ultimoBarcodeConsultado,
    );
  }

  @override
  List<Object?> get props => [
        status,
        resultado,
        consultasRecientes,
        configuracion,
        mensajeError,
        failure,
        ultimoBarcodeConsultado,
      ];
}
