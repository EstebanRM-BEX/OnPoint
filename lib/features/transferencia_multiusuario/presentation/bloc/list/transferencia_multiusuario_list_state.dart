part of 'transferencia_multiusuario_list_bloc.dart';

sealed class TransferenciaMultiusuarioListState extends Equatable {
  const TransferenciaMultiusuarioListState();

  @override
  List<Object> get props => [];
}

final class TransferenciaMultiusuarioListInitial
    extends TransferenciaMultiusuarioListState {
  const TransferenciaMultiusuarioListInitial();
}

final class TransferenciaMultiusuarioListLoading
    extends TransferenciaMultiusuarioListState {
  const TransferenciaMultiusuarioListLoading();
}

final class TransferenciaMultiusuarioListDbLoading
    extends TransferenciaMultiusuarioListState {
  const TransferenciaMultiusuarioListDbLoading();
}

final class TransferenciaSessionsLoaded
    extends TransferenciaMultiusuarioListState {
  final List<TransferenciaSession> sessions;
  const TransferenciaSessionsLoaded(this.sessions);

  @override
  List<Object> get props => [sessions, Object()];
}

final class TransferenciaMultiusuarioListError
    extends TransferenciaMultiusuarioListState {
  final String message;
  const TransferenciaMultiusuarioListError(this.message);

  @override
  List<Object> get props => [message];
}
