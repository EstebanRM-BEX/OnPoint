import 'dart:convert';

class ResponseSendProductConteo {
    final String? jsonrpc;
    final dynamic id;
    final ResponseSendProductResult? result;

    ResponseSendProductConteo({
        this.jsonrpc,
        this.id,
        this.result,
    });

    factory ResponseSendProductConteo.fromJson(String str) => ResponseSendProductConteo.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory ResponseSendProductConteo.fromMap(Map<String, dynamic> json) => ResponseSendProductConteo(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null ? null : ResponseSendProductResult.fromMap(json["result"]),
    );

    Map<String, dynamic> toMap() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "result": result?.toMap(),
    };
}

class ResponseSendProductResult {
    final int? code;
    final String? msg;
    final List<ResultElement>? result;
    final Data? data;

    ResponseSendProductResult({
        this.code,
        this.msg,
        this.result,
        this.data,
    });

    factory ResponseSendProductResult.fromJson(String str) => ResponseSendProductResult.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory ResponseSendProductResult.fromMap(Map<String, dynamic> json) => ResponseSendProductResult(
        code: json["code"],
        msg: json["msg"],
        result: json["result"] == null ? [] : List<ResultElement>.from(json["result"]!.map((x) => ResultElement.fromMap(x))),
        data: json["data"] == null ? null : Data.fromMap(json["data"]),
    );

    Map<String, dynamic> toMap() => {
        "code": code,
        "msg": msg,
        "result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toMap())),
        "data": data?.toMap(),
    };
}

class Data {
    final int? orderId;
    final int? numeroItemsContados;

    Data({
        this.orderId,
        this.numeroItemsContados,
    });

    factory Data.fromJson(String str) => Data.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory Data.fromMap(Map<String, dynamic> json) => Data(
        orderId: json["order_id"],
        numeroItemsContados: json["numero_items_contados"],
    );

    Map<String, dynamic> toMap() => {
        "order_id": orderId,
        "numero_items_contados": numeroItemsContados,
    };
}

class ResultElement {
    final int? lineId;
    final int? productId;
    final dynamic quantityCounted;
    final String? observation;
    final int? userOperatorId;
    final DateTime? dateTransaction;

    ResultElement({
        this.lineId,
        this.productId,
        this.quantityCounted,
        this.observation,
        this.userOperatorId,
        this.dateTransaction,
    });

    factory ResultElement.fromJson(String str) => ResultElement.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory ResultElement.fromMap(Map<String, dynamic> json) => ResultElement(
        lineId: json["line_id"],
        productId: json["product_id"],
        quantityCounted: json["quantity_counted"],
        observation: json["observation"],
        userOperatorId: json["user_operator_id"],
        dateTransaction: json["date_transaction"] == null ? null : DateTime.parse(json["date_transaction"]),
    );

    Map<String, dynamic> toMap() => {
        "line_id": lineId,
        "product_id": productId,
        "quantity_counted": quantityCounted,
        "observation": observation,
        "user_operator_id": userOperatorId,
        "date_transaction": dateTransaction?.toIso8601String(),
    };
}
