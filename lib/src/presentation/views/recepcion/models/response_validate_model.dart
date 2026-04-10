// To parse this JSON data, do
//
//     final responseValidate = responseValidateFromMap(jsonString);

import 'dart:convert';

ResponseValidate responseValidateFromMap(String str) => ResponseValidate.fromMap(json.decode(str));

String responseValidateToMap(ResponseValidate data) => json.encode(data.toMap());

class ResponseValidate {
    String? jsonrpc;
    dynamic id;
    ResultValidate? result;

    ResponseValidate({
        this.jsonrpc,
        this.id,
        this.result,
    });

    factory ResponseValidate.fromMap(Map<String, dynamic> json) => ResponseValidate(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null ? null : ResultValidate.fromMap(json["result"]),
    );

    Map<String, dynamic> toMap() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "result": result?.toMap(),
    };
}

class ResultValidate {
    int? code;
    String? msg;
    String? tipoError;
    List<DetalleValidate>? detalles;

    ResultValidate({
        this.code,
        this.msg,
        this.tipoError,
        this.detalles,
    });

    factory ResultValidate.fromMap(Map<String, dynamic> json) => ResultValidate(
        code: json["code"],
        msg: json["msg"],
        tipoError: json["tipo_error"],
        detalles: json["detalles"] == null
            ? null
            : List<DetalleValidate>.from(json["detalles"].map((x) => DetalleValidate.fromMap(x))),
    );

    Map<String, dynamic> toMap() => {
        "code": code,
        "msg": msg,
        "tipo_error": tipoError,
        "detalles": detalles?.map((x) => x.toMap()).toList(),
    };
}

class DetalleValidate {
    String? producto;
    String? lote;
    String? fechaVencimiento;
    double? cantidad;

    DetalleValidate({
        this.producto,
        this.lote,
        this.fechaVencimiento,
        this.cantidad,
    });

    factory DetalleValidate.fromMap(Map<String, dynamic> json) => DetalleValidate(
        producto: json["producto"],
        lote: json["lote"],
        fechaVencimiento: json["fecha_vencimiento"],
        cantidad: json["cantidad"]?.toDouble(),
    );

    Map<String, dynamic> toMap() => {
        "producto": producto,
        "lote": lote,
        "fecha_vencimiento": fechaVencimiento,
        "cantidad": cantidad,
    };
}
