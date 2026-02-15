import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/login/domain/entities/user.dart';
import 'package:wms_app/features/login/domain/repositories/login_repository.dart';

/// Use case for saving user session data.
///
/// This use case handles saving user information and encrypted password
/// to local storage for session management.
@lazySingleton
class SaveUserSession implements UseCase<void, SaveSessionParams> {
  final LoginRepository repository;

  SaveUserSession(this.repository);

  @override
  Future<Either<Failure, void>> call(SaveSessionParams params) async {
    return await repository.saveUserSession(
      user: params.user,
      password: params.password,
    );
  }
}

/// Parameters for saving session
class SaveSessionParams {
  final User user;
  final String password;

  const SaveSessionParams({
    required this.user,
    required this.password,
  });
}
