import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import '../repositories/picking_cluster_repository.dart';

/// Libera las zonas de trabajo del usuario en un batch de Pick Cluster.
@lazySingleton
class ReleaseBatchZonasUseCase
    implements UseCase<String, ReleaseBatchZonasParams> {
  final IPickingClusterRepository repository;

  ReleaseBatchZonasUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(ReleaseBatchZonasParams params) =>
      repository.releaseZonasBatch(params.batchId, params.zoneIds);
}

class ReleaseBatchZonasParams extends Equatable {
  final int batchId;
  final List<int> zoneIds;

  const ReleaseBatchZonasParams({
    required this.batchId,
    required this.zoneIds,
  });

  @override
  List<Object?> get props => [batchId, zoneIds];
}
