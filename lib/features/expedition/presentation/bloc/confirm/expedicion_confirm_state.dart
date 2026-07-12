part of 'expedicion_confirm_bloc.dart';

sealed class ExpedicionConfirmState extends Equatable {
  const ExpedicionConfirmState();

  @override
  List<Object> get props => [];
}

final class ExpedicionConfirmInitial extends ExpedicionConfirmState {
  const ExpedicionConfirmInitial();
}

final class ExpedicionConfirmLoading extends ExpedicionConfirmState {
  const ExpedicionConfirmLoading();
}

final class ExpedicionConfirmSuccess extends ExpedicionConfirmState {
  const ExpedicionConfirmSuccess();
}

final class ExpedicionConfirmError extends ExpedicionConfirmState {
  final String message;

  const ExpedicionConfirmError(this.message);

  @override
  List<Object> get props => [message];
}
