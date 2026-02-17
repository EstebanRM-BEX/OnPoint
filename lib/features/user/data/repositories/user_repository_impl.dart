import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/device_info.dart';
import '../../domain/entities/user_configuration.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_local_data_source.dart';
import '../datasources/user_remote_data_source.dart';
import '../models/device_info_model.dart';

@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final UserLocalDataSource localDataSource;

  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, UserConfiguration>> getUserConfiguration() async {
    if (await _isConnected()) {
      try {
        final remoteConfig = await remoteDataSource.getUserConfiguration();
        await localDataSource.cacheUserConfiguration(remoteConfig);
        return Right(remoteConfig);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      try {
        final localConfig = await localDataSource.getCachedUserConfiguration();
        if (localConfig != null) {
          return Right(localConfig);
        } else {
          return const Left(CacheFailure('No cached configuration found'));
        }
      } catch (e) {
        return Left(CacheFailure(e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, DeviceInfo>> getDeviceInfo() async {
    try {
      final deviceInfo = await DeviceInfoModel.fromPlatform();
      return Right(deviceInfo);
    } catch (e) {
      return Left(PlatformFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserLocation>>> getUserLocations() async {
    if (await _isConnected()) {
      try {
        final remoteLocations = await remoteDataSource.getUserLocations();
        await localDataSource.cacheUserLocations(remoteLocations);
        return Right(remoteLocations);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> registerDevice(String deviceId,
      String deviceName, String deviceModel, String versionApp) async {
    if (await _isConnected()) {
      try {
        await remoteDataSource.registerDevice(
            deviceId, deviceName, deviceModel, versionApp);
        print('✅ Dispositivo registrado correctamente');
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  Future<bool> _isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
