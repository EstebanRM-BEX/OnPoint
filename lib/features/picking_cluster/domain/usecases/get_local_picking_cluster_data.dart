import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import '../entities/picking_batch.dart';
import '../repositories/picking_cluster_repository.dart';

@lazySingleton
class GetLocalPickingClusterData
    implements UseCase<List<PickingBatch>, NoParams> {
  final IPickingClusterRepository repository;

  GetLocalPickingClusterData(this.repository);

  @override
  Future<Either<Failure, List<PickingBatch>>> call(NoParams params) async {
    return await repository.getCachedPickingBatches();
  }
}
