import 'package:wms_app/features/recepcion_multiusuario/data/models/recepcion_multiusuario_json_utils.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_claim.dart';

class RecepcionClaimModel extends RecepcionClaim {
  const RecepcionClaimModel({
    super.id,
    super.taskId,
    super.productId,
    super.productName,
    super.barcode,
    super.qtyAsignada,
    super.qtyRecibida,
    super.uom,
    super.state,
    super.lotId,
    super.lotName,
    super.fechaAsignacion,
    super.bloqueadoHasta,
    super.observacion,
    super.notaCorreccion,
  });

  /// `result.data` de POST /api/receipt/claim cuando `status == "success"`.
  factory RecepcionClaimModel.fromJson(Map<String, dynamic> json) {
    return RecepcionClaimModel(
      id: dynamicToInt(json['id']),
      taskId: dynamicToInt(json['task_id']),
      productId: dynamicToInt(json['product_id']),
      productName: dynamicToString(json['product_name']),
      barcode: dynamicToString(json['barcode']),
      qtyAsignada: dynamicToDouble(json['qty_asignada']),
      qtyRecibida: dynamicToDouble(json['qty_recibida']),
      uom: dynamicToString(json['uom']),
      state: dynamicToString(json['state']),
      // lot_id llega en `false` cuando el producto no maneja lote.
      lotId: dynamicToInt(json['lot_id']),
      lotName: dynamicToString(json['lot_name']),
      fechaAsignacion: dynamicToString(json['fecha_asignacion']),
      bloqueadoHasta: dynamicToString(json['bloqueado_hasta']),
      observacion: dynamicToString(json['observacion']),
      notaCorreccion: dynamicToString(json['nota_correccion']),
    );
  }
}
