class ItemExpedicion {
  final int? packingId;
  final String? packageName;
  final int? expeditionId;
  final bool? isValidate;
  final int? productoId;
  final String? productName;
  final String? productCode;
  final String? barcode;
  final String? tracking;
  final int? diasVencimiento;
  final double? quantity;
  final String? uom;

  const ItemExpedicion({
    this.packingId,
    this.packageName,
    this.expeditionId,
    this.isValidate,
    this.productoId,
    this.productName,
    this.productCode,
    this.barcode,
    this.tracking,
    this.diasVencimiento,
    this.quantity,
    this.uom,
  });
}
