import 'dart:convert';

GetProductsInventario getProductsInventarioFromMap(String str) =>
    GetProductsInventario.fromMap(json.decode(str));

String getProductsInventarioToMap(GetProductsInventario data) =>
    json.encode(data.toMap());

class GetProductsInventario {
  String? jsonrpc;
  dynamic id;
  Result? result;

  GetProductsInventario({
    this.jsonrpc,
    this.id,
    this.result,
  });

  factory GetProductsInventario.fromMap(Map<String, dynamic> json) =>
      GetProductsInventario(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null ? null : Result.fromMap(json["result"]),
      );

  Map<String, dynamic> toMap() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "result": result?.toMap(),
      };
}

class Result {
  String? status;
  List<Product>? data;

  Result({
    this.status,
    this.data,
  });

  factory Result.fromMap(Map<String, dynamic> json) => Result(
        status: json["status"],
        data: json["data"] == null
            ? []
            : List<Product>.from(json["data"]!.map((x) => Product.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
        "status": status,
        "data":
            data == null ? [] : List<dynamic>.from(data!.map((x) => x.toMap())),
      };
}

class Product {
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

  ///valores para crear productos en una transferencia
  dynamic time;
  dynamic dateStart;
  dynamic dateEnd;
  dynamic quantityDone;
  String? dateTransaction;
  String? expirationDateLote;

  int? idPropietario;
  String? propietario;
  dynamic? manejoPropietario;



  Product({
    this.productId,
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
    this.time,
    this.dateStart,
    this.dateEnd,
    this.quantityDone,
    this.dateTransaction,
    this.expirationDateLote,
    this.idPropietario,
    this.propietario,
    this.manejoPropietario,
  });

  Product copyWith({
    int? productId,
    String? name,
    dynamic code,
    dynamic category,
    dynamic barcode,
    List<BarcodeInventario>? otherBarcodes,
    List<BarcodeInventario>? productPacking,
    dynamic lotId,
    dynamic lotName,
    String? tracking,
    dynamic useExpirationDate,
    dynamic expirationTime,
    dynamic weight,
    dynamic weightUomName,
    dynamic volume,
    dynamic volumeUomName,
    dynamic expirationDate,
    dynamic uom,
    int? locationId,
    String? locationName,
    dynamic quantity,
    dynamic time,
    dynamic dateStart,
    dynamic dateEnd,
    dynamic quantityDone,
    String? dateTransaction,
    String? expirationDateLote,
    int? idPropietario,
    String? propietario,
    dynamic manejoPropietario,
    // Sentinel para campos que se quieren pasar explícitamente a null
    bool clearLotId = false,
    bool clearLotName = false,
    bool clearQuantity = false,
  }) =>
      Product(
        productId: productId ?? this.productId,
        name: name ?? this.name,
        code: code ?? this.code,
        category: category ?? this.category,
        barcode: barcode ?? this.barcode,
        otherBarcodes: otherBarcodes ?? this.otherBarcodes,
        productPacking: productPacking ?? this.productPacking,
        lotId: clearLotId ? null : (lotId ?? this.lotId),
        lotName: clearLotName ? null : (lotName ?? this.lotName),
        tracking: tracking ?? this.tracking,
        useExpirationDate: useExpirationDate ?? this.useExpirationDate,
        expirationTime: expirationTime ?? this.expirationTime,
        weight: weight ?? this.weight,
        weightUomName: weightUomName ?? this.weightUomName,
        volume: volume ?? this.volume,
        volumeUomName: volumeUomName ?? this.volumeUomName,
        expirationDate: expirationDate ?? this.expirationDate,
        uom: uom ?? this.uom,
        locationId: locationId ?? this.locationId,
        locationName: locationName ?? this.locationName,
        quantity: clearQuantity ? null : (quantity ?? this.quantity),
        time: time ?? this.time,
        dateStart: dateStart ?? this.dateStart,
        dateEnd: dateEnd ?? this.dateEnd,
        quantityDone: quantityDone ?? this.quantityDone,
        dateTransaction: dateTransaction ?? this.dateTransaction,
        expirationDateLote: expirationDateLote ?? this.expirationDateLote,
        idPropietario: idPropietario ?? this.idPropietario,
        propietario: propietario ?? this.propietario,
        manejoPropietario: manejoPropietario ?? this.manejoPropietario,
      );

  factory Product.fromMap(Map<String, dynamic> json) => Product(
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
        time: json['time'],
        dateStart: json['date_start'],
        dateEnd: json['date_end'],
        quantityDone: json['quantity_done'],
        dateTransaction: json['date_transaction'],
        expirationDateLote: json['expiration_date'],
        idPropietario: json["id_propietario"],
        manejoPropietario: json["manejo_propietario"],
        propietario: json["propietario"]
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
        "time": time,
        "date_start": dateStart,
        "date_end": dateEnd,
        "quantity_done": quantityDone,
        "date_transaction": dateTransaction,
        "expiration_date_lote": expirationDateLote,
        "propietario" : propietario,
        "id_propietario" : idPropietario,
        "manejo_propietario" : manejoPropietario,
      };
}

class BarcodeInventario {
  dynamic barcode;
  dynamic idProduct;
  dynamic cantidad;

  BarcodeInventario({
    this.barcode,
    this.idProduct,
    this.cantidad,
  });

  factory BarcodeInventario.fromMap(Map<String, dynamic> json) =>
      BarcodeInventario(
          barcode: json["barcode"],
          idProduct: json["id_product"],
          cantidad: json["cantidad"]);

  Map<String, dynamic> toMap() => {
        "barcode": barcode,
        "cantidad": cantidad,
        "id_product": idProduct,
      };
}
