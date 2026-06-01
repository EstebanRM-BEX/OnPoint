import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/repositories/pick_scan_repository.dart';

class MarkPickAsDoneParams {
  final int pickId;

  const MarkPickAsDoneParams({required this.pickId});
}

@lazySingleton
class MarkPickAsDoneUseCase implements UseCase<Unit, MarkPickAsDoneParams> {
  final PickScanRepository repository;

  MarkPickAsDoneUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(MarkPickAsDoneParams params) =>
      repository.markPickAsDone(params.pickId);
}
