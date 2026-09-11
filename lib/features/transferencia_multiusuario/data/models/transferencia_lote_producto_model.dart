import 'package:wms_app/features/transferencia_multiusuario/data/models/transferencia_multiusuario_json_utils.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_lote_producto.dart';

class TransferenciaLoteProductoModel extends TransferenciaLoteProducto {
  const TransferenciaLoteProductoModel({
    super.id,
    super.name,
    super.quantity,
    super.expirationDate,
    super.productId,
    super.productName,
  });

  /// Un elemento de `result.result` de GET /api/lotes/{productId}, o el
  /// `result.result.result` de POST /api/create_lote.
  factory TransferenciaLoteProductoModel.fromJson(Map<String, dynamic> json) {
    return TransferenciaLoteProductoModel(
      id: dynamicToInt(json['id']),
      name: dynamicToString(json['name']),
      quantity: json['quantity'],
      expirationDate: dynamicToString(json['expiration_date']),
      productId: dynamicToInt(json['product_id']),
      productName: dynamicToString(json['product_name']),
    );
  }
}
