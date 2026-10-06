import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import '../entities/picking_batch.dart';
import '../repositories/picking_cluster_repository.dart';

/// Asigna al usuario todas las zonas de trabajo de un batch al iniciarlo.
@lazySingleton
class AssignBatchZonasUseCase implements UseCase<PickingBatch, int> {
  final IPickingClusterRepository repository;

  AssignBatchZonasUseCase(this.repository);

  @override
  Future<Either<Failure, PickingBatch>> call(int batchId) =>
      repository.assignZonasBatch(batchId);
}
