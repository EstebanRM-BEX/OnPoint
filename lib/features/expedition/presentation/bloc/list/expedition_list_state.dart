part of 'expedition_list_bloc.dart';

sealed class ExpedicionListState extends Equatable {
  const ExpedicionListState();

  @override
  List<Object> get props => [];
}

final class ExpedicionListInitial extends ExpedicionListState {
  const ExpedicionListInitial();
}

final class ExpedicionListLoading extends ExpedicionListState {
  const ExpedicionListLoading();
}

final class ExpedicionListDbLoading extends ExpedicionListState {
  const ExpedicionListDbLoading();
}

final class ExpedicionesLoaded extends ExpedicionListState {
  final List<ExpedicionPedido> expediciones;
  const ExpedicionesLoaded(this.expediciones);

  @override
  List<Object> get props => [expediciones, Object()];
}

final class ExpedicionListError extends ExpedicionListState {
  final String message;
  const ExpedicionListError(this.message);

  @override
  List<Object> get props => [message];
}

final class NeedUpdateVersionExpedicionState extends ExpedicionListState {
  const NeedUpdateVersionExpedicionState();
}
