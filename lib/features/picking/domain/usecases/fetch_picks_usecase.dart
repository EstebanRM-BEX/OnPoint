import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/entities/pick_fetch_result.dart';
import 'package:wms_app/features/picking/domain/repositories/picking_repository.dart';

/// Use case for fetching active picks from the remote source.
@lazySingleton
class FetchPicksUseCase implements UseCase<PickFetchResult, NoParams> {
  final PickingRepository repository;

  FetchPicksUseCase(this.repository);

  @override
  Future<Either<Failure, PickFetchResult>> call(NoParams params) async {
    return await repository.fetchPicks();
  }
}
