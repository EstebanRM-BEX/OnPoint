part of 'expedicion_assignment_bloc.dart';

sealed class ExpedicionAssignmentState extends Equatable {
  const ExpedicionAssignmentState();

  @override
  List<Object> get props => [];
}

final class ExpedicionAssignmentInitial extends ExpedicionAssignmentState {
  const ExpedicionAssignmentInitial();
}

final class ExpedicionAssignmentLoading extends ExpedicionAssignmentState {
  const ExpedicionAssignmentLoading();
}

final class ExpedicionAssignmentSuccess extends ExpedicionAssignmentState {
  final ExpedicionPedido pedido;
  const ExpedicionAssignmentSuccess(this.pedido);

  @override
  List<Object> get props => [pedido];
}

final class ExpedicionAssignmentError extends ExpedicionAssignmentState {
  final String message;
  const ExpedicionAssignmentError(this.message);

  @override
  List<Object> get props => [message];
}
