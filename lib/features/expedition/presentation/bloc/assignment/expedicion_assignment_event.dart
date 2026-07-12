part of 'expedicion_assignment_bloc.dart';

sealed class ExpedicionAssignmentEvent extends Equatable {
  const ExpedicionAssignmentEvent();

  @override
  List<Object> get props => [];
}

/// Asigna el usuario autenticado como responsable de la expedición y arranca
/// su tiempo de transferencia (mismo flujo que _onAssignUserToPedido en
/// PackingPedidoBloc).
class AsignarResponsableEvent extends ExpedicionAssignmentEvent {
  final int expeditionId;
  const AsignarResponsableEvent(this.expeditionId);

  @override
  List<Object> get props => [expeditionId];
}
