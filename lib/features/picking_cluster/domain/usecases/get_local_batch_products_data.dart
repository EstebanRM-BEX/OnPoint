import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import '../entities/batch_product.dart';
import '../repositories/picking_cluster_repository.dart';

@lazySingleton
class GetLocalBatchProductsData
    implements UseCase<List<BatchProduct>, GetBatchProductsParams> {
  final IPickingClusterRepository repository;

  GetLocalBatchProductsData(this.repository);

  @override
  Future<Either<Failure, List<BatchProduct>>> call(
      GetBatchProductsParams params) async {
    return await repository.getBatchProducts(params.batchId);
  }
}

class GetBatchProductsParams {
  final int batchId;

  GetBatchProductsParams({required this.batchId});
}
