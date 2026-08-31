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
  });
}
