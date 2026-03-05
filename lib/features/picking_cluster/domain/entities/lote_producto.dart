import 'package:equatable/equatable.dart';

/// Represents a batch (lote) associated with a product.
class LoteProducto extends Equatable {
  final int? id;
  final String? name;
  final int? quantity;
  final DateTime? expirationDate;
  final DateTime? removalDate;
  final DateTime? useDate;
  final int? productId;
  final String? productName;

  const LoteProducto({
    this.id,
    this.name,
    this.quantity,
    this.expirationDate,
    this.removalDate,
    this.useDate,
    this.productId,
    this.productName,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        quantity,
        expirationDate,
        removalDate,
        useDate,
        productId,
        productName,
      ];
}
