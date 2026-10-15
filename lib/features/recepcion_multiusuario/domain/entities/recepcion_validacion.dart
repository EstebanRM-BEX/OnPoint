/// Resultado de POST /api/receipt/session/{sessionId}/validate: la sesión
/// multi cerrada y el picking validado.
class RecepcionValidacion {
  final int? sessionId;
  final String? sessionName;
  final String? sessionState;
  final int? pickingId;
  final String? pickingName;
  final String? pickingState;
  final String? validatorName;

  /// 0 si se recibió todo.
  final int? backorderId;
  final String? backorderName;
  final String? message;

  const RecepcionValidacion({
    this.sessionId,
    this.sessionName,
    this.sessionState,
    this.pickingId,
    this.pickingName,
    this.pickingState,
    this.validatorName,
    this.backorderId,
    this.backorderName,
    this.message,
  });

  /// Solo es éxito si la sesión y el picking quedaron en `done`.
  bool get completada => sessionState == 'done' && pickingState == 'done';

  bool get tieneBackorder => (backorderId ?? 0) > 0;
}
