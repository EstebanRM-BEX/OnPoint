part of 'lote_producto_bloc.dart';

abstract class LoteProductoEvent extends Equatable {
  const LoteProductoEvent();

  @override
  List<Object?> get props => [];
}

class FetchLotesProductoEvent extends LoteProductoEvent {
  final int productId;

  const FetchLotesProductoEvent({required this.productId});

  @override
  List<Object?> get props => [productId];
}

class CrearLoteProductoEvent extends LoteProductoEvent {
  final int productId;
  final String name;
  final String? expirationDate;

  const CrearLoteProductoEvent({
    required this.productId,
    required this.name,
    this.expirationDate,
  });

  @override
  List<Object?> get props => [productId, name, expirationDate];
}
