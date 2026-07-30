/// Producto suelto (no asignado a ningún paquete) de una expedición —
/// listas `items_validados`/`items_pendientes` del response.
class ItemSueltoExpedicion {
  final int? expeditionId;
  final int? packingId;
  final String? productName;
  final String? productCode;
  final String? barcode;
  final int? orderPacking;
  final double? quantity;
  final String? uom;
  final bool? isValidate;

  /// true = validado sin conexión, aún pendiente de enviar al backend.
  /// Con isValidate=true vive en "Listo" pero marcado como "por enviar".
  final bool? syncPending;

  const ItemSueltoExpedicion({
    this.expeditionId,
    this.packingId,
    this.productName,
    this.productCode,
    this.barcode,
    this.orderPacking,
    this.quantity,
    this.uom,
    this.isValidate,
    this.syncPending,
  });
}
