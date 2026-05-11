// To parse this JSON data, do
//
//     final responseUbicaciones = responseUbicacionesFromMap(jsonString);

import 'dart:convert';

ResponseUbicaciones responseUbicacionesFromMap(String str) =>
    ResponseUbicaciones.fromMap(json.decode(str));

String responseUbicacionesToMap(ResponseUbicaciones data) =>
    json.encode(data.toMap());

class ResponseUbicaciones {
  String? jsonrpc;
  dynamic id;
  ResponseUbicacionesResult? result;

  ResponseUbicaciones({
    this.jsonrpc,
    this.id,
    this.result,
  });

  factory ResponseUbicaciones.fromMap(Map<String, dynamic> json) =>
      ResponseUbicaciones(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null
            ? null
            : ResponseUbicacionesResult.fromMap(json["result"]),
      );

  Map<String, dynamic> toMap() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "result": result?.toMap(),
      };
}

class ResponseUbicacionesResult {
  int? code;
  List<ResultUbicaciones>? result;

  ResponseUbicacionesResult({
    this.code,
    this.result,
  });

  factory ResponseUbicacionesResult.fromMap(Map<String, dynamic> json) =>
      ResponseUbicacionesResult(
        code: json["code"],
        result: json["result"] == null
            ? []
            : List<ResultUbicaciones>.from(
                json["result"]!.map((x) => ResultUbicaciones.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
        "code": code,
        "result": result == null
            ? []
            : List<dynamic>.from(result!.map((x) => x.toMap())),
      };
}

class ResultUbicaciones {
  int? id;
  String? name;
  String? barcode;
  int? locationId;
  String? locationName;
  int? idWarehouse;
  String? warehouseName;
  bool? isADockAlter;

  ResultUbicaciones({
    this.id,
    this.name,
    this.barcode,
    this.locationId,
    this.locationName,
    this.idWarehouse,
    this.warehouseName,
    this.isADockAlter,
  });

  factory ResultUbicaciones.fromMap(Map<String, dynamic> json) =>
      ResultUbicaciones(
        id: json["id"],
        name: json["name"],
        barcode: json["barcode"],
        locationId: json["location_id"],
        locationName: json["location_name"],
        idWarehouse: json["id_warehouse"],
        warehouseName: json["warehouse_name"],
        //is_a_dock_alter
        isADockAlter: json["is_a_dock_alter"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "barcode": barcode,
        "location_id": locationId,
        "location_name": locationName,
        "id_warehouse": idWarehouse,
        "warehouse_name": warehouseName,
        "is_a_dock_alter": isADockAlter,
      };
}
