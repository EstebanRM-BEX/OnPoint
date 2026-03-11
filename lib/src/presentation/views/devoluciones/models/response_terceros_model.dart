import 'dart:convert';

class ResponseTerceros {
  final String? jsonrpc;
  final dynamic id;
  final ResponseTercerosResult? result;

  ResponseTerceros({
    this.jsonrpc,
    this.id,
    this.result,
  });

  factory ResponseTerceros.fromJson(String str) =>
      ResponseTerceros.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ResponseTerceros.fromMap(Map<String, dynamic> json) =>
      ResponseTerceros(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null
            ? null
            : ResponseTercerosResult.fromMap(json["result"]),
      );

  Map<String, dynamic> toMap() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "result": result?.toMap(),
      };
}

class ResponseTercerosResult {
  final int? code;
  final List<Terceros>? result;

  ResponseTercerosResult({
    this.code,
    this.result,
  });

  factory ResponseTercerosResult.fromJson(String str) =>
      ResponseTercerosResult.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ResponseTercerosResult.fromMap(Map<String, dynamic> json) =>
      ResponseTercerosResult(
        code: json["code"],
        result: json["result"] == null
            ? []
            : List<Terceros>.from(
                json["result"]!.map((x) => Terceros.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
        "code": code,
        "result": result == null
            ? []
            : List<dynamic>.from(result!.map((x) => x.toMap())),
      };
}

class Terceros {
  final int? id;
  final String? document;
  final String? sucursal;
  final dynamic? name;
  final String? almacen;

  Terceros({
    this.id,
    this.document,
    this.sucursal,
    this.name,
    this.almacen,
  });

  factory Terceros.fromJson(String str) => Terceros.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Terceros.fromMap(Map<String, dynamic> json) => Terceros(
        id: json["id"],
        document: json["document"],
        sucursal: json["sucursal"],
        name: json["name"],
        almacen: json["almacen"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "document": document,
        "sucursal": sucursal,
        "name": name,
        "almacen": almacen,
      };
}
