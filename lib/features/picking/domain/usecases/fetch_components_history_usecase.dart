import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/entities/pick.dart';
import 'package:wms_app/features/picking/domain/repositories/picking_components_repository.dart';

class FetchComponentsHistoryParams {
  final String date;
  const FetchComponentsHistoryParams(this.date);
}

@lazySingleton
class FetchComponentsHistoryUseCase
    implements UseCase<List<Pick>, FetchComponentsHistoryParams> {
  final PickingComponentsRepository repository;

  FetchComponentsHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<Pick>>> call(
      FetchComponentsHistoryParams params) async {
    return await repository.fetchComponentsHistory(params.date);
  }
}
