import 'dart:convert';

class ResponseUpdateProduct {
    final String? jsonrpc;
    final dynamic id;
    final ResultUpdateProduct? result;

    ResponseUpdateProduct({
        this.jsonrpc,
        this.id,
        this.result,
    });

    factory ResponseUpdateProduct.fromJson(String str) => ResponseUpdateProduct.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory ResponseUpdateProduct.fromMap(Map<String, dynamic> json) => ResponseUpdateProduct(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null ? null : ResultUpdateProduct.fromMap(json["result"]),
    );

    Map<String, dynamic> toMap() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "result": result?.toMap(),
    };
}

class ResultUpdateProduct {
    final int? code;
    final String? msg;
    final int? id;
    final int? productId;
    final String? nombre;
    final String? referencia;
    final dynamic precio;
    final dynamic peso;
    final dynamic volumen;
    final String? codigoBarras;
    final dynamic standardPrice;
    final dynamic cantidadDisponible;
    final dynamic previsto;
    final String? categoria;
    final List<String>? updatedFields;

    ResultUpdateProduct({
        this.code,
        this.msg,
        this.id,
        this.productId,
        this.nombre,
        this.referencia,
        this.precio,
        this.peso,
        this.volumen,
        this.codigoBarras,
        this.standardPrice,
        this.cantidadDisponible,
        this.previsto,
        this.categoria,
        this.updatedFields,
    });

    factory ResultUpdateProduct.fromJson(String str) => ResultUpdateProduct.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory ResultUpdateProduct.fromMap(Map<String, dynamic> json) => ResultUpdateProduct(
        code: json["code"],
        msg: json["msg"],
        id: json["id"],
        productId: json["product_id"],
        nombre: json["nombre"],
        referencia: json["referencia"],
        precio: json["precio"],
        peso: json["peso"],
        volumen: json["volumen"]?.toDouble(),
        codigoBarras: json["codigo_barras"],
        standardPrice: json["standard_price"],
        cantidadDisponible: json["cantidad_disponible"],
        previsto: json["previsto"],
        categoria: json["categoria"],
        updatedFields: json["updated_fields"] == null ? [] : List<String>.from(json["updated_fields"]!.map((x) => x)),
    );

    Map<String, dynamic> toMap() => {
        "code": code,
        "msg": msg,
        "id": id,
        "product_id": productId,
        "nombre": nombre,
        "referencia": referencia,
        "precio": precio,
        "peso": peso,
        "volumen": volumen,
        "codigo_barras": codigoBarras,
        "standard_price": standardPrice,
        "cantidad_disponible": cantidadDisponible,
        "previsto": previsto,
        "categoria": categoria,
        "updated_fields": updatedFields == null ? [] : List<dynamic>.from(updatedFields!.map((x) => x)),
    };
}
