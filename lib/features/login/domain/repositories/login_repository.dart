import 'package:fpdart/fpdart.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/login/domain/entities/user.dart';

/// Repository interface for login operations.
/// This defines the contract that the data layer must implement.
abstract class LoginRepository {
  /// Authenticate user with email and password
  Future<Either<Failure, User>> authenticate({
    required String email,
    required String password,
    required String database,
  });

  /// Save user session data (encrypted password)
  Future<Either<Failure, void>> saveUserSession({
    required User user,
    required String password,
  });
}
