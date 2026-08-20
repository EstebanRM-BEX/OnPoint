import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wms_app/core/network/connectivity_extensions.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/device_info.dart';
import '../../domain/entities/device_registration.dart';
import '../../domain/entities/user_configuration.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/entities/user_novelty.dart';
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
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        // Falla la petición remota aunque _isConnected() dio positivo (server
        // caído, DNS intermitente, timeout): en vez de mostrar la excepción
        // cruda (p.ej. "ClientException"), caemos a la config guardada si
        // existe.
        final localConfig = await localDataSource.getCachedUserConfiguration();
        if (localConfig != null) return Right(localConfig);
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
  Future<Either<Failure, List<Novedad>>> getNovelties() async {
    if (await _isConnected()) {
      try {
        final remoteNovelties = await remoteDataSource.getNovelties();
        await localDataSource.cacheUserNovelties(remoteNovelties);
        return Right(remoteNovelties);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      try {
        final localNovelties = await localDataSource.getCachedUserNovelties();
        if (localNovelties != null) {
          return Right(localNovelties);
        } else {
          return const Left(CacheFailure('No cached novelties found'));
        }
      } catch (e) {
        return Left(CacheFailure(e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, DeviceRegistration>> registerDevice(String deviceId,
      String deviceName, String deviceModel, String versionApp) async {
    if (await _isConnected()) {
      try {
        final result = await remoteDataSource.registerDevice(
            deviceId, deviceName, deviceModel, versionApp);
        debugPrint('✅ Dispositivo registrado correctamente');
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  // connectivity_plus solo reporta si hay una interfaz de red activa (WiFi/
  // datos), no si esa red llega realmente a internet. Con WiFi sin salida a
  // internet o servidor inalcanzable, checkConnectivity() daba falso positivo
  // y la petición remota terminaba lanzando una excepción cruda al usuario.
  // Verificamos con una resolución DNS real, igual que NetworkInfoImpl.
  Future<bool> _isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.isOffline) return false;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    }
  }
}
