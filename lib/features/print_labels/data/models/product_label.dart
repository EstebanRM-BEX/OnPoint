/// Modelo liviano para el listado de impresión de etiquetas.
///
/// La pantalla solo necesita id/name/code/barcode, así que evitamos traer y
/// parsear las ~35 columnas `dynamic` del modelo `Product` de inventario.
/// (Optimización #1 de performance del feature print_labels.)
class ProductLabel {
  final int productId;
  final String name;
  final String code;
  final String barcode;

  const ProductLabel({
    required this.productId,
    required this.name,
    required this.code,
    required this.barcode,
  });

  factory ProductLabel.fromMap(Map<String, Object?> map) => ProductLabel(
        productId: (map['product_id'] as int?) ?? 0,
        name: (map['name'] as String?) ?? '',
        code: (map['code'] as String?) ?? '',
        barcode: (map['barcode'] as String?) ?? '',
      );
}
