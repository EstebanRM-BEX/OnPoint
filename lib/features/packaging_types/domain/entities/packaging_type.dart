import 'package:equatable/equatable.dart';

class PackagingType extends Equatable {
  final int id;
  final String name;
  final String barcode;
  final double maxWeight;
  final double height;
  final double width;
  final double packagingLength;
  final String size; // mapping to 'tamaño'
  final String carrier; // mapping to 'transportista'

  const PackagingType({
    required this.id,
    required this.name,
    required this.barcode,
    required this.maxWeight,
    required this.height,
    required this.width,
    required this.packagingLength,
    required this.size,
    required this.carrier,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        barcode,
        maxWeight,
        height,
        width,
        packagingLength,
        size,
        carrier,
      ];
}
