part of 'lote_producto_bloc.dart';

abstract class LoteProductoState extends Equatable {
  const LoteProductoState();

  @override
  List<Object?> get props => [];
}

class LoteProductoInitial extends LoteProductoState {}

class LoteProductoLoading extends LoteProductoState {}

class LotesProductoLoaded extends LoteProductoState {
  final List<LoteProducto> lotes;

  const LotesProductoLoaded(this.lotes);

  @override
  List<Object?> get props => [lotes];
}

class LoteProductoCreated extends LoteProductoState {
  final LoteProducto lote;

  const LoteProductoCreated(this.lote);

  @override
  List<Object?> get props => [lote];
}

class LoteProductoError extends LoteProductoState {
  final String message;

  const LoteProductoError(this.message);

  @override
  List<Object?> get props => [message];
}
