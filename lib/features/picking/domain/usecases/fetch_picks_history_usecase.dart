import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/entities/pick.dart';
import 'package:wms_app/features/picking/domain/repositories/picking_repository.dart';

class FetchPicksHistoryParams {
  final String date;
  const FetchPicksHistoryParams({required this.date});
}

/// Use case for fetching picks history filtered by date.
@lazySingleton
class FetchPicksHistoryUseCase
    implements UseCase<List<Pick>, FetchPicksHistoryParams> {
  final PickingRepository repository;

  FetchPicksHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<Pick>>> call(
      FetchPicksHistoryParams params) async {
    return await repository.fetchPicksHistory(params.date);
  }
}
