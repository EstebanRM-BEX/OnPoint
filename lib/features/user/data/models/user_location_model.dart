import 'package:wms_app/features/user/domain/entities/user_location.dart';

class UserLocationModel extends UserLocation {
  const UserLocationModel({
    required super.id,
    required super.name,
    required super.idWarehouse,
    required super.locationId,
    required super.locationName,
    super.barcode,
    super.warehouseName,
  });

  factory UserLocationModel.fromJson(Map<String, dynamic> json) {
    return UserLocationModel(
      id: json['id'],
      name: json['name'],
      idWarehouse: json['warehouse_id'] is List
          ? json['warehouse_id'][0]
          : json['id_warehouse'] ?? 0,
      barcode: json['barcode'],
      locationId: json['location_id'],
      locationName: json['location_name'],
      warehouseName: json['warehouse_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'id_warehouse': idWarehouse,
      'barcode': barcode,
      'location_id': locationId,
      'location_name': locationName,
      'warehouse_name': warehouseName,
    };
  }
}
