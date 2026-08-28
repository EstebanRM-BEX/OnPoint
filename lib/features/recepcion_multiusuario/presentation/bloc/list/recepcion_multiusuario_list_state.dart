part of 'recepcion_multiusuario_list_bloc.dart';

sealed class RecepcionMultiusuarioListState extends Equatable {
  const RecepcionMultiusuarioListState();

  @override
  List<Object> get props => [];
}

final class RecepcionMultiusuarioListInitial
    extends RecepcionMultiusuarioListState {
  const RecepcionMultiusuarioListInitial();
}

final class RecepcionMultiusuarioListLoading
    extends RecepcionMultiusuarioListState {
  const RecepcionMultiusuarioListLoading();
}

final class RecepcionMultiusuarioListDbLoading
    extends RecepcionMultiusuarioListState {
  const RecepcionMultiusuarioListDbLoading();
}

final class RecepcionSessionsLoaded extends RecepcionMultiusuarioListState {
  final List<RecepcionSession> sessions;
  const RecepcionSessionsLoaded(this.sessions);

  @override
  List<Object> get props => [sessions, Object()];
}

final class RecepcionMultiusuarioListError
    extends RecepcionMultiusuarioListState {
  final String message;
  const RecepcionMultiusuarioListError(this.message);

  @override
  List<Object> get props => [message];
}
