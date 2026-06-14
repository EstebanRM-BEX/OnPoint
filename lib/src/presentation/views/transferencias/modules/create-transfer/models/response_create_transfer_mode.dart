import 'dart:convert';

class RespondeCreateTransfer {
    final String? jsonrpc;
    final dynamic id;
    final Result? result;

    RespondeCreateTransfer({
        this.jsonrpc,
        this.id,
        this.result,
    });

    factory RespondeCreateTransfer.fromJson(String str) => RespondeCreateTransfer.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory RespondeCreateTransfer.fromMap(Map<String, dynamic> json) => RespondeCreateTransfer(
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
    final int? code;
    final String? msg;
    final int? transferenciaId;
    final String? nombreTransferencia;
    final int? totalItems;
    final List<ItemsProcesado>? itemsProcesados;
    final List<dynamic>? correccionesRealizadas;
    final dynamic totalCorrecciones;
    final int? ubicacionOrigenId;
    final int? ubicacionDestinoId;

    Result({
        this.code,
        this.msg,
        this.transferenciaId,
        this.nombreTransferencia,
        this.totalItems,
        this.itemsProcesados,
        this.correccionesRealizadas,
        this.totalCorrecciones,
        this.ubicacionOrigenId,
        this.ubicacionDestinoId,
    });

    factory Result.fromJson(String str) => Result.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory Result.fromMap(Map<String, dynamic> json) => Result(
        code: json["code"],
        msg: json["msg"],
        transferenciaId: json["transferencia_id"],
        nombreTransferencia: json["nombre_transferencia"],
        totalItems: json["total_items"],
        itemsProcesados: json["items_procesados"] == null ? [] : List<ItemsProcesado>.from(json["items_procesados"]!.map((x) => ItemsProcesado.fromMap(x))),
        correccionesRealizadas: json["correcciones_realizadas"] == null ? [] : List<dynamic>.from(json["correcciones_realizadas"]!.map((x) => x)),
        totalCorrecciones: json["total_correcciones"],
        ubicacionOrigenId: json["ubicacion_origen_id"],
        ubicacionDestinoId: json["ubicacion_destino_id"],
    );

    Map<String, dynamic> toMap() => {
        "code": code,
        "msg": msg,
        "transferencia_id": transferenciaId,
        "nombre_transferencia": nombreTransferencia,
        "total_items": totalItems,
        "items_procesados": itemsProcesados == null ? [] : List<dynamic>.from(itemsProcesados!.map((x) => x.toMap())),
        "correcciones_realizadas": correccionesRealizadas == null ? [] : List<dynamic>.from(correccionesRealizadas!.map((x) => x)),
        "total_correcciones": totalCorrecciones,
        "ubicacion_origen_id": ubicacionOrigenId,
        "ubicacion_destino_id": ubicacionDestinoId,
    };
}

class ItemsProcesado {
    final int? lineaId;
    final int? productoId;
    final String? productoNombre;
    final dynamic cantidad;
    final int? loteId;
    final String? observacion;

    ItemsProcesado({
        this.lineaId,
        this.productoId,
        this.productoNombre,
        this.cantidad,
        this.loteId,
        this.observacion,
    });

    factory ItemsProcesado.fromJson(String str) => ItemsProcesado.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory ItemsProcesado.fromMap(Map<String, dynamic> json) => ItemsProcesado(
        lineaId: json["linea_id"],
        productoId: json["producto_id"],
        productoNombre: json["producto_nombre"],
        cantidad: json["cantidad"],
        loteId: json["lote_id"],
        observacion: json["observacion"],
    );

    Map<String, dynamic> toMap() => {
        "linea_id": lineaId,
        "producto_id": productoId,
        "producto_nombre": productoNombre,
        "cantidad": cantidad,
        "lote_id": loteId,
        "observacion": observacion,
    };
}
