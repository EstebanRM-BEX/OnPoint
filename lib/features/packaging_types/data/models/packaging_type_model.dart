import '../../domain/entities/packaging_type.dart';

class PackagingTypeModel extends PackagingType {
  const PackagingTypeModel({
    required super.id,
    required super.name,
    required super.barcode,
    required super.maxWeight,
    required super.height,
    required super.width,
    required super.packagingLength,
    required super.size,
    required super.carrier,
  });

  factory PackagingTypeModel.fromJson(Map<String, dynamic> json) {
    return PackagingTypeModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      maxWeight: (json['max_weight'] as num?)?.toDouble() ?? 0.0,
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      packagingLength: (json['packaging_length'] as num?)?.toDouble() ?? 0.0,
      size: json['tamaño'] as String? ?? '',
      carrier: json['transportista'] as String? ?? 'none',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'max_weight': maxWeight,
      'height': height,
      'width': width,
      'packaging_length': packagingLength,
      'tamaño': size,
      'transportista': carrier,
    };
  }
}
