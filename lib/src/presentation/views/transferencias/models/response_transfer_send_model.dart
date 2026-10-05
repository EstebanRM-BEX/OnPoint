// To parse this JSON data, do
//
//     final responseSenTransfer = responseSenTransferFromMap(jsonString);

import 'dart:convert';

ResponseSenTransfer responseSenTransferFromMap(String str) => ResponseSenTransfer.fromMap(json.decode(str));

String responseSenTransferToMap(ResponseSenTransfer data) => json.encode(data.toMap());

class ResponseSenTransfer {
    String? jsonrpc;
    dynamic id;
    ResponseSenTransferResult? result;

    /// true si el servidor respondió 2xx (o sea, procesó el envío) pero el
    /// cuerpo no se pudo interpretar. No viaja en toMap/fromMap.
    bool acceptedButUnreadable;

    ResponseSenTransfer({
        this.jsonrpc,
        this.id,
        this.result,
        this.acceptedButUnreadable = false,
    });

    factory ResponseSenTransfer.fromMap(Map<String, dynamic> json) => ResponseSenTransfer(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null ? null : ResponseSenTransferResult.fromMap(json["result"]),
    );

    Map<String, dynamic> toMap() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "result": result?.toMap(),
    };
}

class ResponseSenTransferResult {
    int? code;
    String? msg;
    List<ResultElement>? result;

    ResponseSenTransferResult({
        this.code,
        this.msg,
        this.result,
    });

    factory ResponseSenTransferResult.fromMap(Map<String, dynamic> json) => ResponseSenTransferResult(
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

/// Odoo devuelve `false` (no `null`) en los campos vacíos: se normaliza a null.
int? _intOrNull(dynamic v) => v is int ? v : (v is num ? v.toInt() : null);
String? _stringOrNull(dynamic v) => v is String ? v : null;
bool? _boolOrNull(dynamic v) => v is bool ? v : null;

class ResultElement {
    String? error;
    int? idMove;
    int? idTransferencia;
    int? idProduct;
    dynamic qtyDone;
    bool? isDoneItem;
    dynamic dateTransaction;
    String? newObservation;
    dynamic timeLine;
    dynamic? userOperatorId;

    ResultElement({
        this.error,
        this.idMove,
        this.idTransferencia,
        this.idProduct,
        this.qtyDone,
        this.isDoneItem,
        this.dateTransaction,
        this.newObservation,
        this.timeLine,
        this.userOperatorId,
    });

    factory ResultElement.fromMap(Map<String, dynamic> json) => ResultElement(
        error: _stringOrNull(json["error"]),
        idMove: _intOrNull(json["id_move"]),
        idTransferencia: _intOrNull(json["id_transferencia"]),
        idProduct: _intOrNull(json["id_product"]),
        qtyDone: json["qty_done"],
        isDoneItem: _boolOrNull(json["is_done_item"]),
        dateTransaction: json["date_transaction"],
        newObservation: _stringOrNull(json["new_observation"]),
        timeLine: json["time_line"],
        userOperatorId: json["user_operator_id"],
    );

    Map<String, dynamic> toMap() => {
        "error": error,
        "id_move": idMove,
        "id_transferencia": idTransferencia,
        "id_product": idProduct,
        "qty_done": qtyDone,
        "is_done_item": isDoneItem,
        "date_transaction": dateTransaction,
        "new_observation": newObservation,
        "time_line": timeLine,
        "user_operator_id": userOperatorId,
    };
}
