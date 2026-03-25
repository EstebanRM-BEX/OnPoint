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
    this.id = 0,
    this.name = '',
    this.barcode = '',
    this.maxWeight = 0.0,
    this.height = 0.0,
    this.width = 0.0,
    this.packagingLength = 0.0,
    this.size = '',
    this.carrier = '',
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
