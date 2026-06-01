import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/repositories/pick_scan_repository.dart';

class UpdateQuantityParams {
  final int pickId;
  final int productId;
  final int idMove;
  final dynamic quantity;

  const UpdateQuantityParams({
    required this.pickId,
    required this.productId,
    required this.idMove,
    required this.quantity,
  });
}

@lazySingleton
class UpdateQuantitySeparateUseCase
    implements UseCase<Unit, UpdateQuantityParams> {
  final PickScanRepository repository;

  UpdateQuantitySeparateUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(UpdateQuantityParams params) =>
      repository.updateQuantitySeparate(
          params.pickId, params.productId, params.idMove, params.quantity);
}
