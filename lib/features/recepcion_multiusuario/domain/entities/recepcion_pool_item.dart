/// Un producto/tarea disponible ("libre") en el pool de una sesión de
/// recepción multiusuario. Cuando otro operario lo toma, deja de aparecer en
/// GET /api/receipt/session/{id}/pool — el fetch siguiente lo borra local.
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
  });
}
