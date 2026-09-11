/// Una asignación histórica de un producto del pool
/// (`data[].observaciones[]` de POST /api/transfer/session/{id}/pool).
/// Espejo exacto de AsignacionObservacion (recepción) — mismo backend, misma
/// forma de objeto.
class TransferenciaAsignacionObservacion {
  final int? asignacionId;
  final int? operarioId;
  final String? operario;
  final String? state;
  final double? qtyAsignada;
  final double? qtyRecibida;
  final String? observacion;
  final String? notaCorreccion;
  final String? fechaAsignacion;
  final String? fechaCompletado;
  final int? lotId;
  final String? lotName;
  final int? locationDestId;
  final String? locationDestName;
  final double? timeSeconds;
  final double? tiempoHoras;
  final int? claimId;

  const TransferenciaAsignacionObservacion({
    this.asignacionId,
    this.operarioId,
    this.operario,
    this.state,
    this.qtyAsignada,
    this.qtyRecibida,
    this.observacion,
    this.notaCorreccion,
    this.fechaAsignacion,
    this.fechaCompletado,
    this.lotId,
    this.lotName,
    this.locationDestId,
    this.locationDestName,
    this.timeSeconds,
    this.tiempoHoras,
    this.claimId,
  });

  bool get isDone => state == 'done';
}
