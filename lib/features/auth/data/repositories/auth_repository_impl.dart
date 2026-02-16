import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:wms_app/features/auth/domain/entities/session.dart';
import 'package:wms_app/features/auth/domain/repositories/auth_repository.dart';

/// Implementación del repositorio de autenticación
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, Session>> getSession() async {
    try {
      final session = await localDataSource.getSession();
      return Right(session);
    } catch (e) {
      return Left(CacheFailure('Error al obtener sesión: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearSession() async {
    try {
      await localDataSource.clearSession();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error al limpiar sesión: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateLastActiveTime() async {
    try {
      await localDataSource.updateLastActiveTime();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error al actualizar tiempo de actividad: $e'));
    }
  }
}
