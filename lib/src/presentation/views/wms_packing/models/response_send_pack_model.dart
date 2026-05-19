import 'dart:convert';

class ResponseSendPack {
  final String? jsonrpc;
  final dynamic id;
  final ResponseSendPackResult? result;

  ResponseSendPack({
    this.jsonrpc,
    this.id,
    this.result,
  });

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
  final String? msg;

  ResponseSendPackResult({
    this.code,
    this.result,
    this.msg,
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
                  json["result"]!.map((x) => ResultElementPack.fromMap(x))),
          msg: json["msg"]);

  Map<String, dynamic> toMap() => {
        "code": code,
        "result": result == null
            ? []
            : List<dynamic>.from(result!.map((x) => x.toMap())),
        "msg": msg,
      };
}

class ResultElementPack {
  final int? idPaquete;
  final String? namePaquete;
  final int? idBatch;
  final int? cantidadProductosEnElPaquete;
  final bool? isSticker;
  final bool? isCertificate;
  final dynamic? peso;
  final List<ListItem>? listItem;
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
            : List<ListItem>.from(
                json["list_item"]!.map((x) => ListItem.fromMap(x))),
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

class ListItem {
  final int? idMove;
  final int? idProducto;
  final dynamic? cantidadEnviada;
  final int? idUbicacionOrigen;
  final int? idUbicacionDestino;
  final int? idLote;
  final int? idOperario;
  final DateTime? fechaTransaccion;
  final dynamic? timeLine;
  final String? observacion;

  ListItem({
    this.idMove,
    this.idProducto,
    this.cantidadEnviada,
    this.idUbicacionOrigen,
    this.idUbicacionDestino,
    this.idLote,
    this.idOperario,
    this.fechaTransaccion,
    this.timeLine,
    this.observacion,
  });

  factory ListItem.fromJson(String str) => ListItem.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ListItem.fromMap(Map<String, dynamic> json) => ListItem(
        idMove: json["id_move"],
        idProducto: json["id_producto"],
        cantidadEnviada: json["cantidad_enviada"],
        idUbicacionOrigen: json["id_ubicacion_origen"],
        idUbicacionDestino: json["id_ubicacion_destino"],
        idLote: json["id_lote"],
        idOperario: json["id_operario"],
        fechaTransaccion: json["fecha_transaccion"] == null
            ? null
            : DateTime.parse(json["fecha_transaccion"]),
        timeLine: json["time_line"],
        observacion: json["observacion"],
      );

  Map<String, dynamic> toMap() => {
        "id_move": idMove,
        "id_producto": idProducto,
        "cantidad_enviada": cantidadEnviada,
        "id_ubicacion_origen": idUbicacionOrigen,
        "id_ubicacion_destino": idUbicacionDestino,
        "id_lote": idLote,
        "id_operario": idOperario,
        "fecha_transaccion": fechaTransaccion?.toIso8601String(),
        "time_line": timeLine,
        "observacion": observacion,
      };
}
