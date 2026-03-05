import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import '../repositories/picking_cluster_repository.dart';

@lazySingleton
class IncrementProductSeparateQtyUseCase
    implements UseCase<void, IncrementProductSeparateQtyParams> {
  final IPickingClusterRepository repository;

  IncrementProductSeparateQtyUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(
      IncrementProductSeparateQtyParams params) async {
    return await repository.incrementProductSeparateQty(
      params.batchId,
      params.type,
    );
  }
}

class IncrementProductSeparateQtyParams {
  final int batchId;
  final String type;

  IncrementProductSeparateQtyParams({
    required this.batchId,
    required this.type,
  });
}
