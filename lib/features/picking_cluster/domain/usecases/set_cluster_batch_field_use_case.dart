import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import '../repositories/picking_cluster_repository.dart';

@lazySingleton
class SetClusterBatchFieldUseCase
    implements UseCase<void, SetClusterBatchFieldParams> {
  final IPickingClusterRepository repository;

  SetClusterBatchFieldUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SetClusterBatchFieldParams params) async {
    return await repository.setFieldTableBatch(
      params.batchId,
      params.field,
      params.value,
      params.type,
    );
  }
}

class SetClusterBatchFieldParams {
  final int batchId;
  final String field;
  final dynamic value;
  final String type;

  SetClusterBatchFieldParams({
    required this.batchId,
    required this.field,
    required this.value,
    required this.type,
  });
}
