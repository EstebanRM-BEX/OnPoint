import 'package:fpdart/fpdart.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/auth/domain/entities/session.dart';

/// Repositorio abstracto para operaciones de autenticación
abstract class AuthRepository {
  /// Obtiene la sesión actual del usuario
  Future<Either<Failure, Session>> getSession();

  /// Limpia la sesión del usuario
  Future<Either<Failure, void>> clearSession();

  /// Actualiza el tiempo de última actividad
  Future<Either<Failure, void>> updateLastActiveTime();
}
