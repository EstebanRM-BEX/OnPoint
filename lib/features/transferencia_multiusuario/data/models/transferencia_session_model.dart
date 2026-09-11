import 'package:wms_app/features/transferencia_multiusuario/data/models/transferencia_multiusuario_json_utils.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_session.dart';
import 'package:wms_app/src/presentation/providers/db/transferencia_multiusuario/tbl_transferencia_sessions/transferencia_sessions_table.dart';

class TransferenciaSessionModel extends TransferenciaSession {
  const TransferenciaSessionModel({
    super.sessionId,
    super.name,
    super.state,
    super.pickingId,
    super.pickingName,
    super.pickingState,
    super.progressPercent,
    super.pendingTasks,
    super.startTime,
    super.endTime,
    super.maxClaimsPerUser,
    super.claimTtlMinutes,
    super.claimChunkMode,
    super.claimChunkQty,
    super.qtyDemandedTotal,
    super.qtyAlmacenadaTotal,
    super.qtyRecibidaTotal,
    super.qtyAsignadaTotal,
    super.qtyPendienteTotal,
    super.taskCount,
    super.claimCount,
    super.proveedorId,
    super.proveedor,
    super.pesoTotal,
    super.numeroLineas,
    super.numeroItems,
    super.origin,
    super.originPickingId,
    super.originPickingName,
    super.priority,
    super.warehouseId,
    super.warehouseName,
    super.pickingType,
    super.pickingTypeCode,
    super.backorderId,
    super.backorderName,
    super.showCheckAvailability,
    super.manejaTemperatura,
    super.temperatura,
    super.manejoPropietario,
    super.propietario,
    super.locationOrigenId,
    super.locationOrigenName,
    super.locationOrigenBarcode,
    super.locationEntradaId,
    super.locationEntradaName,
    super.locationDestId,
    super.locationDestName,
    super.locationStockId,
    super.locationStockName,
    super.esIntAlmacenamiento,
    super.recepcionUnPaso,
  });

  /// Un elemento de `result.data` de POST /api/transfer/sessions.
  factory TransferenciaSessionModel.fromJson(Map<String, dynamic> json) {
    return TransferenciaSessionModel(
      sessionId: dynamicToInt(json['id']),
      name: dynamicToString(json['name']),
      state: dynamicToString(json['state']),
      pickingId: dynamicToInt(json['picking_id']),
      pickingName: dynamicToString(json['picking_name']),
      pickingState: dynamicToString(json['picking_state']),
      progressPercent: dynamicToDouble(json['progress_percent']),
      pendingTasks: dynamicToInt(json['pending_tasks']),
      startTime: dynamicToString(json['start_time']),
      endTime: dynamicToString(json['end_time']),
      maxClaimsPerUser: dynamicToInt(json['max_claims_per_user']),
      claimTtlMinutes: dynamicToInt(json['claim_ttl_minutes']),
      claimChunkMode: dynamicToString(json['claim_chunk_mode']),
      claimChunkQty: dynamicToDouble(json['claim_chunk_qty']),
      qtyDemandedTotal: dynamicToDouble(json['qty_demanded_total']),
      qtyAlmacenadaTotal: dynamicToDouble(json['qty_almacenada_total']),
      qtyRecibidaTotal: dynamicToDouble(json['qty_recibida_total']),
      qtyAsignadaTotal: dynamicToDouble(json['qty_asignada_total']),
      qtyPendienteTotal: dynamicToDouble(json['qty_pendiente_total']),
      taskCount: dynamicToInt(json['task_count']),
      claimCount: dynamicToInt(json['claim_count']),
      proveedorId: dynamicToInt(json['proveedor_id']),
      proveedor: dynamicToString(json['proveedor']),
      pesoTotal: dynamicToDouble(json['peso_total']),
      numeroLineas: dynamicToInt(json['numero_lineas']),
      numeroItems: dynamicToDouble(json['numero_items']),
      origin: dynamicToString(json['origin']),
      originPickingId: dynamicToInt(json['origin_picking_id']),
      originPickingName: dynamicToString(json['origin_picking_name']),
      priority: dynamicToString(json['priority']),
      warehouseId: dynamicToInt(json['warehouse_id']),
      warehouseName: dynamicToString(json['warehouse_name']),
      pickingType: dynamicToString(json['picking_type']),
      pickingTypeCode: dynamicToString(json['picking_type_code']),
      backorderId: dynamicToInt(json['backorder_id']),
      backorderName: dynamicToString(json['backorder_name']),
      showCheckAvailability: dynamicToBool(json['show_check_availability']),
      manejaTemperatura: dynamicToBool(json['maneja_temperatura']),
      temperatura: dynamicToDouble(json['temperatura']),
      manejoPropietario: dynamicToBool(json['manejo_propietario']),
      propietario: dynamicToString(json['propietario']),
      locationOrigenId: dynamicToInt(json['location_origen_id']),
      locationOrigenName: dynamicToString(json['location_origen_name']),
      locationOrigenBarcode: dynamicToString(json['location_origen_barcode']),
      locationEntradaId: dynamicToInt(json['location_entrada_id']),
      locationEntradaName: dynamicToString(json['location_entrada_name']),
      locationDestId: dynamicToInt(json['location_dest_id']),
      locationDestName: dynamicToString(json['location_dest_name']),
      locationStockId: dynamicToInt(json['location_stock_id']),
      locationStockName: dynamicToString(json['location_stock_name']),
      esIntAlmacenamiento: dynamicToBool(json['es_int_almacenamiento']),
      recepcionUnPaso: dynamicToBool(json['recepcion_un_paso']),
    );
  }

  factory TransferenciaSessionModel.fromMap(Map<String, dynamic> map) {
    return TransferenciaSessionModel(
      sessionId: map[TransferenciaSessionsTable.columnSessionId] as int?,
      name: map[TransferenciaSessionsTable.columnName] as String?,
      state: map[TransferenciaSessionsTable.columnState] as String?,
      pickingId: map[TransferenciaSessionsTable.columnPickingId] as int?,
      pickingName: map[TransferenciaSessionsTable.columnPickingName] as String?,
      pickingState:
          map[TransferenciaSessionsTable.columnPickingState] as String?,
      progressPercent:
          (map[TransferenciaSessionsTable.columnProgressPercent] as num?)
              ?.toDouble(),
      pendingTasks: map[TransferenciaSessionsTable.columnPendingTasks] as int?,
      startTime: map[TransferenciaSessionsTable.columnStartTime] as String?,
      endTime: map[TransferenciaSessionsTable.columnEndTime] as String?,
      maxClaimsPerUser:
          map[TransferenciaSessionsTable.columnMaxClaimsPerUser] as int?,
      claimTtlMinutes:
          map[TransferenciaSessionsTable.columnClaimTtlMinutes] as int?,
      claimChunkMode:
          map[TransferenciaSessionsTable.columnClaimChunkMode] as String?,
      claimChunkQty:
          (map[TransferenciaSessionsTable.columnClaimChunkQty] as num?)
              ?.toDouble(),
      qtyDemandedTotal:
          (map[TransferenciaSessionsTable.columnQtyDemandedTotal] as num?)
              ?.toDouble(),
      qtyAlmacenadaTotal:
          (map[TransferenciaSessionsTable.columnQtyAlmacenadaTotal] as num?)
              ?.toDouble(),
      qtyRecibidaTotal:
          (map[TransferenciaSessionsTable.columnQtyRecibidaTotal] as num?)
              ?.toDouble(),
      qtyAsignadaTotal:
          (map[TransferenciaSessionsTable.columnQtyAsignadaTotal] as num?)
              ?.toDouble(),
      qtyPendienteTotal:
          (map[TransferenciaSessionsTable.columnQtyPendienteTotal] as num?)
              ?.toDouble(),
      taskCount: map[TransferenciaSessionsTable.columnTaskCount] as int?,
      claimCount: map[TransferenciaSessionsTable.columnClaimCount] as int?,
      proveedorId: map[TransferenciaSessionsTable.columnProveedorId] as int?,
      proveedor: map[TransferenciaSessionsTable.columnProveedor] as String?,
      pesoTotal: (map[TransferenciaSessionsTable.columnPesoTotal] as num?)
          ?.toDouble(),
      numeroLineas: map[TransferenciaSessionsTable.columnNumeroLineas] as int?,
      numeroItems: (map[TransferenciaSessionsTable.columnNumeroItems] as num?)
          ?.toDouble(),
      origin: map[TransferenciaSessionsTable.columnOrigin] as String?,
      originPickingId:
          map[TransferenciaSessionsTable.columnOriginPickingId] as int?,
      originPickingName:
          map[TransferenciaSessionsTable.columnOriginPickingName] as String?,
      priority: map[TransferenciaSessionsTable.columnPriority] as String?,
      warehouseId: map[TransferenciaSessionsTable.columnWarehouseId] as int?,
      warehouseName:
          map[TransferenciaSessionsTable.columnWarehouseName] as String?,
      pickingType: map[TransferenciaSessionsTable.columnPickingType] as String?,
      pickingTypeCode:
          map[TransferenciaSessionsTable.columnPickingTypeCode] as String?,
      backorderId: map[TransferenciaSessionsTable.columnBackorderId] as int?,
      backorderName:
          map[TransferenciaSessionsTable.columnBackorderName] as String?,
      showCheckAvailability:
          (map[TransferenciaSessionsTable.columnShowCheckAvailability]
              as int?) ==
          1,
      manejaTemperatura:
          (map[TransferenciaSessionsTable.columnManejaTemperatura] as int?) ==
          1,
      temperatura: (map[TransferenciaSessionsTable.columnTemperatura] as num?)
          ?.toDouble(),
      manejoPropietario:
          (map[TransferenciaSessionsTable.columnManejoPropietario] as int?) ==
          1,
      propietario: map[TransferenciaSessionsTable.columnPropietario] as String?,
      locationOrigenId:
          map[TransferenciaSessionsTable.columnLocationOrigenId] as int?,
      locationOrigenName:
          map[TransferenciaSessionsTable.columnLocationOrigenName] as String?,
      locationOrigenBarcode:
          map[TransferenciaSessionsTable.columnLocationOrigenBarcode]
              as String?,
      locationEntradaId:
          map[TransferenciaSessionsTable.columnLocationEntradaId] as int?,
      locationEntradaName:
          map[TransferenciaSessionsTable.columnLocationEntradaName] as String?,
      locationDestId:
          map[TransferenciaSessionsTable.columnLocationDestId] as int?,
      locationDestName:
          map[TransferenciaSessionsTable.columnLocationDestName] as String?,
      locationStockId:
          map[TransferenciaSessionsTable.columnLocationStockId] as int?,
      locationStockName:
          map[TransferenciaSessionsTable.columnLocationStockName] as String?,
      esIntAlmacenamiento:
          (map[TransferenciaSessionsTable.columnEsIntAlmacenamiento] as int?) ==
          1,
      recepcionUnPaso:
          (map[TransferenciaSessionsTable.columnRecepcionUnPaso] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      TransferenciaSessionsTable.columnSessionId: sessionId,
      TransferenciaSessionsTable.columnName: name,
      TransferenciaSessionsTable.columnState: state,
      TransferenciaSessionsTable.columnPickingId: pickingId,
      TransferenciaSessionsTable.columnPickingName: pickingName,
      TransferenciaSessionsTable.columnPickingState: pickingState,
      TransferenciaSessionsTable.columnProgressPercent: progressPercent,
      TransferenciaSessionsTable.columnPendingTasks: pendingTasks,
      TransferenciaSessionsTable.columnStartTime: startTime,
      TransferenciaSessionsTable.columnEndTime: endTime,
      TransferenciaSessionsTable.columnMaxClaimsPerUser: maxClaimsPerUser,
      TransferenciaSessionsTable.columnClaimTtlMinutes: claimTtlMinutes,
      TransferenciaSessionsTable.columnClaimChunkMode: claimChunkMode,
      TransferenciaSessionsTable.columnClaimChunkQty: claimChunkQty,
      TransferenciaSessionsTable.columnQtyDemandedTotal: qtyDemandedTotal,
      TransferenciaSessionsTable.columnQtyAlmacenadaTotal: qtyAlmacenadaTotal,
      TransferenciaSessionsTable.columnQtyRecibidaTotal: qtyRecibidaTotal,
      TransferenciaSessionsTable.columnQtyAsignadaTotal: qtyAsignadaTotal,
      TransferenciaSessionsTable.columnQtyPendienteTotal: qtyPendienteTotal,
      TransferenciaSessionsTable.columnTaskCount: taskCount,
      TransferenciaSessionsTable.columnClaimCount: claimCount,
      TransferenciaSessionsTable.columnProveedorId: proveedorId,
      TransferenciaSessionsTable.columnProveedor: proveedor,
      TransferenciaSessionsTable.columnPesoTotal: pesoTotal,
      TransferenciaSessionsTable.columnNumeroLineas: numeroLineas,
      TransferenciaSessionsTable.columnNumeroItems: numeroItems,
      TransferenciaSessionsTable.columnOrigin: origin,
      TransferenciaSessionsTable.columnOriginPickingId: originPickingId,
      TransferenciaSessionsTable.columnOriginPickingName: originPickingName,
      TransferenciaSessionsTable.columnPriority: priority,
      TransferenciaSessionsTable.columnWarehouseId: warehouseId,
      TransferenciaSessionsTable.columnWarehouseName: warehouseName,
      TransferenciaSessionsTable.columnPickingType: pickingType,
      TransferenciaSessionsTable.columnPickingTypeCode: pickingTypeCode,
      TransferenciaSessionsTable.columnBackorderId: backorderId,
      TransferenciaSessionsTable.columnBackorderName: backorderName,
      TransferenciaSessionsTable.columnShowCheckAvailability:
          showCheckAvailability == null
          ? null
          : (showCheckAvailability! ? 1 : 0),
      TransferenciaSessionsTable.columnManejaTemperatura:
          manejaTemperatura == null ? null : (manejaTemperatura! ? 1 : 0),
      TransferenciaSessionsTable.columnTemperatura: temperatura,
      TransferenciaSessionsTable.columnManejoPropietario:
          manejoPropietario == null ? null : (manejoPropietario! ? 1 : 0),
      TransferenciaSessionsTable.columnPropietario: propietario,
      TransferenciaSessionsTable.columnLocationOrigenId: locationOrigenId,
      TransferenciaSessionsTable.columnLocationOrigenName: locationOrigenName,
      TransferenciaSessionsTable.columnLocationOrigenBarcode:
          locationOrigenBarcode,
      TransferenciaSessionsTable.columnLocationEntradaId: locationEntradaId,
      TransferenciaSessionsTable.columnLocationEntradaName: locationEntradaName,
      TransferenciaSessionsTable.columnLocationDestId: locationDestId,
      TransferenciaSessionsTable.columnLocationDestName: locationDestName,
      TransferenciaSessionsTable.columnLocationStockId: locationStockId,
      TransferenciaSessionsTable.columnLocationStockName: locationStockName,
      TransferenciaSessionsTable.columnEsIntAlmacenamiento:
          esIntAlmacenamiento == null ? null : (esIntAlmacenamiento! ? 1 : 0),
      TransferenciaSessionsTable.columnRecepcionUnPaso: recepcionUnPaso == null
          ? null
          : (recepcionUnPaso! ? 1 : 0),
    };
  }
}
