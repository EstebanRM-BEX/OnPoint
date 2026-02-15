import 'package:equatable/equatable.dart';

class UserLocation extends Equatable {
  final int id;
  final String name;
  final int idWarehouse;
  final String? barcode;
  final String? warehouseName;

  const UserLocation({
    required this.id,
    required this.name,
    required this.idWarehouse,
    this.barcode,
    this.warehouseName,
  });

  @override
  List<Object?> get props => [id, name, idWarehouse, barcode, warehouseName];
}
