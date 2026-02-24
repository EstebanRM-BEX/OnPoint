import 'package:equatable/equatable.dart';

class UserLocation extends Equatable {
  final int id;
  final String name;
  final int idWarehouse;
  final String? barcode;
  final String? warehouseName;
  final int? locationId;
  final String? locationName;

  const UserLocation({
    required this.id,
    required this.name,
    required this.idWarehouse,
    this.barcode,
    this.warehouseName,
    this.locationId,
    this.locationName,
  });

  @override
  List<Object?> get props =>
      [id, name, idWarehouse, barcode, warehouseName, locationId, locationName];
}
