import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import '../repositories/picking_cluster_repository.dart';

@lazySingleton
class SetClusterBatchProductFieldUseCase
    implements UseCase<void, SetClusterBatchProductFieldParams> {
  final IPickingClusterRepository repository;

  SetClusterBatchProductFieldUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(
      SetClusterBatchProductFieldParams params) async {
    return await repository.setFieldTableBatchProducts(
      params.batchId,
      params.productId,
      params.field,
      params.value,
      params.idMove,
      params.type,
    );
  }
}

class SetClusterBatchProductFieldParams {
  final int batchId;
  final int productId;
  final String field;
  final dynamic value;
  final int idMove;
  final String type;

  SetClusterBatchProductFieldParams({
    required this.batchId,
    required this.productId,
    required this.field,
    required this.value,
    required this.idMove,
    required this.type,
  });
}
