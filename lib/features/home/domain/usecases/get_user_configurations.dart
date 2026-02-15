import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/home/domain/repositories/home_repository.dart';
import 'package:wms_app/features/user/domain/entities/user_configuration.dart';

/// Use case for getting user configurations from local database.
///
/// Takes a user ID as parameter and returns the user's configurations.
@lazySingleton
class GetUserConfigurations implements UseCase<UserConfiguration, int> {
  final HomeRepository repository;

  GetUserConfigurations(this.repository);

  @override
  Future<Either<Failure, UserConfiguration>> call(int userId) async {
    return await repository.getUserConfigurations(userId);
  }
}
