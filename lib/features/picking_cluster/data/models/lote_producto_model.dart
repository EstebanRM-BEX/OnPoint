import 'dart:convert';
import 'package:wms_app/features/picking_cluster/domain/entities/lote_producto.dart';

LoteProductoResponse loteProductoResponseFromJson(String str) =>
    LoteProductoResponse.fromJson(json.decode(str));

class LoteProductoResponse {
  final String? jsonrpc;
  final dynamic id;
  final LoteProductoResultModel? result;

  LoteProductoResponse({
    this.jsonrpc,
    this.id,
    this.result,
  });

  factory LoteProductoResponse.fromJson(Map<String, dynamic> json) =>
      LoteProductoResponse(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null
            ? null
            : LoteProductoResultModel.fromJson(json["result"]),
      );
}

class LoteProductoResultModel {
  final int? code;
  final List<LotesProduct>? result;

  LoteProductoResultModel({
    this.code,
    this.result,
  });

  factory LoteProductoResultModel.fromJson(Map<String, dynamic> json) =>
      LoteProductoResultModel(
        code: json["code"],
        result: json["result"] == null
            ? []
            : List<LotesProduct>.from(
                json["result"]!.map((x) => LotesProduct.fromMap(x))),
      );
}

class LotesProduct {
  int? id;
  String? name;
  dynamic quantity;
  dynamic expirationDate;
  int? productId;
  String? productName;

  LotesProduct({
    this.id,
    this.name,
    this.quantity,
    this.expirationDate,
    this.productId,
    this.productName,
  });

  factory LotesProduct.fromMap(Map<String, dynamic> json) => LotesProduct(
        id: json["id"],
        name: json["name"],
        quantity: json["quantity"],
        expirationDate: json["expiration_date"],
        productId: json["product_id"],
        productName: json["product_name"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "quantity": quantity,
        "expiration_date": expirationDate,
        "product_id": productId,
        "product_name": productName,
      };

  /// Convierte el modelo de datos al dominio entity [LoteProducto].
  LoteProducto toLoteProductoEntity() {
    DateTime? parsedExpiration;
    if (expirationDate != null && expirationDate is String) {
      parsedExpiration = DateTime.tryParse(expirationDate as String);
    } else if (expirationDate is DateTime) {
      parsedExpiration = expirationDate as DateTime;
    }

    return LoteProducto(
      id: id,
      name: name,
      quantity: quantity is int
          ? quantity as int
          : int.tryParse(quantity?.toString() ?? ''),
      expirationDate: parsedExpiration,
      productId: productId,
      productName: productName,
    );
  }
}
