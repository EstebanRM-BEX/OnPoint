import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/repositories/picking_repository.dart';

class RecordTimeParams {
  final int pickId;
  final String timeType;
  const RecordTimeParams({required this.pickId, required this.timeType});
}

/// Use case for recording start or end time of a pick.
@lazySingleton
class StartStopTimePickUseCase implements UseCase<Unit, RecordTimeParams> {
  final PickingRepository repository;

  StartStopTimePickUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(RecordTimeParams params) async {
    return await repository.recordPickTime(params.pickId, params.timeType);
  }
}
