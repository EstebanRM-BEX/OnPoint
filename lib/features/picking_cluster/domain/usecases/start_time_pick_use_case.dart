import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import '../repositories/picking_cluster_repository.dart';

@lazySingleton
class StartTimePickUseCase implements UseCase<void, StartTimePickParams> {
  final IPickingClusterRepository repository;

  StartTimePickUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(StartTimePickParams params) async {
    // 1. timePickingUser
    final userResult = await repository.timePickingUser(params.batchId,
        params.formattedDate, params.endpointUser, params.fieldUser);

    return userResult.fold(
      (failure) => left(failure),
      (successUser) async {
        if (!successUser) {
          return left(ServerFailure('Failed timePickingUser API call'));
        }

        // 2. timePickingBatch
        final batchResult = await repository.timePickingBatch(
          params.batchId,
          params.formattedDate,
          params.endpointBatch,
          params.fieldBatch,
          params.fieldBatch2,
        );

        return batchResult.fold(
          (failure) => left(failure),
          (successBatch) async {
            if (!successBatch) {
              return left(ServerFailure('Failed timePickingBatch API call'));
            }

            // 3. startStopwatchBatch
            final localResult = await repository.startStopwatchBatch(
              params.batchId,
              params.formattedDate,
              params.typePicking,
            );

            return localResult.fold(
              (failure) => left(failure),
              (_) => right(null),
            );
          },
        );
      },
    );
  }
}

class StartTimePickParams {
  final int batchId;
  final String formattedDate;
  final String typePicking;
  final String endpointUser;
  final String fieldUser;
  final String endpointBatch;
  final String fieldBatch;
  final String fieldBatch2;

  StartTimePickParams({
    required this.batchId,
    required this.formattedDate,
    required this.typePicking,
    this.endpointUser = 'start_time_batch_user',
    this.fieldUser = 'start_time',
    this.endpointBatch = 'update_start_time',
    this.fieldBatch = 'start_time_pick',
    this.fieldBatch2 = 'start_time',
  });
}
