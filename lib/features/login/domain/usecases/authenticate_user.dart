import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/login/domain/entities/user.dart';
import 'package:wms_app/features/login/domain/repositories/login_repository.dart';

/// Use case for authenticating a user.
///
/// This use case handles the business logic of user authentication,
/// delegating the actual implementation to the repository.
@lazySingleton
class AuthenticateUser implements UseCase<User, AuthenticateParams> {
  final LoginRepository repository;

  AuthenticateUser(this.repository);

  @override
  Future<Either<Failure, User>> call(AuthenticateParams params) async {
    return await repository.authenticate(
      email: params.email,
      password: params.password,
      database: params.database,
    );
  }
}

/// Parameters for authentication
class AuthenticateParams {
  final String email;
  final String password;
  final String database;

  const AuthenticateParams({
    required this.email,
    required this.password,
    required this.database,
  });
}
