/// Resultado de reclamar ("tomar") un producto libre de una sesión de
/// recepción multiusuario (POST /api/receipt/claim). Mientras
/// [bloqueadoHasta] no venza, el producto queda bloqueado para el operario
/// que lo reclamó — nadie más puede tomarlo.
class RecepcionClaim {
  final int? id;
  final int? taskId;
  final int? productId;
  final String? productName;
  final String? barcode;
  final double? qtyAsignada;
  final double? qtyRecibida;
  final String? uom;
  final String? state;
  final int? lotId;
  final String? lotName;
  final String? fechaAsignacion;
  final String? bloqueadoHasta;
  final String? observacion;
  final String? notaCorreccion;

  const RecepcionClaim({
    this.id,
    this.taskId,
    this.productId,
    this.productName,
    this.barcode,
    this.qtyAsignada,
    this.qtyRecibida,
    this.uom,
    this.state,
    this.lotId,
    this.lotName,
    this.fechaAsignacion,
    this.bloqueadoHasta,
    this.observacion,
    this.notaCorreccion,
  });

  /// true si este producto maneja lote (lot_id llega en `false` cuando no).
  bool get manejaLote => lotId != null;
}
