import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/repositories/pick_scan_repository.dart';

class ValidateConfirmPickParams {
  final int pickId;
  final bool isBackOrder;

  const ValidateConfirmPickParams({
    required this.pickId,
    required this.isBackOrder,
  });
}

@lazySingleton
class ValidateConfirmPickUseCase
    implements UseCase<String, ValidateConfirmPickParams> {
  final PickScanRepository repository;

  ValidateConfirmPickUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(ValidateConfirmPickParams params) =>
      repository.validateConfirmPick(params.pickId, params.isBackOrder);
}
