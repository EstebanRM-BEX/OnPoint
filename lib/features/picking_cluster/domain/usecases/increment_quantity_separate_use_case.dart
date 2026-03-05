import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import '../repositories/picking_cluster_repository.dart';

@lazySingleton
class IncrementQuantitySeparateUseCase
    implements UseCase<void, IncrementQuantitySeparateParams> {
  final IPickingClusterRepository repository;

  IncrementQuantitySeparateUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(
      IncrementQuantitySeparateParams params) async {
    return await repository.incremenQtytProductSeparate(
      params.batchId,
      params.productId,
      params.idMove,
      params.quantity,
      params.type,
    );
  }
}

class IncrementQuantitySeparateParams {
  final int batchId;
  final int productId;
  final int idMove;
  final dynamic quantity;
  final String type;

  IncrementQuantitySeparateParams({
    required this.batchId,
    required this.productId,
    required this.idMove,
    required this.quantity,
    required this.type,
  });
}
