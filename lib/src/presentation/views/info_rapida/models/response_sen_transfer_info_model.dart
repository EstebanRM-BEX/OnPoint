// To parse this JSON data, do
//
//     final sendTransferResponse = sendTransferResponseFromMap(jsonString);

import 'dart:convert';

SendTransferResponse sendTransferResponseFromMap(String str) => SendTransferResponse.fromMap(json.decode(str));

String sendTransferResponseToMap(SendTransferResponse data) => json.encode(data.toMap());

class SendTransferResponse {
    String? jsonrpc;
    dynamic id;
    Result? result;

    SendTransferResponse({
        this.jsonrpc,
        this.id,
        this.result,
    });

    factory SendTransferResponse.fromMap(Map<String, dynamic> json) => SendTransferResponse(
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
    int? code;
    String? msg;
    dynamic transferenciaId;
    String? nombreTransferencia;
    dynamic lineaId;
    dynamic cantidadEnviada;
    dynamic idProducto;
    String? nombreProducto;
    String? ubicacionOrigen;
    String? ubicacionDestino;
    String? fechaTransaccion;
    String? observacion;
    dynamic timeLine;
    dynamic userOperatorId;
    String? userOperatorName;
    dynamic idLote;

    Result({
        this.code,
        this.msg,
        this.transferenciaId,
        this.nombreTransferencia,
        this.lineaId,
        this.cantidadEnviada,
        this.idProducto,
        this.nombreProducto,
        this.ubicacionOrigen,
        this.ubicacionDestino,
        this.fechaTransaccion,
        this.observacion,
        this.timeLine,
        this.userOperatorId,
        this.userOperatorName,
        this.idLote,
    });

    factory Result.fromMap(Map<String, dynamic> json) => Result(
        code: json["code"],
        msg: json["msg"],
        transferenciaId: json["transferencia_id"],
        nombreTransferencia: json["nombre_transferencia"],
        lineaId: json["linea_id"],
        cantidadEnviada: json["cantidad_enviada"],
        idProducto: json["id_producto"],
        nombreProducto: json["nombre_producto"],
        ubicacionOrigen: json["ubicacion_origen"],
        ubicacionDestino: json["ubicacion_destino"],
        fechaTransaccion: json["fecha_transaccion"],
        observacion: json["observacion"],
        timeLine: json["time_line"],
        userOperatorId: json["user_operator_id"],
        userOperatorName: json["user_operator_name"],
        idLote: json["id_lote"],
    );

    Map<String, dynamic> toMap() => {
        "code": code,
        "msg": msg,
        "transferencia_id": transferenciaId,
        "nombre_transferencia": nombreTransferencia,
        "linea_id": lineaId,
        "cantidad_enviada": cantidadEnviada,
        "id_producto": idProducto,
        "nombre_producto": nombreProducto,
        "ubicacion_origen": ubicacionOrigen,
        "ubicacion_destino": ubicacionDestino,
        "fecha_transaccion": fechaTransaccion,
        "observacion": observacion,
        "time_line": timeLine,
        "user_operator_id": userOperatorId,
        "user_operator_name": userOperatorName,
        "id_lote": idLote,
    };
}
