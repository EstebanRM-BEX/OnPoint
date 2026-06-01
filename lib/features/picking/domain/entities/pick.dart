/// Domain entity for a picking transfer.
/// Pure business object without any framework dependencies.
class Pick {
  final int? id;
  final String? name;
  final String? observacion;
  final String? fechaCreacion;
  final String? proveedor;
  final String? origin;
  final String? priority;
  final int? responsableId;
  final String? responsable;
  final String? pickingType;
  final String? startTimeTransfer;
  final int? backorderId;
  final String? backorderName;
  final dynamic isSeparate;
  final dynamic isSelected;
  final String? zonaEntrega;
  final dynamic numeroLineas;
  final dynamic numeroItems;

  const Pick({
    this.id,
    this.name,
    this.observacion,
    this.fechaCreacion,
    this.proveedor,
    this.origin,
    this.priority,
    this.responsableId,
    this.responsable,
    this.pickingType,
    this.startTimeTransfer,
    this.backorderId,
    this.backorderName,
    this.isSeparate,
    this.isSelected,
    this.zonaEntrega,
    this.numeroLineas,
    this.numeroItems,
  });
}
