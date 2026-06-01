import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/repositories/picking_repository.dart';
import 'package:wms_app/features/user/data/models/user_configuration_model.dart';

/// Use case for retrieving user configurations for picking.
@lazySingleton
class GetPickConfigurationsUseCase
    implements UseCase<UserConfigurationModel, NoParams> {
  final PickingRepository repository;

  GetPickConfigurationsUseCase(this.repository);

  @override
  Future<Either<Failure, UserConfigurationModel>> call(NoParams params) async {
    return await repository.getPickConfigurations();
  }
}
