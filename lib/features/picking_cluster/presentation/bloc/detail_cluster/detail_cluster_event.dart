part of 'detail_cluster_bloc.dart';

sealed class DetailClusterEvent extends Equatable {
  const DetailClusterEvent();

  @override
  List<Object?> get props => [];
}

class ViewProductImageDetailEvent extends DetailClusterEvent {
  final int idProduct;

  const ViewProductImageDetailEvent(this.idProduct);

  @override
  List<Object?> get props => [idProduct];
}

/// Libera las zonas del usuario en el batch (zone_ids de zonas_trabajo).
class ReleaseZonasEvent extends DetailClusterEvent {
  final int batchId;
  final List<int> zoneIds;

  const ReleaseZonasEvent({required this.batchId, required this.zoneIds});

  @override
  List<Object?> get props => [batchId, zoneIds];
}
