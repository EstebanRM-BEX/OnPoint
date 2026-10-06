part of 'picking_cluster_list_bloc.dart';

sealed class PickingClusterListEvent extends Equatable {
  const PickingClusterListEvent();

  @override
  List<Object?> get props => [];
}

class FetchClustersEvent extends PickingClusterListEvent {
  /// Refresca en segundo plano: sin diálogo de carga ni mensajes de error
  /// (p. ej. tras un error de asignación de zonas, con el diálogo abierto).
  final bool silent;

  const FetchClustersEvent({this.silent = false});

  @override
  List<Object?> get props => [silent];
}

class LoadLocalClustersEvent extends PickingClusterListEvent {
  final bool silent;

  const LoadLocalClustersEvent({this.silent = false});

  @override
  List<Object?> get props => [silent];
}

class SelectBatchEvent extends PickingClusterListEvent {
  final PickingBatch batch;
  final DateTime? startTime;

  /// Asigna al usuario las zonas sin asignar del batch antes de abrirlo.
  final bool assignZonas;

  const SelectBatchEvent(
    this.batch, {
    this.startTime,
    this.assignZonas = false,
  });

  @override
  List<Object?> get props => [batch, startTime, assignZonas];
}
