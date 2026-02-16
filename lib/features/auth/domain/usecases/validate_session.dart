import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/auth/domain/entities/session_validation_result.dart';
import 'package:wms_app/features/auth/domain/repositories/auth_repository.dart';

/// Use case para validar la sesión del usuario
@lazySingleton
class ValidateSession implements UseCase<SessionValidationResult, NoParams> {
  final AuthRepository repository;

  ValidateSession(this.repository);

  @override
  Future<Either<Failure, SessionValidationResult>> call(NoParams params) async {
    final sessionResult = await repository.getSession();

    return sessionResult.fold(
      (failure) => Left(failure),
      (session) async {
        // Usuario no está logueado
        if (!session.isLoggedIn) {
          return const Right(SessionValidationResult.notLoggedIn());
        }

        // Sesión expirada (más de 1 hora de inactividad)
        if (session.isExpired()) {
          await repository.clearSession();
          return const Right(SessionValidationResult.expired());
        }

        // Sesión válida - actualizar tiempo de actividad
        await repository.updateLastActiveTime();
        return const Right(SessionValidationResult.valid());
      },
    );
  }
}
