import 'dart:convert';

class ResponseAssignLocationPack {
  final String? jsonrpc;
  final dynamic id;
  final ResultAssignLocation? result;

  ResponseAssignLocationPack({
    this.jsonrpc,
    this.id,
    this.result,
  });

  factory ResponseAssignLocationPack.fromJson(String str) =>
      ResponseAssignLocationPack.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ResponseAssignLocationPack.fromMap(Map<String, dynamic> json) =>
      ResponseAssignLocationPack(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null
            ? null
            : ResultAssignLocation.fromMap(json["result"]),
      );

  Map<String, dynamic> toMap() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "result": result?.toMap(),
      };
}

class ResultAssignLocation {
  final int? code;
  final String? msg;
  final ResultDataAssign? result;

  ResultAssignLocation({
    this.code,
    this.msg,
    this.result,
  });

  factory ResultAssignLocation.fromMap(Map<String, dynamic> json) =>
      ResultAssignLocation(
        code: json["code"],
        msg: json["msg"],
        result: json["result"] == null
            ? null
            : ResultDataAssign.fromMap(json["result"]),
      );

  Map<String, dynamic> toMap() => {
        "code": code,
        "msg": msg,
        "result": result?.toMap(),
      };
}

class ResultDataAssign {
  final String? paquete;
  final String? nuevaUbicacion;
  final int? lineasActualizadas;

  ResultDataAssign({
    this.paquete,
    this.nuevaUbicacion,
    this.lineasActualizadas,
  });

  factory ResultDataAssign.fromMap(Map<String, dynamic> json) =>
      ResultDataAssign(
        paquete: json["paquete"],
        nuevaUbicacion: json["nueva_ubicacion"],
        lineasActualizadas: json["lineas_actualizadas"],
      );

  Map<String, dynamic> toMap() => {
        "paquete": paquete,
        "nueva_ubicacion": nuevaUbicacion,
        "lineas_actualizadas": lineasActualizadas,
      };
}
