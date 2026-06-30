import 'dart:convert';

import 'package:wms_app/src/presentation/providers/db/models/response_products_model.dart';

class ProductDevolucion {
  int? productId;
  String? name;
  dynamic code;
  dynamic category;
  dynamic barcode;
  List<BarcodeInventario>? otherBarcodes;
  List<BarcodeInventario>? productPacking;

  dynamic lotId;
  dynamic lotName;
  String? tracking;
  dynamic useExpirationDate;
  dynamic expirationTime;
  dynamic weight;
  dynamic weightUomName;
  dynamic volume;
  dynamic volumeUomName;
  dynamic expirationDate;
  dynamic uom;

  int? locationId;
  String? locationName;
  dynamic quantity;
  dynamic manejaSegundaUnidad;
  String? uomSegundaUnidad;
  double? quantitySegundaUnidad;

  ProductDevolucion(
      {this.productId,
      this.name,
      this.code,
      this.category,
      this.lotId,
      this.lotName,
      this.barcode,
      this.otherBarcodes,
      this.productPacking,
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
      this.manejaSegundaUnidad,
      this.uomSegundaUnidad,
      this.quantitySegundaUnidad});

  Product toProduct({
    bool clearLotId = false,
    bool clearLotName = false,
    bool clearQuantity = false,
  }) =>
      Product(
        productId: productId,
        name: name,
        code: code,
        category: category,
        barcode: barcode,
        otherBarcodes: otherBarcodes,
        productPacking: productPacking,
        lotId: clearLotId ? null : lotId,
        lotName: clearLotName ? null : lotName,
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
        quantity: clearQuantity ? null : quantity,
        manejaSegundaUnidad: manejaSegundaUnidad,
        uomSegundaUnidad: uomSegundaUnidad,
        quantitySegundaUnidad: quantitySegundaUnidad,
      );

  factory ProductDevolucion.fromMap(Map<String, dynamic> json) =>
      ProductDevolucion(
        productId: json["product_id"],
        name: json["name"],
        code: json["code"],
        category: json["category"],
        lotId: json["lot_id"],
        lotName: json["lot_name"],
        barcode: json["barcode"],
        otherBarcodes: json["other_barcodes"] == null
            ? []
            : List<BarcodeInventario>.from(json["other_barcodes"]!
                .map((x) => BarcodeInventario.fromMap(x))),
        productPacking: json["product_packing"] == null
            ? []
            : List<BarcodeInventario>.from(json["product_packing"]!
                .map((x) => BarcodeInventario.fromMap(x))),
        tracking: json["tracking"],
        useExpirationDate: json["use_expiration_date"],
        expirationTime: json["expiration_time"],
        weight: json["weight"]?.toDouble(),
        weightUomName: json["weight_uom_name"],
        volume: json["volume"]?.toDouble(),
        volumeUomName: json["volume_uom_name"],
        expirationDate: json["expiration_date"],
        uom: json["uom"],
        locationId: json['location_id'],
        locationName: json['location_name'],
        quantity: json['quantity'],
        manejaSegundaUnidad: json['maneja_segunda_unidad'],
        uomSegundaUnidad: json['uom_segunda_unidad'] is bool ? null : json['uom_segunda_unidad'] as String?,
        quantitySegundaUnidad: (json['quantity_segunda_unidad'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        "product_id": productId,
        "name": name,
        "code": code,
        "category": category,
        "lot_id": lotId,
        "lot_name": lotName,
        "barcode": barcode,
        "other_barcodes": otherBarcodes == null
            ? []
            : List<dynamic>.from(otherBarcodes!.map((x) => x.toMap())),
        "product_packing": productPacking == null
            ? []
            : List<dynamic>.from(productPacking!.map((x) => x.toMap())),
        "tracking": tracking,
        "use_expiration_date": useExpirationDate,
        "expiration_time": expirationTime,
        "weight": weight,
        "weight_uom_name": weightUomName,
        "volume": volume,
        "volume_uom_name": volumeUomName,
        "expiration_date": expirationDate,
        "uom": uom,
        "location_id": locationId,
        "location_name": locationName,
        "quantity": quantity,
        "maneja_segunda_unidad": manejaSegundaUnidad,
        "uom_segunda_unidad": uomSegundaUnidad,
        "quantity_segunda_unidad": quantitySegundaUnidad,
      };
}
