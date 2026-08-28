class RecepcionSession {
  final int? sessionId;
  final String? name;
  final int? pickingId;
  final String? pickingName;
  final int? warehouseId;
  final double? progressPercent;
  final int? pendingTasks;

  const RecepcionSession({
    this.sessionId,
    this.name,
    this.pickingId,
    this.pickingName,
    this.warehouseId,
    this.progressPercent,
    this.pendingTasks,
  });
}
