import 'dart:convert';

class ResponseSendPack {
  final String? jsonrpc;
  final dynamic id;
  final ResponseSendPackResult? result;

  ResponseSendPack({this.jsonrpc, this.id, this.result});

  factory ResponseSendPack.fromJson(String str) =>
      ResponseSendPack.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ResponseSendPack.fromMap(Map<String, dynamic> json) =>
      ResponseSendPack(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null
            ? null
            : ResponseSendPackResult.fromMap(json["result"]),
      );

  Map<String, dynamic> toMap() => {
    "jsonrpc": jsonrpc,
    "id": id,
    "result": result?.toMap(),
  };
}

class ResponseSendPackResult {
  final int? code;
  final List<ResultElementPack>? result;

  /// El backend manda el texto en `mensaje` ("Paquete creado exitosamente");
  /// `msg` se mantiene como alternativa por si alguna respuesta vieja la usa.
  final String? msg;

  /// Ajustes que el backend aplicó por su cuenta al crear el paquete.
  final List<dynamic> correccionesRealizadas;
  final int? totalCorrecciones;

  ResponseSendPackResult({
    this.code,
    this.result,
    this.msg,
    this.correccionesRealizadas = const [],
    this.totalCorrecciones,
  });

  factory ResponseSendPackResult.fromJson(String str) =>
      ResponseSendPackResult.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ResponseSendPackResult.fromMap(Map<String, dynamic> json) =>
      ResponseSendPackResult(
        code: json["code"],
        result: json["result"] == null
            ? []
            : List<ResultElementPack>.from(
                json["result"]!.map((x) => ResultElementPack.fromMap(x)),
              ),
        msg: (json["mensaje"] ?? json["msg"])?.toString(),
        correccionesRealizadas: json["correcciones_realizadas"] is List
            ? List<dynamic>.from(json["correcciones_realizadas"])
            : const [],
        totalCorrecciones: json["total_correcciones"],
      );

  Map<String, dynamic> toMap() => {
    "code": code,
    "result": result == null
        ? []
        : List<dynamic>.from(result!.map((x) => x.toMap())),
    "mensaje": msg,
    "correcciones_realizadas": correccionesRealizadas,
    "total_correcciones": totalCorrecciones,
  };
}

class ResultElementPack {
  final int? idPaquete;
  final String? namePaquete;
  final int? idBatch;
  final int? cantidadProductosEnElPaquete;
  final bool? isSticker;
  final bool? isCertificate;
  final dynamic peso;
  final List<PackedMoveItem>? listItem;
  final dynamic consecutivo;
  final String? packingBarcode;

  ResultElementPack({
    this.idPaquete,
    this.namePaquete,
    this.idBatch,
    this.cantidadProductosEnElPaquete,
    this.isSticker,
    this.isCertificate,
    this.peso,
    this.listItem,
    this.consecutivo,
    this.packingBarcode,
  });

  factory ResultElementPack.fromJson(String str) =>
      ResultElementPack.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ResultElementPack.fromMap(Map<String, dynamic> json) =>
      ResultElementPack(
        idPaquete: json["id_paquete"],
        namePaquete: json["name_paquete"],
        idBatch: json["id_batch"],
        cantidadProductosEnElPaquete: json["cantidad_productos_en_el_paquete"],
        isSticker: json["is_sticker"],
        isCertificate: json["is_certificate"],
        peso: json["peso"],
        listItem: json["list_item"] == null
            ? []
            : List<PackedMoveItem>.from(
                json["list_item"]!.map((x) => PackedMoveItem.fromMap(x)),
              ),
        consecutivo: json["consecutivo"],
        packingBarcode: json["packing_barcode"],
      );

  Map<String, dynamic> toMap() => {
    "id_paquete": idPaquete,
    "name_paquete": namePaquete,
    "id_batch": idBatch,
    "cantidad_productos_en_el_paquete": cantidadProductosEnElPaquete,
    "is_sticker": isSticker,
    "is_certificate": isCertificate,
    "peso": peso,
    "list_item": listItem == null
        ? []
        : List<dynamic>.from(listItem!.map((x) => x.toMap())),
    "consecutivo": consecutivo,
    "packing_barcode": packingBarcode,
  };
}

/// Cada entrada de `list_item` es el stock.move que quedó dentro del paquete,
/// con la misma forma que manda `transferencias/unpacking`.
class PackedMoveItem {
  final int? id;
  final int? idMove;
  final int? pedidoId;
  final int? batchId;
  final int? idProduct;
  final String? productName;
  final String? productCode;
  final String? barcode;

  /// Cantidad que quedó en el paquete para ese move.
  final double? quantity;
  final double? quantityOrdered;
  final double? quantityToTransfer;
  final double? cantidadFaltante;
  final String? uom;
  final String? unidades;
  final String? tracking;
  final int? loteId;
  final String? expireDate;
  final bool? isDoneItem;
  final String? dateTransaction;
  final String? observation;
  final dynamic time;
  final int? userOperatorId;
  final int? idPaquete;
  final String? namePaquete;
  final dynamic consecutivo;

  /// Mapa crudo, para los campos que no se modelan acá.
  final Map<String, dynamic> raw;

  PackedMoveItem({
    this.id,
    this.idMove,
    this.pedidoId,
    this.batchId,
    this.idProduct,
    this.productName,
    this.productCode,
    this.barcode,
    this.quantity,
    this.quantityOrdered,
    this.quantityToTransfer,
    this.cantidadFaltante,
    this.uom,
    this.unidades,
    this.tracking,
    this.loteId,
    this.expireDate,
    this.isDoneItem,
    this.dateTransaction,
    this.observation,
    this.time,
    this.userOperatorId,
    this.idPaquete,
    this.namePaquete,
    this.consecutivo,
    this.raw = const {},
  });

  static double? _toDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('${value ?? ''}');

  static int? _refId(dynamic value) =>
      (value is List && value.isNotEmpty && value.first is int)
      ? value.first as int
      : null;

  static String? _refName(dynamic value) =>
      (value is List && value.length > 1) ? '${value[1]}' : null;

  int? get idLocation => _refId(raw['location_id']);
  String? get locationName => _refName(raw['location_id']);
  int? get idLocationDest => _refId(raw['location_dest_id']);
  String? get locationDestName => _refName(raw['location_dest_id']);
  String? get barcodeLocation => raw['barcode_location']?.toString();
  String? get barcodeLocationDest => raw['barcode_location_dest']?.toString();
  double? get weight => _toDouble(raw['weight']);
  bool get manejaTemperatura => raw['maneja_temperatura'] == true;
  double? get temperatura => _toDouble(raw['temperatura']);

  factory PackedMoveItem.fromJson(String str) =>
      PackedMoveItem.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PackedMoveItem.fromMap(Map<String, dynamic> json) => PackedMoveItem(
    id: json["id"],
    idMove: json["id_move"],
    pedidoId: json["pedido_id"],
    batchId: json["batch_id"],
    idProduct: json["id_product"],
    productName: json["product_name"],
    productCode: json["product_code"],
    barcode: json["barcode"]?.toString(),
    quantity: _toDouble(json["quantity"]),
    quantityOrdered: _toDouble(json["quantity_ordered"]),
    quantityToTransfer: _toDouble(json["quantity_to_transfer"]),
    cantidadFaltante: _toDouble(json["cantidad_faltante"]),
    uom: json["uom"]?.toString(),
    unidades: json["unidades"]?.toString(),
    tracking: json["tracking"]?.toString(),
    loteId: json["lote_id"] is int ? json["lote_id"] : null,
    expireDate: json["expire_date"]?.toString(),
    isDoneItem: json["is_done_item"],
    dateTransaction: json["date_transaction"]?.toString(),
    observation: json["observation"]?.toString(),
    time: json["time"],
    userOperatorId: json["user_operator_id"],
    idPaquete: json["id_paquete"],
    namePaquete: json["name_paquete"],
    consecutivo: json["consecutivo"],
    raw: json,
  );

  Map<String, dynamic> toMap() => Map<String, dynamic>.from(raw);
}
