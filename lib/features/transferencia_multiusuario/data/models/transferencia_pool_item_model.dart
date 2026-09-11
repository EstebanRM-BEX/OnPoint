import 'package:wms_app/features/transferencia_multiusuario/data/models/transferencia_asignacion_observacion_model.dart';
import 'package:wms_app/features/transferencia_multiusuario/data/models/transferencia_multiusuario_json_utils.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_pool_item.dart';

class TransferenciaPoolItemModel extends TransferenciaPoolItem {
  const TransferenciaPoolItemModel({
    super.taskId,
    super.sessionId,
    super.productId,
    super.productName,
    super.defaultCode,
    super.barcode,
    super.qtyDemanded,
    super.qtyAsignada,
    super.qtyAlmacenada,
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

  /// Un elemento de `result.data` de POST /api/transfer/session/{id}/pool.
  /// [sessionId] no viene en el json (es el id de la ruta), se inyecta acá.
  factory TransferenciaPoolItemModel.fromJson(
    Map<String, dynamic> json, {
    required int sessionId,
  }) {
    final observaciones = (json['observaciones'] as List? ?? [])
        .map(
          (o) => TransferenciaAsignacionObservacionModel.fromJson(
            o as Map<String, dynamic>,
          ),
        )
        .toList();

    return TransferenciaPoolItemModel(
      taskId: dynamicToInt(json['task_id']),
      sessionId: sessionId,
      productId: dynamicToInt(json['product_id']),
      productName: dynamicToString(json['product_name']),
      defaultCode: dynamicToString(json['default_code']),
      barcode: dynamicToString(json['barcode']),
      qtyDemanded: dynamicToDouble(json['qty_demanded']),
      qtyAsignada: dynamicToDouble(json['qty_asignada']),
      qtyAlmacenada: dynamicToDouble(json['qty_almacenada']),
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
}
