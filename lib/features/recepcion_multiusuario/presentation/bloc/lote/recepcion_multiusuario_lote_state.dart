part of 'recepcion_multiusuario_lote_bloc.dart';

sealed class RecepcionMultiusuarioLoteState extends Equatable {
  const RecepcionMultiusuarioLoteState();

  @override
  List<Object> get props => [];
}

final class RecepcionMultiusuarioLoteInitial
    extends RecepcionMultiusuarioLoteState {
  const RecepcionMultiusuarioLoteInitial();
}

final class RecepcionMultiusuarioLoteLoading
    extends RecepcionMultiusuarioLoteState {
  const RecepcionMultiusuarioLoteLoading();
}

final class RecepcionLotesLoaded extends RecepcionMultiusuarioLoteState {
  final List<LoteProducto> lotes;
  const RecepcionLotesLoaded(this.lotes);

  @override
  List<Object> get props => [lotes, Object()];
}

final class RecepcionMultiusuarioLoteError
    extends RecepcionMultiusuarioLoteState {
  final String message;
  const RecepcionMultiusuarioLoteError(this.message);

  @override
  List<Object> get props => [message];
}

final class CreateLoteLoading extends RecepcionMultiusuarioLoteState {
  const CreateLoteLoading();
}

final class CreateLoteSuccess extends RecepcionMultiusuarioLoteState {
  final LoteProducto lote;
  const CreateLoteSuccess(this.lote);

  @override
  List<Object> get props => [lote, Object()];
}

/// El backend rechazó la fecha (anterior a hoy) pero ofrece reintentar
/// forzándola (code 202 de create_lote).
final class CreateLoteNeedsConfirmation extends RecepcionMultiusuarioLoteState {
  final String message;
  const CreateLoteNeedsConfirmation(this.message);

  @override
  List<Object> get props => [message];
}

final class CreateLoteError extends RecepcionMultiusuarioLoteState {
  final String message;
  const CreateLoteError(this.message);

  @override
  List<Object> get props => [message];
}
