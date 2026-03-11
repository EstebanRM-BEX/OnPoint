import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import '../repositories/picking_cluster_repository.dart';

@lazySingleton
class EndTimePickUseCase implements UseCase<void, EndTimePickParams> {
  final IPickingClusterRepository repository;

  EndTimePickUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(EndTimePickParams params) async {
    // 1. timePickingUser
    final userResult = await repository.timePickingUser(
      params.batchId,
      params.formattedDate,
      params.endpointUser,
      params.fieldUser,
      params.userid,
    );

    return userResult.fold(
      (failure) => left(failure),
      (userSuccess) async {
        // 2. timePickingBatch
        final batchResult = await repository.timePickingBatch(
          params.batchId,
          params.formattedDate,
          params.endpointBatch,
          params.fieldBatch,
          params.field2Batch,
        );

        return batchResult.fold(
          (failure) => left(failure),
          (batchSuccess) async {
            if (batchSuccess) {
              // 3. endStopwatchBatch
              final localResult = await repository.endStopwatchBatch(
                params.batchId,
                params.formattedDate,
                params.typePicking,
              );
              return localResult.fold(
                (failure) => left(failure),
                (_) => right(null),
              );
            } else {
              return left(
                  ServerFailure('Error al terminar el tiempo de separacion'));
            }
          },
        );
      },
    );
  }
}

class EndTimePickParams {
  final int batchId;
  final String formattedDate;
  final String typePicking;
  final int userid;
  final String endpointUser;
  final String fieldUser;
  final String endpointBatch;
  final String fieldBatch;
  final String field2Batch;

  EndTimePickParams({
    required this.batchId,
    required this.formattedDate,
    required this.typePicking,
    required this.userid,
    this.endpointUser = 'end_time_batch_user',
    this.fieldUser = 'end_time',
    this.endpointBatch = 'update_end_time',
    this.fieldBatch = 'end_time_pick',
    this.field2Batch = 'end_time',
  });
}
