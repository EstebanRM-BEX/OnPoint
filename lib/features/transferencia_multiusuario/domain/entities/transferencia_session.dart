class TransferenciaSession {
  final int? sessionId;
  final String? name;
  final String? state;
  final int? pickingId;
  final String? pickingName;
  final String? pickingState;
  final double? progressPercent;
  final int? pendingTasks;
  final String? startTime;
  final String? endTime;
  final int? maxClaimsPerUser;
  final int? claimTtlMinutes;
  final String? claimChunkMode;
  final double? claimChunkQty;
  final double? qtyDemandedTotal;
  final double? qtyAlmacenadaTotal;
  final double? qtyRecibidaTotal;
  final double? qtyAsignadaTotal;
  final double? qtyPendienteTotal;
  final int? taskCount;
  final int? claimCount;
  final int? proveedorId;
  final String? proveedor;
  final double? pesoTotal;
  final int? numeroLineas;
  final double? numeroItems;
  final String? origin;
  final int? originPickingId;
  final String? originPickingName;
  final String? priority;
  final int? warehouseId;
  final String? warehouseName;
  final String? pickingType;
  final String? pickingTypeCode;
  final int? backorderId;
  final String? backorderName;
  final bool? showCheckAvailability;
  final bool? manejaTemperatura;
  final double? temperatura;
  final bool? manejoPropietario;
  final String? propietario;
  final int? locationOrigenId;
  final String? locationOrigenName;
  final String? locationOrigenBarcode;
  final int? locationEntradaId;
  final String? locationEntradaName;
  final int? locationDestId;
  final String? locationDestName;
  final int? locationStockId;
  final String? locationStockName;
  final bool? esIntAlmacenamiento;
  final bool? recepcionUnPaso;

  const TransferenciaSession({
    this.sessionId,
    this.name,
    this.state,
    this.pickingId,
    this.pickingName,
    this.pickingState,
    this.progressPercent,
    this.pendingTasks,
    this.startTime,
    this.endTime,
    this.maxClaimsPerUser,
    this.claimTtlMinutes,
    this.claimChunkMode,
    this.claimChunkQty,
    this.qtyDemandedTotal,
    this.qtyAlmacenadaTotal,
    this.qtyRecibidaTotal,
    this.qtyAsignadaTotal,
    this.qtyPendienteTotal,
    this.taskCount,
    this.claimCount,
    this.proveedorId,
    this.proveedor,
    this.pesoTotal,
    this.numeroLineas,
    this.numeroItems,
    this.origin,
    this.originPickingId,
    this.originPickingName,
    this.priority,
    this.warehouseId,
    this.warehouseName,
    this.pickingType,
    this.pickingTypeCode,
    this.backorderId,
    this.backorderName,
    this.showCheckAvailability,
    this.manejaTemperatura,
    this.temperatura,
    this.manejoPropietario,
    this.propietario,
    this.locationOrigenId,
    this.locationOrigenName,
    this.locationOrigenBarcode,
    this.locationEntradaId,
    this.locationEntradaName,
    this.locationDestId,
    this.locationDestName,
    this.locationStockId,
    this.locationStockName,
    this.esIntAlmacenamiento,
    this.recepcionUnPaso,
  });
}
