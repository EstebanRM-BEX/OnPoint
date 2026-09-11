import 'package:wms_app/features/transferencia_multiusuario/data/models/transferencia_multiusuario_json_utils.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_asignacion_observacion.dart';

class TransferenciaAsignacionObservacionModel
    extends TransferenciaAsignacionObservacion {
  const TransferenciaAsignacionObservacionModel({
    super.asignacionId,
    super.operarioId,
    super.operario,
    super.state,
    super.qtyAsignada,
    super.qtyRecibida,
    super.observacion,
    super.notaCorreccion,
    super.fechaAsignacion,
    super.fechaCompletado,
    super.lotId,
    super.lotName,
    super.locationDestId,
    super.locationDestName,
    super.timeSeconds,
    super.tiempoHoras,
    super.claimId,
  });

  factory TransferenciaAsignacionObservacionModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return TransferenciaAsignacionObservacionModel(
      asignacionId: dynamicToInt(json['asignacion_id']),
      operarioId: dynamicToInt(json['operario_id']),
      operario: dynamicToString(json['operario']),
      state: dynamicToString(json['state']),
      qtyAsignada: dynamicToDouble(json['qty_asignada']),
      qtyRecibida: dynamicToDouble(json['qty_recibida']),
      observacion: dynamicToString(json['observacion']),
      notaCorreccion: dynamicToString(json['nota_correccion']),
      fechaAsignacion: dynamicToString(json['fecha_asignacion']),
      fechaCompletado: dynamicToString(json['fecha_completado']),
      lotId: dynamicToInt(json['lot_id']),
      lotName: dynamicToString(json['lot_name']),
      locationDestId: dynamicToInt(json['location_dest_id']),
      locationDestName: dynamicToString(json['location_dest_name']),
      timeSeconds: dynamicToDouble(json['time_seconds']),
      tiempoHoras: dynamicToDouble(json['tiempo_horas']),
      claimId: dynamicToInt(json['claim_id']),
    );
  }
}
