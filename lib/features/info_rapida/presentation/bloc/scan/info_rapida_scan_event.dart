part of 'info_rapida_scan_bloc.dart';

sealed class InfoRapidaScanEvent extends Equatable {
  const InfoRapidaScanEvent();

  @override
  List<Object?> get props => [];
}

/// Disparado al iniciar la pantalla principal de escaneo de Información Rápida.
///
/// Carga la configuración del usuario (permisos de edición) y el historial
/// de consultas recientes.
class InfoRapidaScanIniciado extends InfoRapidaScanEvent {
  const InfoRapidaScanIniciado();
}

/// Consulta al backend por código de barras escaneado o ingresado manualmente.
class ConsultarPorBarcodeEvent extends InfoRapidaScanEvent {
  final String barcode;

  const ConsultarPorBarcodeEvent(this.barcode);

  @override
  List<Object?> get props => [barcode];
}

/// Consulta al backend por ID numérico (usado desde catálogo o selecciones directas).
class ConsultarPorIdEvent extends InfoRapidaScanEvent {
  final int id;
  final bool isProduct;

  /// `false` en las consultas internas (refrescar tras una transferencia):
  /// no deben aparecer en "Últimas consultas".
  final bool guardarEnRecientes;

  const ConsultarPorIdEvent({
    required this.id,
    required this.isProduct,
    this.guardarEnRecientes = true,
  });

  @override
  List<Object?> get props => [id, isProduct, guardarEnRecientes];
}

/// Re-ejecuta una consulta almacenada en el historial de recientes.
class ConsultaRecienteSeleccionada extends InfoRapidaScanEvent {
  final RecentQuery query;

  const ConsultaRecienteSeleccionada(this.query);

  @override
  List<Object?> get props => [query];
}

/// Vuelve a leer "Últimas consultas". Las listas y los detalles consultan con
/// su propio bloc, así que al volver a la pantalla principal hay que recargar.
class RecargarConsultasRecientesEvent extends InfoRapidaScanEvent {
  const RecargarConsultasRecientesEvent();
}

/// Borra todas las consultas recientes del almacenamiento local.
class BorrarHistorialConsultasEvent extends InfoRapidaScanEvent {
  const BorrarHistorialConsultasEvent();
}

/// Resetea el resultado de escaneo actual para preparar una nueva búsqueda limpia.
class LimpiarResultadoScanEvent extends InfoRapidaScanEvent {
  const LimpiarResultadoScanEvent();
}
