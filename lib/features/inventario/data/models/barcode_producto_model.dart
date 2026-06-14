// lib/features/inventario/data/models/barcode_producto_model.dart

import 'package:wms_app/features/inventario/domain/entities/barcode_producto.dart';
import 'package:wms_app/src/presentation/providers/db/models/response_products_model.dart'
    as legacy;

class BarcodeProductoModel extends BarcodeProducto {
  const BarcodeProductoModel({
    super.barcode,
    super.idProduct,
    super.cantidad,
  });

  factory BarcodeProductoModel.fromMap(Map<String, dynamic> json) =>
      BarcodeProductoModel(
        barcode: json['barcode'],
        idProduct: json['id_product'],
        cantidad: json['cantidad'],
      );

  factory BarcodeProductoModel.fromLegacy(legacy.BarcodeInventario b) =>
      BarcodeProductoModel(
        barcode: b.barcode,
        idProduct: b.idProduct,
        cantidad: b.cantidad,
      );

  legacy.BarcodeInventario toLegacy() => legacy.BarcodeInventario(
        barcode: barcode,
        idProduct: idProduct,
        cantidad: cantidad,
      );
}
