import 'dart:convert';

class ResponseDeleteProduct {
    final String? jsonrpc;
    final dynamic id;
    final ResponseDeleteProductResult? result;

    ResponseDeleteProduct({
        this.jsonrpc,
        this.id,
        this.result,
    });

    factory ResponseDeleteProduct.fromJson(String str) => ResponseDeleteProduct.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory ResponseDeleteProduct.fromMap(Map<String, dynamic> json) => ResponseDeleteProduct(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null ? null : ResponseDeleteProductResult.fromMap(json["result"]),
    );

    Map<String, dynamic> toMap() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "result": result?.toMap(),
    };
}

class ResponseDeleteProductResult {
    final int? code;
    final String? msg;
    final List<ResultElement>? result;

    ResponseDeleteProductResult({
        this.code,
        this.msg,
        this.result,
    });

    factory ResponseDeleteProductResult.fromJson(String str) => ResponseDeleteProductResult.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory ResponseDeleteProductResult.fromMap(Map<String, dynamic> json) => ResponseDeleteProductResult(
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
    final int? lineId;
    final int? productId;
    final dynamic quantityCounted;
    final String? newObservation;
    final dynamic userOperatorId;
    final String? dateTransaction;

    ResultElement({
        this.lineId,
        this.productId,
        this.quantityCounted,
        this.newObservation,
        this.userOperatorId,
        this.dateTransaction,
    });

    factory ResultElement.fromJson(String str) => ResultElement.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory ResultElement.fromMap(Map<String, dynamic> json) => ResultElement(
        lineId: json["line_id"],
        productId: json["product_id"],
        quantityCounted: json["quantity_counted"],
        newObservation: json["new_observation"],
        userOperatorId: json["user_operator_id"],
        dateTransaction: json["date_transaction"],
    );

    Map<String, dynamic> toMap() => {
        "line_id": lineId,
        "product_id": productId,
        "quantity_counted": quantityCounted,
        "new_observation": newObservation,
        "user_operator_id": userOperatorId,
        "date_transaction": dateTransaction,
    };
}
