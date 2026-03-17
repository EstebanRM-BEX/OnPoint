// To parse this JSON data, do
//
//     final typePack = typePackFromJson(jsonString);

import 'dart:convert';

TypePack typePackFromJson(String str) => TypePack.fromJson(json.decode(str));

String typePackToJson(TypePack data) => json.encode(data.toJson());

class TypePack {
  final String? jsonrpc;
  final dynamic id;
  final TypePackResult? result;

  TypePack({
    this.jsonrpc,
    this.id,
    this.result,
  });

  factory TypePack.fromJson(Map<String, dynamic> json) => TypePack(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null
            ? null
            : TypePackResult.fromJson(json["result"]),
      );

  Map<String, dynamic> toJson() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "result": result?.toJson(),
      };
}

class TypePackResult {
  final int? code;
  final List<ResultElement>? result;

  TypePackResult({
    this.code,
    this.result,
  });

  factory TypePackResult.fromJson(Map<String, dynamic> json) => TypePackResult(
        code: json["code"],
        result: json["result"] == null
            ? []
            : List<ResultElement>.from(
                json["result"]!.map((x) => ResultElement.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "code": code,
        "result": result == null
            ? []
            : List<dynamic>.from(result!.map((x) => x.toJson())),
      };
}

class ResultElement {
  final int? id;
  final String? name;
  final String? barcode;
  final int? maxWeight;
  final int? height;
  final int? width;
  final int? packagingLength;
  final String? tamao;
  final String? transportista;

  ResultElement({
    this.id,
    this.name,
    this.barcode,
    this.maxWeight,
    this.height,
    this.width,
    this.packagingLength,
    this.tamao,
    this.transportista,
  });

  factory ResultElement.fromJson(Map<String, dynamic> json) => ResultElement(
        id: json["id"],
        name: json["name"],
        barcode: json["barcode"],
        maxWeight: json["max_weight"],
        height: json["height"],
        width: json["width"],
        packagingLength: json["packaging_length"],
        tamao: json["tamaño"],
        transportista: json["transportista"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "barcode": barcode,
        "max_weight": maxWeight,
        "height": height,
        "width": width,
        "packaging_length": packagingLength,
        "tamaño": tamao,
        "transportista": transportista,
      };
}
