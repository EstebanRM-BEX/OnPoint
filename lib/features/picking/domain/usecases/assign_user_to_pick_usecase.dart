import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/repositories/picking_repository.dart';

class AssignUserParams {
  final int pickId;
  const AssignUserParams({required this.pickId});
}

/// Use case for assigning the current user to a pick.
@lazySingleton
class AssignUserToPickUseCase implements UseCase<Unit, AssignUserParams> {
  final PickingRepository repository;

  AssignUserToPickUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(AssignUserParams params) async {
    return await repository.assignUserToPick(params.pickId);
  }
}
