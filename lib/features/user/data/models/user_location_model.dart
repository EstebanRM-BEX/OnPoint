import 'package:wms_app/features/user/domain/entities/user_location.dart';

class UserLocationModel extends UserLocation {
  const UserLocationModel({
    required super.id,
    required super.name,
    required super.idWarehouse,
    super.barcode,
    super.warehouseName,
  });

  factory UserLocationModel.fromJson(Map<String, dynamic> json) {
    return UserLocationModel(
      id: json['id'],
      name: json['name'],
      idWarehouse: json['warehouse_id'] is List
          ? json['warehouse_id'][0]
          : json['warehouse_id'] ?? 0,
      barcode: json['barcode'],
      warehouseName: json['warehouse_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'warehouse_id': idWarehouse,
      'barcode': barcode,
      'warehouse_name': warehouseName,
    };
  }
}
