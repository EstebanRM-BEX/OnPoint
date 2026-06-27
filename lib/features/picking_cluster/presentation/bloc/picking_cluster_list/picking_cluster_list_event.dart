part of 'picking_cluster_list_bloc.dart';

sealed class PickingClusterListEvent extends Equatable {
  const PickingClusterListEvent();

  @override
  List<Object?> get props => [];
}

class FetchClustersEvent extends PickingClusterListEvent {
  const FetchClustersEvent();
}

class LoadLocalClustersEvent extends PickingClusterListEvent {
  const LoadLocalClustersEvent();
}

class SelectBatchEvent extends PickingClusterListEvent {
  final PickingBatch batch;
  final DateTime? startTime;

  const SelectBatchEvent(this.batch, {this.startTime});

  @override
  List<Object?> get props => [batch, startTime];
}
