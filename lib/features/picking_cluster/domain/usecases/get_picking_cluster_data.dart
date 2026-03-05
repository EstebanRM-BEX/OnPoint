import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import '../entities/picking_batch.dart';
import '../repositories/picking_cluster_repository.dart';

/// Use case to retrieve picking batches/clusters from the repository.
@lazySingleton
class GetPickingClusterData implements UseCase<List<PickingBatch>, NoParams> {
  final IPickingClusterRepository repository;

  GetPickingClusterData(this.repository);

  @override
  Future<Either<Failure, List<PickingBatch>>> call(NoParams params) async {
    return await repository.getPickingBatches();
  }
}
