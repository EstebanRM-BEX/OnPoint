import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/features/recepcion_multiusuario/data/datasources/recepcion_multiusuario_local_data_source.dart';
import 'package:wms_app/features/recepcion_multiusuario/data/datasources/recepcion_multiusuario_remote_data_source.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/lote_producto.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_claim.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_pool_item.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/repositories/recepcion_multiusuario_repository.dart';

@LazySingleton(as: RecepcionMultiusuarioRepository)
class RecepcionMultiusuarioRepositoryImpl
    implements RecepcionMultiusuarioRepository {
  final RecepcionMultiusuarioRemoteDataSource remoteDataSource;
  final RecepcionMultiusuarioLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  RecepcionMultiusuarioRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<RecepcionSession>>> fetchSessions({
    required bool isLoadinDialog,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No hay conexión a Internet'));
    }

    try {
      final sessions = await remoteDataSource.fetchSessions(
        isLoadinDialog: isLoadinDialog,
      );

      // No hay mutaciones locales pendientes de sincronizar en esta fase
      // (fase 1 es solo lectura), así que el fetch reemplaza la foto
      // completa: se borra y se vuelve a insertar lo que manda el backend.
      await localDataSource.limpiarSessions();
      if (sessions.isNotEmpty) {
        await localDataSource.saveSessions(sessions);
      }

      final localSessions = await localDataSource.getSessionsFromDb();
      return Right(localSessions);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al obtener las recepciones: $e'));
    }
  }

  @override
  Future<Either<Failure, List<RecepcionSession>>> getSessionsFromDb() async {
    try {
      final localSessions = await localDataSource.getSessionsFromDb();
      return Right(localSessions);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Error al leer las recepciones locales: $e'));
    }
  }

  @override
  Future<Either<Failure, List<RecepcionPoolItem>>> fetchPool({
    required int sessionId,
    required bool isLoadinDialog,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No hay conexión a Internet'));
    }

    try {
      final items = await remoteDataSource.fetchPool(
        sessionId: sessionId,
        isLoadinDialog: isLoadinDialog,
      );

      // savePool ya borra y reinserta el pool de la sesión en una sola
      // transacción: lo que no vino en esta respuesta ya no está libre.
      await localDataSource.savePool(sessionId, items);

      final localItems = await localDataSource.getPoolFromDb(sessionId);
      return Right(localItems);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al obtener el pool de la sesión: $e'));
    }
  }

  @override
  Future<Either<Failure, List<RecepcionPoolItem>>> getPoolFromDb(
    int sessionId,
  ) async {
    try {
      final localItems = await localDataSource.getPoolFromDb(sessionId);
      return Right(localItems);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Error al leer el pool local: $e'));
    }
  }

  @override
  Future<Either<Failure, RecepcionClaim>> claimProduct({
    required int sessionId,
    required int productId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No hay conexión a Internet'));
    }

    try {
      final claim = await remoteDataSource.claimProduct(
        sessionId: sessionId,
        productId: productId,
      );
      return Right(claim);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al reclamar el producto: $e'));
    }
  }

  @override
  Future<Either<Failure, List<RecepcionClaim>>> fetchMyClaims({
    required int sessionId,
    required bool isLoadinDialog,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No hay conexión a Internet'));
    }

    try {
      final claims = await remoteDataSource.fetchMyClaims(
        sessionId: sessionId,
        isLoadinDialog: isLoadinDialog,
      );
      return Right(claims);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
        ServerFailure('Error al obtener mis productos asignados: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> releaseClaim({required int claimId}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No hay conexión a Internet'));
    }

    try {
      await remoteDataSource.releaseClaim(claimId: claimId);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al liberar la asignación: $e'));
    }
  }

  @override
  Future<Either<Failure, List<LoteProducto>>> fetchLotesProduct({
    required int productId,
    required bool isLoadinDialog,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No hay conexión a Internet'));
    }

    try {
      final lotes = await remoteDataSource.fetchLotesProduct(
        productId: productId,
        isLoadinDialog: isLoadinDialog,
      );
      return Right(lotes);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al obtener los lotes del producto: $e'));
    }
  }

  @override
  Future<Either<Failure, LoteProducto>> createLote({
    required int productId,
    required String nombreLote,
    required String fechaVencimiento,
    required bool priorityExpiration,
    required bool isLoadinDialog,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No hay conexión a Internet'));
    }

    try {
      final lote = await remoteDataSource.createLote(
        productId: productId,
        nombreLote: nombreLote,
        fechaVencimiento: fechaVencimiento,
        priorityExpiration: priorityExpiration,
        isLoadinDialog: isLoadinDialog,
      );
      return Right(lote);
    } on ConfirmationRequiredException catch (e) {
      return Left(ConfirmationRequiredFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al crear el lote: $e'));
    }
  }

  @override
  Future<Either<Failure, RecepcionClaim>> finishClaim({
    required int claimId,
    required double qtyDone,
    required int lotId,
    required int ubicacionDestino,
    required int timeLine,
    required String observation,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No hay conexión a Internet'));
    }

    try {
      final claim = await remoteDataSource.finishClaim(
        claimId: claimId,
        qtyDone: qtyDone,
        lotId: lotId,
        ubicacionDestino: ubicacionDestino,
        timeLine: timeLine,
        observation: observation,
      );
      return Right(claim);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al confirmar la recepción: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> undoClaim({
    required int claimId,
    required String observacion,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No hay conexión a Internet'));
    }

    try {
      await remoteDataSource.undoClaim(
        claimId: claimId,
        observacion: observacion,
      );
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al deshacer la recepción: $e'));
    }
  }
}
