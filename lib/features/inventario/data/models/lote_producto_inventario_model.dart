// lib/features/inventario/data/models/lote_producto_inventario_model.dart

import 'package:wms_app/features/inventario/domain/entities/lote_producto_inventario.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_lotes_product_model.dart'
    as legacy;

class LoteProductoInventarioModel extends LoteProductoInventario {
  const LoteProductoInventarioModel({
    super.id,
    super.name,
    super.quantity,
    super.expirationDate,
    super.productId,
    super.productName,
  });

  factory LoteProductoInventarioModel.fromMap(Map<String, dynamic> json) =>
      LoteProductoInventarioModel(
        id: json['id'],
        name: json['name'],
        quantity: json['quantity'],
        expirationDate: json['expiration_date'],
        productId: json['product_id'],
        productName: json['product_name'],
      );

  factory LoteProductoInventarioModel.fromLegacy(legacy.LotesProduct l) =>
      LoteProductoInventarioModel(
        id: l.id,
        name: l.name,
        quantity: l.quantity,
        expirationDate: l.expirationDate,
        productId: l.productId,
        productName: l.productName,
      );

  legacy.LotesProduct toLegacy() => legacy.LotesProduct(
        id: id,
        name: name,
        quantity: quantity,
        expirationDate: expirationDate,
        productId: productId,
        productName: productName,
      );
}
