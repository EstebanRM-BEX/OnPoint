import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/core/utils/performance/catalogo_sync_trace.dart';
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
  final NetworkInfo networkInfo;

  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
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

  /// Sync de ubicaciones: incremental (`since`/`scope`) si hay marca y
  /// ubicaciones locales, completo si no. Devuelve la lista COMPLETA leída de
  /// SQLite: con el incremental la respuesta trae solo lo cambiado.
  @override
  Future<Either<Failure, List<UserLocation>>> getUserLocations() async {
    if (!await _isConnected()) {
      return const Left(NetworkFailure('No internet connection'));
    }

    final trace = CatalogoSyncTrace.iniciar('ubicaciones_sync');
    var resultado = 'error';
    try {
      // Sobreviven al cierre de sesión: si son de otra empresa (o no se sabe
      // de cuál, p. ej. tras actualizar la app) se borran antes de descargar.
      String? motivoLocal;
      final empresa = await localDataSource.empresaActual();
      if (await localDataSource.empresaUbicaciones() != empresa) {
        await localDataSource.borrarUbicaciones();
        await localDataSource.borrarMarcaSyncUbicaciones();
        motivoLocal = 'empresa_distinta';
      }

      var marca = await localDataSource.marcaSyncUbicaciones();
      if (marca == null) {
        motivoLocal ??= 'sin_marca';
      } else if (await localDataSource.contarUbicaciones() == 0) {
        marca = null;
        motivoLocal ??= 'catalogo_vacio';
      }

      final r = await remoteDataSource.getUserLocations(
        since: marca?.since,
        scope: marca?.scope,
      );
      final msDescarga = trace.tramo('ms_descarga');

      final tipo = r.full ? 'completa' : 'incremental';
      final motivo = r.full
          ? motivoDescargaCompleta(
              motivoLocal: marca == null ? motivoLocal : null,
              scopeEnviado: marca?.scope,
              serverTime: r.serverTime,
              scopeRecibido: r.scope,
            )
          : 'incremental';
      debugPrint(
        '📍 [Ubicaciones] $tipo ($motivo) · since=${marca?.since ?? '-'} · '
        '${r.ubicaciones.length} filas, ${r.activos?.length ?? '-'} activas · '
        'descarga ${msDescarga}ms',
      );
      trace
        ..atributo('tipo', tipo)
        ..atributo('motivo', motivo)
        ..metrica('filas', r.ubicaciones.length);

      if (r.full) {
        if (r.ubicaciones.isEmpty) {
          resultado = 'sin_productos';
          return const Left(
            ServerFailure('El servidor no devolvió ubicaciones'),
          );
        }
        await localDataSource.cacheUserLocations(r.ubicaciones);
      } else {
        await localDataSource.aplicarCambiosUbicaciones(r.ubicaciones, r.activos);
      }
      await localDataSource.guardarEmpresaUbicaciones(empresa);

      // La marca se guarda solo con todo aplicado; sin server_time (servidor
      // anterior) no hay marca y la próxima vez se pide completo.
      final serverTime = r.serverTime;
      final scope = r.scope;
      if (serverTime != null && scope != null) {
        await localDataSource.guardarMarcaSyncUbicaciones(serverTime, scope);
      } else {
        await localDataSource.borrarMarcaSyncUbicaciones();
      }
      final msGuardado = trace.tramo('ms_guardado');
      debugPrint(
        '📍 [Ubicaciones] guardado en ${msGuardado}ms · '
        'próximo since=${serverTime ?? '-'} scope=${scope ?? '-'}',
      );

      final locales = await localDataSource.getUbicacionesLocales();
      resultado = 'ok';
      return Right(locales);
    } on SessionExpiredException catch (e) {
      resultado = 'sesion_expirada';
      return Left(SessionExpiredFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    } finally {
      trace.terminar(resultado);
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

  Future<bool> _isConnected() => networkInfo.isConnected;
}
