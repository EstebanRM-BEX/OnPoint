/// Espejo de LoteProducto (recepción multiusuario). Los lotes son un dato de
/// producto, no de sesión de transferencia — mismos endpoints genéricos
/// (GET /api/lotes/{productId}, POST /api/create_lote), duplicado
/// feature-local por la misma convención de desacoplar módulos.
class TransferenciaLoteProducto {
  final int? id;
  final String? name;
  final dynamic quantity;
  final String? expirationDate;
  final int? productId;
  final String? productName;

  const TransferenciaLoteProducto({
    this.id,
    this.name,
    this.quantity,
    this.expirationDate,
    this.productId,
    this.productName,
  });
}
