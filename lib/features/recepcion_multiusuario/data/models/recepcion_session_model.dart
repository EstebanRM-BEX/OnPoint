import 'package:wms_app/features/recepcion_multiusuario/data/models/recepcion_multiusuario_json_utils.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';
import 'package:wms_app/src/presentation/providers/db/recepcion_multiusuario/tbl_recepcion_sessions/recepcion_sessions_table.dart';

class RecepcionSessionModel extends RecepcionSession {
  const RecepcionSessionModel({
    super.sessionId,
    super.name,
    super.pickingId,
    super.pickingName,
    super.warehouseId,
    super.progressPercent,
    super.pendingTasks,
  });

  /// Un elemento de `result.data` de GET /api/receipt/sessions.
  factory RecepcionSessionModel.fromJson(Map<String, dynamic> json) {
    return RecepcionSessionModel(
      sessionId: dynamicToInt(json['id']),
      name: dynamicToString(json['name']),
      pickingId: dynamicToInt(json['picking_id']),
      pickingName: dynamicToString(json['picking_name']),
      warehouseId: dynamicToInt(json['warehouse_id']),
      progressPercent: dynamicToDouble(json['progress_percent']),
      pendingTasks: dynamicToInt(json['pending_tasks']),
    );
  }

  factory RecepcionSessionModel.fromMap(Map<String, dynamic> map) {
    return RecepcionSessionModel(
      sessionId: map[RecepcionSessionsTable.columnSessionId] as int?,
      name: map[RecepcionSessionsTable.columnName] as String?,
      pickingId: map[RecepcionSessionsTable.columnPickingId] as int?,
      pickingName: map[RecepcionSessionsTable.columnPickingName] as String?,
      warehouseId: map[RecepcionSessionsTable.columnWarehouseId] as int?,
      progressPercent:
          (map[RecepcionSessionsTable.columnProgressPercent] as num?)
              ?.toDouble(),
      pendingTasks: map[RecepcionSessionsTable.columnPendingTasks] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      RecepcionSessionsTable.columnSessionId: sessionId,
      RecepcionSessionsTable.columnName: name,
      RecepcionSessionsTable.columnPickingId: pickingId,
      RecepcionSessionsTable.columnPickingName: pickingName,
      RecepcionSessionsTable.columnWarehouseId: warehouseId,
      RecepcionSessionsTable.columnProgressPercent: progressPercent,
      RecepcionSessionsTable.columnPendingTasks: pendingTasks,
    };
  }
}
