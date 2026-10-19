import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import '../entities/picking_cluster_fetch_result.dart';
import '../repositories/picking_cluster_repository.dart';

/// Use case to retrieve picking batches/clusters from the repository.
@lazySingleton
class GetPickingClusterData implements UseCase<PickingClusterFetchResult, NoParams> {
  final IPickingClusterRepository repository;

  GetPickingClusterData(this.repository);

  @override
  Future<Either<Failure, PickingClusterFetchResult>> call(NoParams params) async {
    return await repository.getPickingBatches();
  }
}
