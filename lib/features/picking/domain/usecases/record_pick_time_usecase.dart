import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/repositories/pick_scan_repository.dart';

class RecordPickTimeParams {
  final int pickId;
  final String timeType;

  const RecordPickTimeParams({
    required this.pickId,
    required this.timeType,
  });
}

@lazySingleton
class RecordPickTimeUseCase implements UseCase<Unit, RecordPickTimeParams> {
  final PickScanRepository repository;

  RecordPickTimeUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(RecordPickTimeParams params) =>
      repository.recordPickTime(params.pickId, params.timeType);
}
