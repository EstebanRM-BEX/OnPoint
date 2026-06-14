// lib/features/inventario/domain/entities/lote_producto_inventario.dart

class LoteProductoInventario {
  final int? id;
  final String? name;
  final dynamic quantity;
  final dynamic expirationDate;
  final int? productId;
  final String? productName;

  const LoteProductoInventario({
    this.id,
    this.name,
    this.quantity,
    this.expirationDate,
    this.productId,
    this.productName,
  });
}
