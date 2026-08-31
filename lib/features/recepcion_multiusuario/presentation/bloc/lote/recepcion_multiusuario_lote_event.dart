part of 'recepcion_multiusuario_lote_bloc.dart';

sealed class RecepcionMultiusuarioLoteEvent extends Equatable {
  const RecepcionMultiusuarioLoteEvent();

  @override
  List<Object> get props => [];
}

/// Trae los lotes existentes de [productId] (GET /api/lotes/{productId}).
class FetchLotesEvent extends RecepcionMultiusuarioLoteEvent {
  final int productId;
  const FetchLotesEvent(this.productId);

  @override
  List<Object> get props => [productId];
}

/// Filtra la lista ya cargada por nombre de lote.
class SearchLoteEvent extends RecepcionMultiusuarioLoteEvent {
  final String query;
  const SearchLoteEvent(this.query);

  @override
  List<Object> get props => [query];
}

/// Crea un lote nuevo (POST /api/create_lote).
class CreateLoteEvent extends RecepcionMultiusuarioLoteEvent {
  final int productId;
  final String nombreLote;
  final String fechaVencimiento;
  final bool priorityExpiration;

  const CreateLoteEvent({
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
