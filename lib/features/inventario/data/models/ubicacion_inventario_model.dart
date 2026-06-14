// lib/features/inventario/data/models/ubicacion_inventario_model.dart

import 'package:wms_app/features/inventario/domain/entities/ubicacion_inventario.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart' as legacy;

class UbicacionInventarioModel extends UbicacionInventario {
  const UbicacionInventarioModel({
    super.id,
    super.name,
    super.barcode,
    super.locationId,
    super.locationName,
    super.idWarehouse,
    super.warehouseName,
    super.isADockAlter,
  });

  factory UbicacionInventarioModel.fromLegacy(legacy.ResultUbicaciones u) =>
      UbicacionInventarioModel(
        id: u.id,
        name: u.name,
        barcode: u.barcode,
        locationId: u.locationId,
        locationName: u.locationName,
        idWarehouse: u.idWarehouse,
        warehouseName: u.warehouseName,
        isADockAlter: u.isADockAlter,
      );

  legacy.ResultUbicaciones toLegacy() => legacy.ResultUbicaciones(
        id: id,
        name: name,
        barcode: barcode,
        locationId: locationId,
        locationName: locationName,
        idWarehouse: idWarehouse,
        warehouseName: warehouseName,
        isADockAlter: isADockAlter,
      );
}
