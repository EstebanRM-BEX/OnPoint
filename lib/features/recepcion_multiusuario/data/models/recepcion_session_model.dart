import 'package:wms_app/features/recepcion_multiusuario/data/models/recepcion_multiusuario_json_utils.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';
import 'package:wms_app/src/presentation/providers/db/recepcion_multiusuario/tbl_recepcion_sessions/recepcion_sessions_table.dart';

class RecepcionSessionModel extends RecepcionSession {
  const RecepcionSessionModel({
    super.sessionId,
    super.name,
    super.state,
    super.pickingId,
    super.pickingName,
    super.progressPercent,
    super.pendingTasks,
    super.proveedorId,
    super.proveedor,
    super.pesoTotal,
    super.numeroLineas,
    super.numeroItems,
    super.origin,
    super.priority,
    super.warehouseId,
    super.warehouseName,
    super.pickingType,
    super.backorderId,
    super.backorderName,
    super.showCheckAvailability,
    super.manejaTemperatura,
    super.temperatura,
    super.manejoPropietario,
    super.propietario,
  });

  /// Un elemento de `result.data` de POST /api/receipt/sessions.
  factory RecepcionSessionModel.fromJson(Map<String, dynamic> json) {
    return RecepcionSessionModel(
      sessionId: dynamicToInt(json['id']),
      name: dynamicToString(json['name']),
      state: dynamicToString(json['state']),
      pickingId: dynamicToInt(json['picking_id']),
      pickingName: dynamicToString(json['picking_name']),
      progressPercent: dynamicToDouble(json['progress_percent']),
      pendingTasks: dynamicToInt(json['pending_tasks']),
      proveedorId: dynamicToInt(json['proveedor_id']),
      proveedor: dynamicToString(json['proveedor']),
      pesoTotal: dynamicToDouble(json['peso_total']),
      numeroLineas: dynamicToInt(json['numero_lineas']),
      numeroItems: dynamicToDouble(json['numero_items']),
      origin: dynamicToString(json['origin']),
      priority: dynamicToString(json['priority']),
      warehouseId: dynamicToInt(json['warehouse_id']),
      warehouseName: dynamicToString(json['warehouse_name']),
      pickingType: dynamicToString(json['picking_type']),
      backorderId: dynamicToInt(json['backorder_id']),
      backorderName: dynamicToString(json['backorder_name']),
      showCheckAvailability: dynamicToBool(json['show_check_availability']),
      manejaTemperatura: dynamicToBool(json['maneja_temperatura']),
      temperatura: dynamicToDouble(json['temperatura']),
      manejoPropietario: dynamicToBool(json['manejo_propietario']),
      propietario: dynamicToString(json['propietario']),
    );
  }

  factory RecepcionSessionModel.fromMap(Map<String, dynamic> map) {
    return RecepcionSessionModel(
      sessionId: map[RecepcionSessionsTable.columnSessionId] as int?,
      name: map[RecepcionSessionsTable.columnName] as String?,
      state: map[RecepcionSessionsTable.columnState] as String?,
      pickingId: map[RecepcionSessionsTable.columnPickingId] as int?,
      pickingName: map[RecepcionSessionsTable.columnPickingName] as String?,
      progressPercent:
          (map[RecepcionSessionsTable.columnProgressPercent] as num?)
              ?.toDouble(),
      pendingTasks: map[RecepcionSessionsTable.columnPendingTasks] as int?,
      proveedorId: map[RecepcionSessionsTable.columnProveedorId] as int?,
      proveedor: map[RecepcionSessionsTable.columnProveedor] as String?,
      pesoTotal: (map[RecepcionSessionsTable.columnPesoTotal] as num?)
          ?.toDouble(),
      numeroLineas: map[RecepcionSessionsTable.columnNumeroLineas] as int?,
      numeroItems: (map[RecepcionSessionsTable.columnNumeroItems] as num?)
          ?.toDouble(),
      origin: map[RecepcionSessionsTable.columnOrigin] as String?,
      priority: map[RecepcionSessionsTable.columnPriority] as String?,
      warehouseId: map[RecepcionSessionsTable.columnWarehouseId] as int?,
      warehouseName: map[RecepcionSessionsTable.columnWarehouseName] as String?,
      pickingType: map[RecepcionSessionsTable.columnPickingType] as String?,
      backorderId: map[RecepcionSessionsTable.columnBackorderId] as int?,
      backorderName: map[RecepcionSessionsTable.columnBackorderName] as String?,
      showCheckAvailability:
          (map[RecepcionSessionsTable.columnShowCheckAvailability] as int?) ==
          1,
      manejaTemperatura:
          (map[RecepcionSessionsTable.columnManejaTemperatura] as int?) == 1,
      temperatura: (map[RecepcionSessionsTable.columnTemperatura] as num?)
          ?.toDouble(),
      manejoPropietario:
          (map[RecepcionSessionsTable.columnManejoPropietario] as int?) == 1,
      propietario: map[RecepcionSessionsTable.columnPropietario] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      RecepcionSessionsTable.columnSessionId: sessionId,
      RecepcionSessionsTable.columnName: name,
      RecepcionSessionsTable.columnState: state,
      RecepcionSessionsTable.columnPickingId: pickingId,
      RecepcionSessionsTable.columnPickingName: pickingName,
      RecepcionSessionsTable.columnProgressPercent: progressPercent,
      RecepcionSessionsTable.columnPendingTasks: pendingTasks,
      RecepcionSessionsTable.columnProveedorId: proveedorId,
      RecepcionSessionsTable.columnProveedor: proveedor,
      RecepcionSessionsTable.columnPesoTotal: pesoTotal,
      RecepcionSessionsTable.columnNumeroLineas: numeroLineas,
      RecepcionSessionsTable.columnNumeroItems: numeroItems,
      RecepcionSessionsTable.columnOrigin: origin,
      RecepcionSessionsTable.columnPriority: priority,
      RecepcionSessionsTable.columnWarehouseId: warehouseId,
      RecepcionSessionsTable.columnWarehouseName: warehouseName,
      RecepcionSessionsTable.columnPickingType: pickingType,
      RecepcionSessionsTable.columnBackorderId: backorderId,
      RecepcionSessionsTable.columnBackorderName: backorderName,
      RecepcionSessionsTable.columnShowCheckAvailability:
          showCheckAvailability == null
          ? null
          : (showCheckAvailability! ? 1 : 0),
      RecepcionSessionsTable.columnManejaTemperatura: manejaTemperatura == null
          ? null
          : (manejaTemperatura! ? 1 : 0),
      RecepcionSessionsTable.columnTemperatura: temperatura,
      RecepcionSessionsTable.columnManejoPropietario: manejoPropietario == null
          ? null
          : (manejoPropietario! ? 1 : 0),
      RecepcionSessionsTable.columnPropietario: propietario,
    };
  }
}
