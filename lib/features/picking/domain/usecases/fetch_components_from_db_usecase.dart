import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/entities/pick.dart';
import 'package:wms_app/features/picking/domain/repositories/picking_components_repository.dart';

@lazySingleton
class FetchComponentsFromDbUseCase implements UseCase<List<Pick>, NoParams> {
  final PickingComponentsRepository repository;

  FetchComponentsFromDbUseCase(this.repository);

  @override
  Future<Either<Failure, List<Pick>>> call(NoParams params) async {
    return await repository.fetchComponentsFromDb();
  }
}
