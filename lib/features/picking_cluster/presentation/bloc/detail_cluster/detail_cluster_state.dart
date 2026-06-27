part of 'detail_cluster_bloc.dart';

sealed class DetailClusterState extends Equatable {
  const DetailClusterState();

  @override
  List<Object?> get props => [];
}

class DetailClusterInitial extends DetailClusterState {}

class ImageDetailLoading extends DetailClusterState {}

class ImageDetailSuccess extends DetailClusterState {
  final String url;

  const ImageDetailSuccess(this.url);

  @override
  List<Object?> get props => [url];
}

class ImageDetailFailure extends DetailClusterState {
  final String error;

  const ImageDetailFailure(this.error);

  @override
  List<Object?> get props => [error];
}
