import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/features/login/data/datasources/login_local_data_source.dart';
import 'package:wms_app/features/login/data/datasources/login_remote_data_source.dart';
import 'package:wms_app/features/login/domain/entities/user.dart';
import 'package:wms_app/features/login/domain/repositories/login_repository.dart';

/// Implementation of LoginRepository.
/// Coordinates between remote and local data sources and converts exceptions to failures.
@LazySingleton(as: LoginRepository)
class LoginRepositoryImpl implements LoginRepository {
  final LoginRemoteDataSource remoteDataSource;
  final LoginLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  LoginRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> authenticate({
    required String email,
    required String password,
    required String database,
  }) async {
    // Check network connectivity
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final user = await remoteDataSource.authenticate(
        email: email,
        password: password,
        database: database,
      );
      return Right(user);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveUserSession({
    required User user,
    required String password,
  }) async {
    try {
      await localDataSource.saveUserSession(
        user: user,
        password: password,
      );
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Error al guardar sesión: $e'));
    }
  }
}
