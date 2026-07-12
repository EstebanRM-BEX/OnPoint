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
  });
}
