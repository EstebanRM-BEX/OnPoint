part of 'transferencia_multiusuario_lote_bloc.dart';

sealed class TransferenciaMultiusuarioLoteState extends Equatable {
  const TransferenciaMultiusuarioLoteState();

  @override
  List<Object> get props => [];
}

final class TransferenciaMultiusuarioLoteInitial
    extends TransferenciaMultiusuarioLoteState {
  const TransferenciaMultiusuarioLoteInitial();
}

final class TransferenciaMultiusuarioLoteLoading
    extends TransferenciaMultiusuarioLoteState {
  const TransferenciaMultiusuarioLoteLoading();
}

final class TransferenciaLotesLoaded
    extends TransferenciaMultiusuarioLoteState {
  final List<TransferenciaLoteProducto> lotes;
  const TransferenciaLotesLoaded(this.lotes);

  @override
  List<Object> get props => [lotes, Object()];
}

final class TransferenciaMultiusuarioLoteError
    extends TransferenciaMultiusuarioLoteState {
  final String message;
  const TransferenciaMultiusuarioLoteError(this.message);

  @override
  List<Object> get props => [message];
}

final class CreateTransferenciaLoteLoading
    extends TransferenciaMultiusuarioLoteState {
  const CreateTransferenciaLoteLoading();
}

final class CreateTransferenciaLoteSuccess
    extends TransferenciaMultiusuarioLoteState {
  final TransferenciaLoteProducto lote;
  const CreateTransferenciaLoteSuccess(this.lote);

  @override
  List<Object> get props => [lote, Object()];
}

/// El backend rechazó la fecha (anterior a hoy) pero ofrece reintentar
/// forzándola (code 202 de create_lote).
final class CreateTransferenciaLoteNeedsConfirmation
    extends TransferenciaMultiusuarioLoteState {
  final String message;
  const CreateTransferenciaLoteNeedsConfirmation(this.message);

  @override
  List<Object> get props => [message];
}

final class CreateTransferenciaLoteError
    extends TransferenciaMultiusuarioLoteState {
  final String message;
  const CreateTransferenciaLoteError(this.message);

  @override
  List<Object> get props => [message];
}
