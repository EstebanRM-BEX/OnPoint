import 'package:equatable/equatable.dart';

/// Representación inmutable de un producto del catálogo local para búsqueda y listado.
class ProductoCatalogo extends Equatable {
  final int id;
  final String name;
  final String? code;
  final String? barcode;
  final String? lotName;
  final int? lotId;
  final String? locationName;
  final int? locationId;
  final double? quantity;
  final List<String> otherBarcodes;
  final String? propietario;
  final bool manejoPropietario;

  const ProductoCatalogo({
    required this.id,
    required this.name,
    this.code,
    this.barcode,
    this.lotName,
    this.lotId,
    this.locationName,
    this.locationId,
    this.quantity,
    this.otherBarcodes = const [],
    this.propietario,
    this.manejoPropietario = false,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        barcode,
        lotName,
        lotId,
        locationName,
        locationId,
        quantity,
        otherBarcodes,
        propietario,
        manejoPropietario,
      ];
}

/// Representación inmutable de una ubicación del catálogo local para búsqueda y selección.
class UbicacionCatalogo extends Equatable {
  final int id;
  final String name;
  final String? barcode;
  final int? idWarehouse;
  final String? warehouseName;
  final int? locationParentId;
  final String? locationParentName;
  final bool isADock;

  const UbicacionCatalogo({
    required this.id,
    required this.name,
    this.barcode,
    this.idWarehouse,
    this.warehouseName,
    this.locationParentId,
    this.locationParentName,
    this.isADock = false,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        barcode,
        idWarehouse,
        warehouseName,
        locationParentId,
        locationParentName,
        isADock,
      ];
}
