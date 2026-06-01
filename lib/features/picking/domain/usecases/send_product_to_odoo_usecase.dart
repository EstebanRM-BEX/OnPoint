import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/entities/scan_send_result.dart';
import 'package:wms_app/features/picking/domain/repositories/pick_scan_repository.dart';

class SendProductParams {
  final int pickId;
  final int productId;
  final int idMove;
  final int currentBatchId;

  const SendProductParams({
    required this.pickId,
    required this.productId,
    required this.idMove,
    required this.currentBatchId,
  });
}

@lazySingleton
class SendProductToOdooUseCase
    implements UseCase<ScanSendResult, SendProductParams> {
  final PickScanRepository repository;

  SendProductToOdooUseCase(this.repository);

  @override
  Future<Either<Failure, ScanSendResult>> call(SendProductParams params) =>
      repository.sendProductToOdoo(
          params.pickId, params.productId, params.idMove, params.currentBatchId);
}
