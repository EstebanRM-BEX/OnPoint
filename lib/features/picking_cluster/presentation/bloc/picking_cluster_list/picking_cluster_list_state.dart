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
