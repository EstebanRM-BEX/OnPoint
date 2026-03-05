import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import '../entities/batch_product.dart';
import '../repositories/picking_cluster_repository.dart';

@lazySingleton
class GetProductBatchUseCase
    implements UseCase<BatchProduct?, GetProductBatchParams> {
  final IPickingClusterRepository repository;

  GetProductBatchUseCase(this.repository);

  @override
  Future<Either<Failure, BatchProduct?>> call(
      GetProductBatchParams params) async {
    return await repository.getProductBatch(
      params.batchId,
      params.productId,
      params.idMove,
      params.type,
    );
  }
}

class GetProductBatchParams {
  final int batchId;
  final int productId;
  final int idMove;
  final String type;

  GetProductBatchParams({
    required this.batchId,
    required this.productId,
    required this.idMove,
    required this.type,
  });
}
