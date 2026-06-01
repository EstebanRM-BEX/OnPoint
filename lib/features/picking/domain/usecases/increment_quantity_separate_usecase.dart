import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/repositories/pick_scan_repository.dart';

class IncrementQuantityParams {
  final int pickId;
  final int productId;
  final int idMove;
  final dynamic quantity;

  const IncrementQuantityParams({
    required this.pickId,
    required this.productId,
    required this.idMove,
    required this.quantity,
  });
}

@lazySingleton
class IncrementQuantitySeparateUseCase
    implements UseCase<Unit, IncrementQuantityParams> {
  final PickScanRepository repository;

  IncrementQuantitySeparateUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(IncrementQuantityParams params) =>
      repository.incrementQuantitySeparate(
          params.pickId, params.productId, params.idMove, params.quantity);
}
