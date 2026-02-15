import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_configuration.dart';
import '../repositories/user_repository.dart';

@lazySingleton
class GetUserConfiguration implements UseCase<UserConfiguration, NoParams> {
  final UserRepository repository;

  GetUserConfiguration(this.repository);

  @override
  Future<Either<Failure, UserConfiguration>> call(NoParams params) async {
    return await repository.getUserConfiguration();
  }
}
