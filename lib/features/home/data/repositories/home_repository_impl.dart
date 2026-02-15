import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/features/home/data/datasources/home_local_data_source.dart';
import 'package:wms_app/features/home/data/datasources/home_remote_data_source.dart';
import 'package:wms_app/features/home/domain/entities/app_version.dart';
import 'package:wms_app/features/home/domain/entities/user_data.dart';
import 'package:wms_app/features/home/domain/repositories/home_repository.dart';
import 'package:wms_app/features/user/domain/entities/user_configuration.dart';

/// Implementation of HomeRepository interface.
/// Coordinates between remote and local data sources.
@LazySingleton(as: HomeRepository)
class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;
  final HomeLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  HomeRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, AppVersion>> getAppVersion() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No hay conexión a Internet'));
    }

    try {
      final version = await remoteDataSource.getAppVersion();
      return Right(version);
    } on SessionExpiredException catch (e) {
      return Left(SessionExpiredFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error desconocido: $e'));
    }
  }

  @override
  Future<Either<Failure, UserData>> getUserData() async {
    try {
      final userData = await localDataSource.getUserData();
      return Right(userData);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Error desconocido: $e'));
    }
  }

  @override
  Future<Either<Failure, UserConfiguration>> getUserConfigurations(
      int userId) async {
    try {
      final config = await localDataSource.getUserConfigurations(userId);
      return Right(config);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Error desconocido: $e'));
    }
  }
}
