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

    ResponseSenTransfer({
        this.jsonrpc,
        this.id,
        this.result,
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
    int? userOperatorId;

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
        error: json["error"],
        idMove: json["id_move"],
        idTransferencia: json["id_transferencia"],
        idProduct: json["id_product"],
        qtyDone: json["qty_done"],
        isDoneItem: json["is_done_item"],
        dateTransaction: json["date_transaction"],
        newObservation: json["new_observation"],
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
