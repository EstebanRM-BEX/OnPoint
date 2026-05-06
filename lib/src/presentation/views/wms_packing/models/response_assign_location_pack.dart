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
            : json["result"] is Map<String, dynamic>
                ? ResultAssignLocation.fromMap(json["result"])
                : json["result"] is List
                    ? ResultAssignLocation.fromMap({
                        "result": json["result"],
                        "code": 200,
                        "msg": "Éxito"
                      })
                    : null,
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
  final List<ResultDataAssign>? result;

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
            : json["result"] is List
                ? List<ResultDataAssign>.from(json["result"].map((x) =>
                    ResultDataAssign.fromMap(x is Map<String, dynamic> ? x : {})))
                : json["result"] is Map<String, dynamic>
                    ? [ResultDataAssign.fromMap(json["result"])]
                    : [],
      );

  Map<String, dynamic> toMap() => {
        "code": code,
        "msg": msg,
        "result": result == null
            ? null
            : List<dynamic>.from(result!.map((x) => x.toMap())),
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
        paquete: json["paquete"]?.toString(),
        nuevaUbicacion: json["nueva_ubicacion"]?.toString(),
        lineasActualizadas: json["lineas_actualizadas"] is int
            ? json["lineas_actualizadas"]
            : int.tryParse(json["lineas_actualizadas"]?.toString() ?? ""),
      );

  Map<String, dynamic> toMap() => {
        "paquete": paquete,
        "nueva_ubicacion": nuevaUbicacion,
        "lineas_actualizadas": lineasActualizadas,
      };
}
