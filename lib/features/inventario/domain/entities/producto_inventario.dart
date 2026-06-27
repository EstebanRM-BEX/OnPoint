// lib/features/inventario/domain/entities/producto_inventario.dart

import 'package:wms_app/features/inventario/domain/entities/barcode_producto.dart';

class ProductoInventario {
  final int? productId;
  final String? name;
  final dynamic code;
  final dynamic category;
  final dynamic barcode;
  final List<BarcodeProducto>? otherBarcodes;
  final List<BarcodeProducto>? productPacking;
  final dynamic lotId;
  final dynamic lotName;
  final String? tracking;
  final dynamic useExpirationDate;
  final dynamic expirationTime;
  final dynamic weight;
  final dynamic weightUomName;
  final dynamic volume;
  final dynamic volumeUomName;
  final dynamic expirationDate;
  final dynamic uom;
  final int? locationId;
  final String? locationName;
  final dynamic quantity;
  final dynamic time;
  final dynamic dateStart;
  final dynamic dateEnd;
  final dynamic quantityDone;
  final String? dateTransaction;
  final String? expirationDateLote;
  final String? propietario;
  final int? idPropietario;
  final dynamic manejoPropietario;
  final dynamic manejaSegundaUnidad;
  final String? uomSegundaUnidad;

  const ProductoInventario({
    this.productId,
    this.name,
    this.code,
    this.category,
    this.barcode,
    this.otherBarcodes,
    this.productPacking,
    this.lotId,
    this.lotName,
    this.tracking,
    this.useExpirationDate,
    this.expirationTime,
    this.weight,
    this.weightUomName,
    this.volume,
    this.volumeUomName,
    this.expirationDate,
    this.uom,
    this.locationId,
    this.locationName,
    this.quantity,
    this.time,
    this.dateStart,
    this.dateEnd,
    this.quantityDone,
    this.dateTransaction,
    this.expirationDateLote,
    this.propietario,
    this.idPropietario,
    this.manejoPropietario,
    this.manejaSegundaUnidad,
    this.uomSegundaUnidad,
  });
}
