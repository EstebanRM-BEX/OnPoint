import 'dart:convert';

class ResponseDeleteLine {
    final String? jsonrpc;
    final dynamic id;
    final ResponseDeleteLineResult? result;

    ResponseDeleteLine({
        this.jsonrpc,
        this.id,
        this.result,
    });

    factory ResponseDeleteLine.fromJson(String str) => ResponseDeleteLine.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory ResponseDeleteLine.fromMap(Map<String, dynamic> json) => ResponseDeleteLine(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null ? null : ResponseDeleteLineResult.fromMap(json["result"]),
    );

    Map<String, dynamic> toMap() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "result": result?.toMap(),
    };
}

class ResponseDeleteLineResult {
    final int? code;
    final String? msg;
    final ResultResult? result;

    ResponseDeleteLineResult({
        this.code,
        this.msg,
        this.result,
    });

    factory ResponseDeleteLineResult.fromJson(String str) => ResponseDeleteLineResult.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory ResponseDeleteLineResult.fromMap(Map<String, dynamic> json) => ResponseDeleteLineResult(
        code: json["code"],
        msg: json["msg"],
        result: json["result"] == null ? null : ResultResult.fromMap(json["result"]),
    );

    Map<String, dynamic> toMap() => {
        "code": code,
        "msg": msg,
        "result": result?.toMap(),
    };
}

class ResultResult {
    final int? id;
    final int? idMove;
    final int? idTransferencia;
    final int? productId;
    final String? productName;
    final String? productCode;
    final dynamic productBarcode;
    final String? ordenName;
    final int? locationDestId;
    final String? locationDestName;
    final String? locationDestBarcode;
    final int? locationId;
    final String? locationName;
    final String? locationBarcode;
    final dynamic quantityOrdered;
    final dynamic quantityToTransfer;
    final dynamic cantidadFaltante;
    final dynamic cantidadDemandada;

    ResultResult({
        this.id,
        this.idMove,
        this.idTransferencia,
        this.productId,
        this.productName,
        this.productCode,
        this.productBarcode,
        this.ordenName,
        this.locationDestId,
        this.locationDestName,
        this.locationDestBarcode,
        this.locationId,
        this.locationName,
        this.locationBarcode,
        this.quantityOrdered,
        this.quantityToTransfer,
        this.cantidadFaltante,
        this.cantidadDemandada,
    });

    factory ResultResult.fromJson(String str) => ResultResult.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory ResultResult.fromMap(Map<String, dynamic> json) => ResultResult(
        id: json["id"],
        idMove: json["id_move"],
        idTransferencia: json["id_transferencia"],
        productId: json["product_id"],
        productName: json["product_name"],
        productCode: json["product_code"],
        productBarcode: json["product_barcode"],
        ordenName: json["orden_name"],
        locationDestId: json["location_dest_id"],
        locationDestName: json["location_dest_name"],
        locationDestBarcode: json["location_dest_barcode"],
        locationId: json["location_id"],
        locationName: json["location_name"],
        locationBarcode: json["location_barcode"],
        quantityOrdered: json["quantity_ordered"],
        quantityToTransfer: json["quantity_to_transfer"],
        cantidadFaltante: json["cantidad_faltante"],
        cantidadDemandada: json["cantidad_demandada"],
    );

    Map<String, dynamic> toMap() => {
        "id": id,
        "id_move": idMove,
        "id_transferencia": idTransferencia,
        "product_id": productId,
        "product_name": productName,
        "product_code": productCode,
        "product_barcode": productBarcode,
        "orden_name": ordenName,
        "location_dest_id": locationDestId,
        "location_dest_name": locationDestName,
        "location_dest_barcode": locationDestBarcode,
        "location_id": locationId,
        "location_name": locationName,
        "location_barcode": locationBarcode,
        "quantity_ordered": quantityOrdered,
        "quantity_to_transfer": quantityToTransfer,
        "cantidad_faltante": cantidadFaltante,
        "cantidad_demandada": cantidadDemandada,
    };
}
