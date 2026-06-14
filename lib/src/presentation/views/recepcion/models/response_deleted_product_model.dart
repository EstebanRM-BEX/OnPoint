import 'dart:convert';

class DeletedProduct {
    final String? jsonrpc;
    final dynamic id;
    final DeletedProductResult? result;

    DeletedProduct({
        this.jsonrpc,
        this.id,
        this.result,
    });

    factory DeletedProduct.fromRawJson(String str) => DeletedProduct.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory DeletedProduct.fromJson(Map<String, dynamic> json) => DeletedProduct(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null ? null : DeletedProductResult.fromJson(json["result"]),
    );

    Map<String, dynamic> toJson() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "result": result?.toJson(),
    };
}

class DeletedProductResult {
    final int? code;
    final String? mensaje;
    final List<ProductDeleted>? result;

    
    DeletedProductResult({
        this.code,
        this.mensaje,
        this.result,
    });

    factory DeletedProductResult.fromRawJson(String str) => DeletedProductResult.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory DeletedProductResult.fromJson(Map<String, dynamic> json) => DeletedProductResult(
        code: json["code"],
        mensaje: json["msg"],
        result: json["result"] == null ? [] : List<ProductDeleted>.from(json["result"]!.map((x) => ProductDeleted.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "code": code,
        "mensaje": mensaje,
        "result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
    };
}

class ProductDeleted {
    final bool? error;
    final String? mensaje;
    final String? producto;
    final dynamic cantidad;
    final int? idMove;
    final int? idProducto;
    final int? idMoveDeleted;

    ProductDeleted({
        this.error,
        this.mensaje,
        this.producto,
        this.cantidad,
        this.idMove,
        this.idProducto,
        this.idMoveDeleted,
    });

    factory ProductDeleted.fromRawJson(String str) => ProductDeleted.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory ProductDeleted.fromJson(Map<String, dynamic> json) => ProductDeleted(
        error: json["error"],
        mensaje: json["mensaje"],
        producto: json["producto"],
        cantidad: json["cantidad"],
        idMove: json["id_move"],
        idProducto: json["id_producto"],
        idMoveDeleted: json["id_move_deleted"],
    );

    factory ProductDeleted.fromMap(Map<String, dynamic> json) {
    return ProductDeleted(
      error: json['error'] ?? false,
      mensaje: json['mensaje'] ?? '',
      producto: json['producto'] ?? '',
      cantidad: (json['cantidad'] ?? 0).toDouble(),
      idMove: json['id_move'],
      idProducto: json['id_producto'],
      idMoveDeleted: json['id_move_deleted'],
    );
  }

    Map<String, dynamic> toJson() => {
        "error": error,
        "mensaje": mensaje,
        "producto": producto,
        "cantidad": cantidad,
        "id_move": idMove,
        "id_producto": idProducto,
        "id_move_deleted": idMoveDeleted,
    };
}
