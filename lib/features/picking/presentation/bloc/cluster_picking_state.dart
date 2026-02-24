part of 'cluster_picking_bloc.dart';

sealed class ClusterPickingState extends Equatable {
  const ClusterPickingState();

  @override
  List<Object> get props => [];
}

final class ClusterPickingInitial extends ClusterPickingState {}

final class ScanSuccess extends ClusterPickingState {
  final String barcode;
  const ScanSuccess(this.barcode);

  @override
  List<Object> get props => [barcode];
}

final class ScanError extends ClusterPickingState {
  final String message;
  const ScanError(this.message);

  @override
  List<Object> get props => [message];
}
