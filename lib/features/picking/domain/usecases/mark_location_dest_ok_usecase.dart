import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/repositories/pick_scan_repository.dart';

class MarkLocationDestOkParams {
  final int batchId;
  final int productId;
  final int idMove;
  final bool isOk;

  const MarkLocationDestOkParams({
    required this.batchId,
    required this.productId,
    required this.idMove,
    required this.isOk,
  });
}

@lazySingleton
class MarkLocationDestOkUseCase
    implements UseCase<Unit, MarkLocationDestOkParams> {
  final PickScanRepository repository;

  MarkLocationDestOkUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(MarkLocationDestOkParams params) =>
      repository.markLocationDestOk(
          params.batchId, params.productId, params.idMove, params.isOk);
}
