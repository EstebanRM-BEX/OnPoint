part of 'transferencia_multiusuario_location_dest_bloc.dart';

sealed class TransferenciaMultiusuarioLocationDestState extends Equatable {
  const TransferenciaMultiusuarioLocationDestState();

  @override
  List<Object?> get props => [];
}

class TransferenciaMultiusuarioLocationDestInitial
    extends TransferenciaMultiusuarioLocationDestState {
  const TransferenciaMultiusuarioLocationDestInitial();
}

class TransferenciaMultiusuarioLocationDestLoading
    extends TransferenciaMultiusuarioLocationDestState {
  const TransferenciaMultiusuarioLocationDestLoading();
}

class TransferenciaMultiusuarioLocationDestLoaded
    extends TransferenciaMultiusuarioLocationDestState {
  const TransferenciaMultiusuarioLocationDestLoaded(this.ubicaciones);

  final List<ResultUbicaciones> ubicaciones;

  @override
  List<Object?> get props => [ubicaciones];
}

class TransferenciaMultiusuarioLocationDestError
    extends TransferenciaMultiusuarioLocationDestState {
  const TransferenciaMultiusuarioLocationDestError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
