// lib/features/inventario/data/models/producto_inventario_model.dart

// Odoo devuelve false (bool) para campos string vacíos. Este helper convierte
// false → null para que el cast a String? no falle en runtime.

import 'package:wms_app/features/inventario/data/models/barcode_producto_model.dart';
import 'package:wms_app/features/inventario/domain/entities/barcode_producto.dart';
import 'package:wms_app/features/inventario/domain/entities/producto_inventario.dart';
import 'package:wms_app/src/presentation/providers/db/models/response_products_model.dart'
    as legacy;

String? _s(dynamic v) => v is bool ? null : v as String?;
class ProductoInventarioModel extends ProductoInventario {
  const ProductoInventarioModel({
    super.productId,
    super.name,
    super.code,
    super.category,
    super.barcode,
    super.otherBarcodes,
    super.productPacking,
    super.lotId,
    super.lotName,
    super.tracking,
    super.useExpirationDate,
    super.expirationTime,
    super.weight,
    super.weightUomName,
    super.volume,
    super.volumeUomName,
    super.expirationDate,
    super.uom,
    super.locationId,
    super.locationName,
    super.quantity,
    super.time,
    super.dateStart,
    super.dateEnd,
    super.quantityDone,
    super.dateTransaction,
    super.expirationDateLote,
    super.propietario,
    super.idPropietario,
    super.manejoPropietario,
    super.manejaSegundaUnidad,
    super.uomSegundaUnidad,
  });

  // Copia literal de Product.fromMap, creando BarcodeProductoModel en listas anidadas.
  factory ProductoInventarioModel.fromMap(Map<String, dynamic> json) =>
      ProductoInventarioModel(
        productId: json['product_id'],
        name: json['name'],
        code: json['code'],
        category: json['category'],
        lotId: json['lot_id'],
        lotName: json['lot_name'],
        barcode: json['barcode'],
        otherBarcodes: json['other_barcodes'] == null
            ? []
            : List<BarcodeProducto>.from(
                (json['other_barcodes'] as List<dynamic>)
                    .map((x) => BarcodeProductoModel.fromMap(
                        x as Map<String, dynamic>))),
        productPacking: json['product_packing'] == null
            ? []
            : List<BarcodeProducto>.from(
                (json['product_packing'] as List<dynamic>)
                    .map((x) => BarcodeProductoModel.fromMap(
                        x as Map<String, dynamic>))),
        tracking: _s(json['tracking']),
        useExpirationDate: json['use_expiration_date'],
        expirationTime: json['expiration_time'],
        weight: json['weight'] is bool ? null : json['weight']?.toDouble(),
        weightUomName: json['weight_uom_name'],
        volume: json['volume'] is bool ? null : json['volume']?.toDouble(),
        volumeUomName: json['volume_uom_name'],
        expirationDate: json['expiration_date'],
        uom: json['uom'],
        locationId: json['location_id'] is bool ? null : json['location_id'],
        locationName: _s(json['location_name']),
        quantity: json['quantity'],
        time: json['time'],
        dateStart: json['date_start'],
        dateEnd: json['date_end'],
        quantityDone: json['quantity_done'],
        dateTransaction: _s(json['date_transaction']),
        expirationDateLote: _s(json['expiration_date']),
        propietario: _s(json['propietario']),
        idPropietario: json['id_propietario'] is bool ? null : json['id_propietario'],
        manejoPropietario: json['manejo_propietario'],
        manejaSegundaUnidad: json['maneja_segunda_unidad'],
        uomSegundaUnidad: json['uom_segunda_unidad'] is bool ? null : json['uom_segunda_unidad'] as String?,
      );

  factory ProductoInventarioModel.fromLegacy(legacy.Product p) =>
      ProductoInventarioModel(
        productId: p.productId,
        name: p.name,
        code: p.code,
        category: p.category,
        barcode: p.barcode,
        otherBarcodes: p.otherBarcodes
            ?.map(BarcodeProductoModel.fromLegacy)
            .cast<BarcodeProducto>()
            .toList(),
        productPacking: p.productPacking
            ?.map(BarcodeProductoModel.fromLegacy)
            .cast<BarcodeProducto>()
            .toList(),
        lotId: p.lotId,
        lotName: p.lotName,
        tracking: p.tracking,
        useExpirationDate: p.useExpirationDate,
        expirationTime: p.expirationTime,
        weight: p.weight,
        weightUomName: p.weightUomName,
        volume: p.volume,
        volumeUomName: p.volumeUomName,
        expirationDate: p.expirationDate,
        uom: p.uom,
        locationId: p.locationId,
        locationName: p.locationName,
        quantity: p.quantity,
        time: p.time,
        dateStart: p.dateStart,
        dateEnd: p.dateEnd,
        quantityDone: p.quantityDone,
        dateTransaction: p.dateTransaction,
        expirationDateLote: p.expirationDateLote,
        propietario: p.propietario,
        idPropietario: p.idPropietario,
        manejoPropietario: p.manejoPropietario,
        manejaSegundaUnidad: p.manejaSegundaUnidad,
        uomSegundaUnidad: p.uomSegundaUnidad,
      );

  legacy.Product toLegacy() => legacy.Product(
        productId: productId,
        name: name,
        code: code,
        category: category,
        barcode: barcode,
        otherBarcodes: otherBarcodes
            ?.map(_barcodeToLegacy)
            .toList(),
        productPacking: productPacking
            ?.map(_barcodeToLegacy)
            .toList(),
        lotId: lotId,
        lotName: lotName,
        tracking: tracking,
        useExpirationDate: useExpirationDate,
        expirationTime: expirationTime,
        weight: weight,
        weightUomName: weightUomName,
        volume: volume,
        volumeUomName: volumeUomName,
        expirationDate: expirationDate,
        uom: uom,
        locationId: locationId,
        locationName: locationName,
        quantity: quantity,
        time: time,
        dateStart: dateStart,
        dateEnd: dateEnd,
        quantityDone: quantityDone,
        dateTransaction: dateTransaction,
        expirationDateLote: expirationDateLote,
        propietario: propietario,
        idPropietario: idPropietario,
        manejoPropietario: manejoPropietario,
        manejaSegundaUnidad: manejaSegundaUnidad,
        uomSegundaUnidad: uomSegundaUnidad,
      );

  static legacy.BarcodeInventario _barcodeToLegacy(BarcodeProducto b) {
    if (b is BarcodeProductoModel) return b.toLegacy();
    return legacy.BarcodeInventario(
        barcode: b.barcode, idProduct: b.idProduct, cantidad: b.cantidad);
  }
}
