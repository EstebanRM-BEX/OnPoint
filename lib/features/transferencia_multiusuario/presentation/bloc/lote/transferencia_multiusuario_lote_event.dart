part of 'transferencia_multiusuario_lote_bloc.dart';

sealed class TransferenciaMultiusuarioLoteEvent extends Equatable {
  const TransferenciaMultiusuarioLoteEvent();

  @override
  List<Object> get props => [];
}

/// Trae los lotes existentes de [productId] (GET /api/lotes/{productId}).
class FetchTransferenciaLotesEvent extends TransferenciaMultiusuarioLoteEvent {
  final int productId;
  const FetchTransferenciaLotesEvent(this.productId);

  @override
  List<Object> get props => [productId];
}

/// Filtra la lista ya cargada por nombre de lote.
class SearchTransferenciaLoteEvent extends TransferenciaMultiusuarioLoteEvent {
  final String query;
  const SearchTransferenciaLoteEvent(this.query);

  @override
  List<Object> get props => [query];
}

/// Crea un lote nuevo (POST /api/create_lote).
class CreateTransferenciaLoteEvent extends TransferenciaMultiusuarioLoteEvent {
  final int productId;
  final String nombreLote;
  final String fechaVencimiento;
  final bool priorityExpiration;

  const CreateTransferenciaLoteEvent({
    required this.productId,
    required this.nombreLote,
    required this.fechaVencimiento,
    this.priorityExpiration = false,
  });

  @override
  List<Object> get props => [
    productId,
    nombreLote,
    fechaVencimiento,
    priorityExpiration,
  ];
}
