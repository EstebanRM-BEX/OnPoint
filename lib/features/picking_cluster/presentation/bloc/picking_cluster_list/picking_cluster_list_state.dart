part of 'picking_cluster_list_bloc.dart';

sealed class PickingClusterListState extends Equatable {
  const PickingClusterListState();

  @override
  List<Object?> get props => [];
}

class PickingClusterListInitial extends PickingClusterListState {}

class ClustersLoadingState extends PickingClusterListState {}

class ClustersLoadedState extends PickingClusterListState {
  final List<PickingBatch> batches;

  const ClustersLoadedState(this.batches);

  @override
  List<Object?> get props => [batches];
}

/// Lista recargada en segundo plano: la pantalla la repinta pero no cierra
/// diálogos ni muestra mensajes.
class ClustersSilentLoadedState extends ClustersLoadedState {
  const ClustersSilentLoadedState(super.batches);
}

class ClustersErrorState extends PickingClusterListState {
  final String message;

  const ClustersErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

// Señal de que la carga de productos fue delegada a ClusterPickingBloc.
// La pantalla escucha a ClusterPickingBloc para BatchProductsLoaded/Error.
class BatchDelegatedState extends PickingClusterListState {}

class BatchStartTimeErrorState extends PickingClusterListState {
  final String message;

  const BatchStartTimeErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

/// Asignando al usuario las zonas del batch (antes de abrirlo).
class BatchZonasAssigningState extends PickingClusterListState {}

/// Zonas asignadas correctamente; el flujo continúa hacia el batch.
class BatchZonasAssignedState extends PickingClusterListState {}

class BatchZonasErrorState extends PickingClusterListState {
  final String message;

  const BatchZonasErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
