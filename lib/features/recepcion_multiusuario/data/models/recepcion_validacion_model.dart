import 'package:wms_app/features/recepcion_multiusuario/data/models/recepcion_multiusuario_json_utils.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_validacion.dart';

class RecepcionValidacionModel extends RecepcionValidacion {
  const RecepcionValidacionModel({
    super.sessionId,
    super.sessionName,
    super.sessionState,
    super.pickingId,
    super.pickingName,
    super.pickingState,
    super.validatorName,
    super.backorderId,
    super.backorderName,
    super.message,
  });

  /// `result.data` (+ `result.message`) de
  /// POST /api/receipt/session/{sessionId}/validate.
  factory RecepcionValidacionModel.fromJson(
    Map<String, dynamic> json, {
    String? message,
  }) {
    return RecepcionValidacionModel(
      sessionId: dynamicToInt(json['session_id']),
      sessionName: dynamicToString(json['session_name']),
      sessionState: dynamicToString(json['session_state']),
      pickingId: dynamicToInt(json['picking_id']),
      pickingName: dynamicToString(json['picking_name']),
      pickingState: dynamicToString(json['picking_state']),
      validatorName: dynamicToString(json['validator_name']),
      backorderId: dynamicToInt(json['backorder_id']),
      backorderName: dynamicToString(json['backorder_name']),
      message: message,
    );
  }
}
