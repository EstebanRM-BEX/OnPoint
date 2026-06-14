// lib/features/inventario/domain/entities/barcode_producto.dart

class BarcodeProducto {
  final dynamic barcode;
  final dynamic idProduct;
  final dynamic cantidad;

  const BarcodeProducto({
    this.barcode,
    this.idProduct,
    this.cantidad,
  });
}
