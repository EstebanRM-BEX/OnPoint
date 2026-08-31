/// Una asignación histórica de un producto del pool
/// (`data[].observaciones[]` de POST /api/receipt/session/{id}/pool):
/// cada vez que un operario reclama, libera o termina ese producto queda un
/// registro acá. `state` puede ser, entre otros, `done` (recepción
/// terminada — lo que se muestra en el tab "Terminados"), `expired`
/// (bloqueo vencido sin terminar) o `released` (liberada manualmente).
class AsignacionObservacion {
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

  const AsignacionObservacion({
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
