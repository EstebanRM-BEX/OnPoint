import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/repositories/pick_scan_repository.dart';

class MarkProductOkParams {
  final int batchId;
  final int productId;
  final int idMove;

  const MarkProductOkParams({
    required this.batchId,
    required this.productId,
    required this.idMove,
  });
}

@lazySingleton
class MarkProductOkUseCase implements UseCase<Unit, MarkProductOkParams> {
  final PickScanRepository repository;

  MarkProductOkUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(MarkProductOkParams params) =>
      repository.markProductOk(
          params.batchId, params.productId, params.idMove);
}
