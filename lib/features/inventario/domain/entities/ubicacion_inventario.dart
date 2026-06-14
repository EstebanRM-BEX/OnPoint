// lib/features/inventario/domain/entities/ubicacion_inventario.dart

class UbicacionInventario {
  final int? id;
  final String? name;
  final String? barcode;
  final int? locationId;
  final String? locationName;
  final int? idWarehouse;
  final String? warehouseName;
  final bool? isADockAlter;

  const UbicacionInventario({
    this.id,
    this.name,
    this.barcode,
    this.locationId,
    this.locationName,
    this.idWarehouse,
    this.warehouseName,
    this.isADockAlter,
  });
}
