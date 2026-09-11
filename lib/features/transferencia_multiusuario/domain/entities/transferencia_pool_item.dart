import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_asignacion_observacion.dart';

/// Un producto/tarea disponible ("libre") en el pool de una sesión de
/// transferencia multiusuario. Cuando otro operario lo toma, deja de
/// aparecer en POST /api/transfer/session/{id}/pool — el fetch siguiente lo
/// borra de la lista en memoria (el pool no se cachea local, es en vivo).
///
/// Espejo de RecepcionPoolItem, con un campo extra: [qtyAlmacenada]
/// (cantidad ya almacenada en el destino), que no existe en recepción.
///
/// [observaciones] es el historial de asignaciones de este producto —
/// vendrá vacío hasta que el tab "Terminados" lo necesite.
class TransferenciaPoolItem {
  final int? taskId;
  final int? sessionId;
  final int? productId;
  final String? productName;
  final String? defaultCode;
  final String? barcode;
  final double? qtyDemanded;
  final double? qtyAsignada;
  final double? qtyAlmacenada;
  final double? qtyRecibida;
  final double? qtyAvailable;
  final String? uom;
  final int? asignacionesActivas;
  final double? qtyClaimed;
  final double? qtyDone;
  final String? taskState;
  final bool? tieneObservaciones;
  final List<TransferenciaAsignacionObservacion> observaciones;

  const TransferenciaPoolItem({
    this.taskId,
    this.sessionId,
    this.productId,
    this.productName,
    this.defaultCode,
    this.barcode,
    this.qtyDemanded,
    this.qtyAsignada,
    this.qtyAlmacenada,
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
