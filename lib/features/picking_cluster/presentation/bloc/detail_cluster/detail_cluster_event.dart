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
