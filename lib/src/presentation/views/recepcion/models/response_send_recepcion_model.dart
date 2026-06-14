// To parse this JSON data, do
//
//     final responSendRecepcion = responSendRecepcionFromMap(jsonString);

import 'dart:convert';

ResponSendRecepcion responSendRecepcionFromMap(String str) => ResponSendRecepcion.fromMap(json.decode(str));

String responSendRecepcionToMap(ResponSendRecepcion data) => json.encode(data.toMap());

class ResponSendRecepcion {
    String? jsonrpc;
    dynamic id;
    ResponSendRecepcionResult? result;

    ResponSendRecepcion({
        this.jsonrpc,
        this.id,
        this.result,
    });

    factory ResponSendRecepcion.fromMap(Map<String, dynamic> json) => ResponSendRecepcion(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null ? null : ResponSendRecepcionResult.fromMap(json["result"]),
    );

    Map<String, dynamic> toMap() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "result": result?.toMap(),
    };
}

class ResponSendRecepcionResult {
    int? code;
    String? msg;
    List<ResultElement>? result;

    ResponSendRecepcionResult({
        this.code,
        this.msg,
        this.result,
    });

    factory ResponSendRecepcionResult.fromMap(Map<String, dynamic> json) => ResponSendRecepcionResult(
        code: json["code"],
        msg: json["msg"],
        result: json["result"] == null ? [] : List<ResultElement>.from(json["result"]!.map((x) => ResultElement.fromMap(x))),
    );

    Map<String, dynamic> toMap() => {
        "code": code,
        "msg": msg,
        "result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toMap())),
    };
}

class ResultElement {
    int? id;
    String? producto;
    dynamic cantidad;
    dynamic lote;
    int? ubicacionDestino;
    String? fechaTransaccion;
    String? dateTransaction;
    String? newObservation;
    dynamic time;
    dynamic userOperatorId;
    bool? isDoneItem;

    ResultElement({
        this.id,
        this.producto,
        this.cantidad,
        this.lote,
        this.ubicacionDestino,
        this.fechaTransaccion,
        this.dateTransaction,
        this.newObservation,
        this.time,
        this.userOperatorId,
        this.isDoneItem,
    });

    factory ResultElement.fromMap(Map<String, dynamic> json) => ResultElement(
        id: json["id"],
        producto: json["producto"],
        cantidad: json["cantidad"],
        lote: json["lote"],
        ubicacionDestino: json["ubicacion_destino"],
        fechaTransaccion: json["fecha_transaccion"],
        dateTransaction: json["date_transaction"],
        newObservation: json["new_observation"],
        time: json["time"],
        userOperatorId: json["user_operator_id"],
        isDoneItem: json["is_done_item"],
    );

    Map<String, dynamic> toMap() => {
        "id": id,
        "producto": producto,
        "cantidad": cantidad,
        "lote": lote,
        "ubicacion_destino": ubicacionDestino,
        "fecha_transaccion": fechaTransaccion,
        "date_transaction": dateTransaction,
        "new_observation": newObservation,
        "time": time,
        "user_operator_id": userOperatorId,
        "is_done_item": isDoneItem,
    };
}
