import 'package:wms_app/features/recepcion_multiusuario/data/models/recepcion_multiusuario_json_utils.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/lote_producto.dart';

class LoteProductoModel extends LoteProducto {
  const LoteProductoModel({
    super.id,
    super.name,
    super.quantity,
    super.expirationDate,
    super.productId,
    super.productName,
  });

  /// Un elemento de `result.result` de GET /api/lotes/{productId}, o el
  /// `result.result.result` de POST /api/create_lote.
  factory LoteProductoModel.fromJson(Map<String, dynamic> json) {
    return LoteProductoModel(
      id: dynamicToInt(json['id']),
      name: dynamicToString(json['name']),
      quantity: json['quantity'],
      expirationDate: dynamicToString(json['expiration_date']),
      productId: dynamicToInt(json['product_id']),
      productName: dynamicToString(json['product_name']),
    );
  }
}
