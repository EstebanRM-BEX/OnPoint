import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import '../entities/batch_product.dart';
import '../repositories/picking_cluster_repository.dart';

@lazySingleton
class GetBarcodesProductUseCase
    implements UseCase<List<BatchBarcode>, GetBarcodesProductParams> {
  final IPickingClusterRepository repository;

  GetBarcodesProductUseCase(this.repository);

  @override
  Future<Either<Failure, List<BatchBarcode>>> call(
      GetBarcodesProductParams params) async {
    return await repository.getBarcodesProduct(
      params.batchId,
      params.productId,
      params.idMove,
      params.type,
    );
  }
}

class GetBarcodesProductParams {
  final int batchId;
  final int productId;
  final int idMove;
  final String type;

  GetBarcodesProductParams({
    required this.batchId,
    required this.productId,
    required this.idMove,
    required this.type,
  });
}
