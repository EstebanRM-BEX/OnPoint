part of 'recepcion_multiusuario_location_dest_bloc.dart';

sealed class RecepcionMultiusuarioLocationDestState extends Equatable {
  const RecepcionMultiusuarioLocationDestState();

  @override
  List<Object?> get props => [];
}

class RecepcionMultiusuarioLocationDestInitial
    extends RecepcionMultiusuarioLocationDestState {
  const RecepcionMultiusuarioLocationDestInitial();
}

class RecepcionMultiusuarioLocationDestLoading
    extends RecepcionMultiusuarioLocationDestState {
  const RecepcionMultiusuarioLocationDestLoading();
}

class RecepcionMultiusuarioLocationDestLoaded
    extends RecepcionMultiusuarioLocationDestState {
  const RecepcionMultiusuarioLocationDestLoaded(this.ubicaciones);

  final List<ResultUbicaciones> ubicaciones;

  @override
  List<Object?> get props => [ubicaciones];
}

class RecepcionMultiusuarioLocationDestError
    extends RecepcionMultiusuarioLocationDestState {
  const RecepcionMultiusuarioLocationDestError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
