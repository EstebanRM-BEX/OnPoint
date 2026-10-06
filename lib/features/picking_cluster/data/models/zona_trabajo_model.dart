import '../../domain/entities/zona_trabajo.dart';

class ZonaTrabajoModel {
  final int? id;
  final String? name;
  final int? batchId;
  final int? zoneId;
  final String? estado;
  final int? userId;
  final String? userName;

  ZonaTrabajoModel({
    this.id,
    this.name,
    this.batchId,
    this.zoneId,
    this.estado,
    this.userId,
    this.userName,
  });

  static int? _asInt(dynamic v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse('${v ?? ''}'));

  /// Odoo manda `false` en los campos de texto vacíos.
  static String? _asString(dynamic v) => v is String ? v : null;

  factory ZonaTrabajoModel.fromJson(Map<String, dynamic> json) =>
      ZonaTrabajoModel(
        id: _asInt(json["id"]),
        name: _asString(json["name"]),
        batchId: _asInt(json["batch_id"]),
        zoneId: _asInt(json["zone_id"]),
        estado: _asString(json["estado"]),
        userId: _asInt(json["user_id"]),
        userName: _asString(json["user_name"]),
      );

  /// El `batch_id` de la zona puede venir vacío: se fuerza al del batch padre
  /// para que la fila quede ligada al batch correcto en SQLite.
  ZonaTrabajoModel copyWithBatch(int? batchId) => ZonaTrabajoModel(
        id: id,
        name: name,
        batchId: this.batchId ?? batchId,
        zoneId: zoneId,
        estado: estado,
        userId: userId,
        userName: userName,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "batch_id": batchId,
        "zone_id": zoneId,
        "estado": estado,
        "user_id": userId,
        "user_name": userName,
      };

  ZonaTrabajo toEntity() => ZonaTrabajo(
        id: id,
        name: name,
        batchId: batchId,
        zoneId: zoneId,
        estado: estado,
        userId: userId,
        userName: userName,
      );

  factory ZonaTrabajoModel.fromEntity(ZonaTrabajo e) => ZonaTrabajoModel(
        id: e.id,
        name: e.name,
        batchId: e.batchId,
        zoneId: e.zoneId,
        estado: e.estado,
        userId: e.userId,
        userName: e.userName,
      );
}
