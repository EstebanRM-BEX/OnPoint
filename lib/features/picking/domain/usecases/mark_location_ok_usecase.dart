import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/repositories/pick_scan_repository.dart';

class MarkLocationOkParams {
  final int batchId;
  final int productId;
  final int idMove;

  const MarkLocationOkParams({
    required this.batchId,
    required this.productId,
    required this.idMove,
  });
}

@lazySingleton
class MarkLocationOkUseCase implements UseCase<Unit, MarkLocationOkParams> {
  final PickScanRepository repository;

  MarkLocationOkUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(MarkLocationOkParams params) =>
      repository.markLocationOk(params.batchId, params.productId, params.idMove);
}
