import 'package:wms_app/features/recepcion_multiusuario/domain/entities/asignacion_observacion.dart';

/// Un producto/tarea disponible ("libre") en el pool de una sesión de
/// recepción multiusuario. Cuando otro operario lo toma, deja de aparecer en
/// GET /api/receipt/session/{id}/pool — el fetch siguiente lo borra local.
///
/// [observaciones] es el historial de asignaciones de este producto (de
/// cualquier operario, terminadas o no) — el tab "Terminados" lo usa
/// filtrando por `state == 'done'`.
class RecepcionPoolItem {
  final int? taskId;
  final int? sessionId;
  final int? productId;
  final String? productName;
  final String? defaultCode;
  final String? barcode;
  final double? qtyDemanded;
  final double? qtyAsignada;
  final double? qtyRecibida;
  final double? qtyAvailable;
  final String? uom;
  final int? asignacionesActivas;
  final double? qtyClaimed;
  final double? qtyDone;
  final String? taskState;
  final bool? tieneObservaciones;
  final List<AsignacionObservacion> observaciones;

  const RecepcionPoolItem({
    this.taskId,
    this.sessionId,
    this.productId,
    this.productName,
    this.defaultCode,
    this.barcode,
    this.qtyDemanded,
    this.qtyAsignada,
    this.qtyRecibida,
    this.qtyAvailable,
    this.uom,
    this.asignacionesActivas,
    this.qtyClaimed,
    this.qtyDone,
    this.taskState,
    this.tieneObservaciones,
    this.observaciones = const [],
  });
}
