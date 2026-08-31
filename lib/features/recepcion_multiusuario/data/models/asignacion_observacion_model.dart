import 'package:wms_app/features/recepcion_multiusuario/data/models/recepcion_multiusuario_json_utils.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/asignacion_observacion.dart';

class AsignacionObservacionModel extends AsignacionObservacion {
  const AsignacionObservacionModel({
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

  factory AsignacionObservacionModel.fromJson(Map<String, dynamic> json) {
    return AsignacionObservacionModel(
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

  factory AsignacionObservacionModel.fromMap(Map<String, dynamic> map) {
    return AsignacionObservacionModel(
      asignacionId: map['asignacion_id'] as int?,
      operarioId: map['operario_id'] as int?,
      operario: map['operario'] as String?,
      state: map['state'] as String?,
      qtyAsignada: (map['qty_asignada'] as num?)?.toDouble(),
      qtyRecibida: (map['qty_recibida'] as num?)?.toDouble(),
      observacion: map['observacion'] as String?,
      notaCorreccion: map['nota_correccion'] as String?,
      fechaAsignacion: map['fecha_asignacion'] as String?,
      fechaCompletado: map['fecha_completado'] as String?,
      lotId: map['lot_id'] as int?,
      lotName: map['lot_name'] as String?,
      locationDestId: map['location_dest_id'] as int?,
      locationDestName: map['location_dest_name'] as String?,
      timeSeconds: (map['time_seconds'] as num?)?.toDouble(),
      tiempoHoras: (map['tiempo_horas'] as num?)?.toDouble(),
      claimId: map['claim_id'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'asignacion_id': asignacionId,
      'operario_id': operarioId,
      'operario': operario,
      'state': state,
      'qty_asignada': qtyAsignada,
      'qty_recibida': qtyRecibida,
      'observacion': observacion,
      'nota_correccion': notaCorreccion,
      'fecha_asignacion': fechaAsignacion,
      'fecha_completado': fechaCompletado,
      'lot_id': lotId,
      'lot_name': lotName,
      'location_dest_id': locationDestId,
      'location_dest_name': locationDestName,
      'time_seconds': timeSeconds,
      'tiempo_horas': tiempoHoras,
      'claim_id': claimId,
    };
  }
}
