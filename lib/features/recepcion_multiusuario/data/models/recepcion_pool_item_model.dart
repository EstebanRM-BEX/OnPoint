import 'dart:convert';

import 'package:wms_app/features/recepcion_multiusuario/data/models/asignacion_observacion_model.dart';
import 'package:wms_app/features/recepcion_multiusuario/data/models/recepcion_multiusuario_json_utils.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/asignacion_observacion.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_pool_item.dart';
import 'package:wms_app/src/presentation/providers/db/recepcion_multiusuario/tbl_recepcion_session_pool/recepcion_session_pool_table.dart';

class RecepcionPoolItemModel extends RecepcionPoolItem {
  const RecepcionPoolItemModel({
    super.taskId,
    super.sessionId,
    super.productId,
    super.productName,
    super.defaultCode,
    super.barcode,
    super.qtyDemanded,
    super.qtyAsignada,
    super.qtyRecibida,
    super.qtyAvailable,
    super.uom,
    super.asignacionesActivas,
    super.qtyClaimed,
    super.qtyDone,
    super.taskState,
    super.tieneObservaciones,
    super.observaciones,
  });

  /// Un elemento de `result.data` de POST /api/receipt/session/{id}/pool.
  /// [sessionId] no viene en el json (es el id de la ruta), se inyecta acá.
  factory RecepcionPoolItemModel.fromJson(
    Map<String, dynamic> json, {
    required int sessionId,
  }) {
    final observaciones = (json['observaciones'] as List? ?? [])
        .map(
          (o) => AsignacionObservacionModel.fromJson(o as Map<String, dynamic>),
        )
        .toList();

    return RecepcionPoolItemModel(
      taskId: dynamicToInt(json['task_id']),
      sessionId: sessionId,
      productId: dynamicToInt(json['product_id']),
      productName: dynamicToString(json['product_name']),
      defaultCode: dynamicToString(json['default_code']),
      barcode: dynamicToString(json['barcode']),
      qtyDemanded: dynamicToDouble(json['qty_demanded']),
      qtyAsignada: dynamicToDouble(json['qty_asignada']),
      qtyRecibida: dynamicToDouble(json['qty_recibida']),
      qtyAvailable: dynamicToDouble(json['qty_available']),
      uom: dynamicToString(json['uom']),
      asignacionesActivas: dynamicToInt(json['asignaciones_activas']),
      qtyClaimed: dynamicToDouble(json['qty_claimed']),
      qtyDone: dynamicToDouble(json['qty_done']),
      taskState: dynamicToString(json['task_state']),
      tieneObservaciones: dynamicToBool(json['tiene_observaciones']),
      observaciones: observaciones,
    );
  }

  factory RecepcionPoolItemModel.fromMap(Map<String, dynamic> map) {
    final observacionesJson =
        map[RecepcionSessionPoolTable.columnObservacionesJson] as String?;
    final observaciones = observacionesJson == null || observacionesJson.isEmpty
        ? const <AsignacionObservacion>[]
        : (jsonDecode(observacionesJson) as List)
              .map(
                (o) => AsignacionObservacionModel.fromMap(
                  o as Map<String, dynamic>,
                ),
              )
              .toList();

    return RecepcionPoolItemModel(
      taskId: map[RecepcionSessionPoolTable.columnTaskId] as int?,
      sessionId: map[RecepcionSessionPoolTable.columnSessionId] as int?,
      productId: map[RecepcionSessionPoolTable.columnProductId] as int?,
      productName: map[RecepcionSessionPoolTable.columnProductName] as String?,
      defaultCode: map[RecepcionSessionPoolTable.columnDefaultCode] as String?,
      barcode: map[RecepcionSessionPoolTable.columnBarcode] as String?,
      qtyDemanded: (map[RecepcionSessionPoolTable.columnQtyDemanded] as num?)
          ?.toDouble(),
      qtyAsignada: (map[RecepcionSessionPoolTable.columnQtyAsignada] as num?)
          ?.toDouble(),
      qtyRecibida: (map[RecepcionSessionPoolTable.columnQtyRecibida] as num?)
          ?.toDouble(),
      qtyAvailable: (map[RecepcionSessionPoolTable.columnQtyAvailable] as num?)
          ?.toDouble(),
      uom: map[RecepcionSessionPoolTable.columnUom] as String?,
      asignacionesActivas:
          map[RecepcionSessionPoolTable.columnAsignacionesActivas] as int?,
      qtyClaimed: (map[RecepcionSessionPoolTable.columnQtyClaimed] as num?)
          ?.toDouble(),
      qtyDone: (map[RecepcionSessionPoolTable.columnQtyDone] as num?)
          ?.toDouble(),
      taskState: map[RecepcionSessionPoolTable.columnTaskState] as String?,
      tieneObservaciones:
          (map[RecepcionSessionPoolTable.columnTieneObservaciones] as int?) ==
          1,
      observaciones: observaciones,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      RecepcionSessionPoolTable.columnTaskId: taskId,
      RecepcionSessionPoolTable.columnSessionId: sessionId,
      RecepcionSessionPoolTable.columnProductId: productId,
      RecepcionSessionPoolTable.columnProductName: productName,
      RecepcionSessionPoolTable.columnDefaultCode: defaultCode,
      RecepcionSessionPoolTable.columnBarcode: barcode,
      RecepcionSessionPoolTable.columnQtyDemanded: qtyDemanded,
      RecepcionSessionPoolTable.columnQtyAsignada: qtyAsignada,
      RecepcionSessionPoolTable.columnQtyRecibida: qtyRecibida,
      RecepcionSessionPoolTable.columnQtyAvailable: qtyAvailable,
      RecepcionSessionPoolTable.columnUom: uom,
      RecepcionSessionPoolTable.columnAsignacionesActivas: asignacionesActivas,
      RecepcionSessionPoolTable.columnQtyClaimed: qtyClaimed,
      RecepcionSessionPoolTable.columnQtyDone: qtyDone,
      RecepcionSessionPoolTable.columnTaskState: taskState,
      RecepcionSessionPoolTable.columnTieneObservaciones:
          tieneObservaciones == true ? 1 : 0,
      RecepcionSessionPoolTable.columnObservacionesJson: jsonEncode(
        observaciones
            .whereType<AsignacionObservacionModel>()
            .map((o) => o.toMap())
            .toList(),
      ),
    };
  }
}
