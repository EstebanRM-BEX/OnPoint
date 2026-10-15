class RecepcionSession {
  final int? sessionId;
  final String? name;
  final String? state;
  final int? pickingId;
  final String? pickingName;
  final double? progressPercent;
  final int? pendingTasks;
  final int? proveedorId;
  final String? proveedor;
  final double? pesoTotal;
  final int? numeroLineas;
  final double? numeroItems;
  final String? origin;
  final String? priority;
  final int? warehouseId;
  final String? warehouseName;
  final String? pickingType;
  final int? backorderId;
  final String? backorderName;
  final bool? showCheckAvailability;
  final bool? manejaTemperatura;
  final double? temperatura;
  final bool? manejoPropietario;
  final String? propietario;

  // Validación del documento (stock_receipt_validator). Solo validatorId y
  // validatorName se guardan en SQLite (para la lista); el resto se lee
  // fresco del backend antes de validar.
  /// 0 si nadie está asignado como validador.
  final int? validatorId;
  final String? validatorName;
  /// Claims `in_progress`: con más de 0 no se puede validar.
  final int? linesAssigned;
  final bool? currentUserCanBeValidator;
  final bool? currentUserIsValidator;
  final bool? canValidateDocument;

  const RecepcionSession({
    this.sessionId,
    this.name,
    this.state,
    this.pickingId,
    this.pickingName,
    this.progressPercent,
    this.pendingTasks,
    this.proveedorId,
    this.proveedor,
    this.pesoTotal,
    this.numeroLineas,
    this.numeroItems,
    this.origin,
    this.priority,
    this.warehouseId,
    this.warehouseName,
    this.pickingType,
    this.backorderId,
    this.backorderName,
    this.showCheckAvailability,
    this.manejaTemperatura,
    this.temperatura,
    this.manejoPropietario,
    this.propietario,
    this.validatorId,
    this.validatorName,
    this.linesAssigned,
    this.currentUserCanBeValidator,
    this.currentUserIsValidator,
    this.canValidateDocument,
  });
}
