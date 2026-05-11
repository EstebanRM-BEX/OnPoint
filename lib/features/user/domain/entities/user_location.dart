import 'package:equatable/equatable.dart';

class UserLocation extends Equatable {
  final int id;
  final String name;
  final int idWarehouse;
  final String? barcode;
  final String? warehouseName;
  final int? locationId;
  final String? locationName;
  final bool? isADockAlter;

  const UserLocation({
    required this.id,
    required this.name,
    required this.idWarehouse,
    this.barcode,
    this.warehouseName,
    this.locationId,
    this.locationName,
    this.isADockAlter,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        idWarehouse,
        barcode,
        warehouseName,
        locationId,
        locationName,
        isADockAlter,
      ];
}
