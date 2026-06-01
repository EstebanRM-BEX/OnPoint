import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/repositories/pick_scan_repository.dart';

class ValidateTransferParams {
  final int pickId;
  final bool isBackOrder;

  const ValidateTransferParams({
    required this.pickId,
    required this.isBackOrder,
  });
}

@lazySingleton
class ValidateTransferUseCase
    implements UseCase<String, ValidateTransferParams> {
  final PickScanRepository repository;

  ValidateTransferUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(ValidateTransferParams params) =>
      repository.validateTransfer(params.pickId, params.isBackOrder);
}
