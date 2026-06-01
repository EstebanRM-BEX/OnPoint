import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/repositories/pick_scan_repository.dart';

class MarkQuantityOkParams {
  final int batchId;
  final int productId;
  final int idMove;
  final bool isOk;

  const MarkQuantityOkParams({
    required this.batchId,
    required this.productId,
    required this.idMove,
    required this.isOk,
  });
}

@lazySingleton
class MarkQuantityOkUseCase implements UseCase<Unit, MarkQuantityOkParams> {
  final PickScanRepository repository;

  MarkQuantityOkUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(MarkQuantityOkParams params) =>
      repository.markQuantityOk(
          params.batchId, params.productId, params.idMove, params.isOk);
}
