import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/features/picking/data/datasources/picking_local_data_source.dart';
import 'package:wms_app/features/picking/data/datasources/picking_remote_data_source.dart';
import 'package:wms_app/features/picking/data/models/pick_model.dart';
import 'package:wms_app/features/picking/domain/entities/pick.dart';
import 'package:wms_app/features/picking/domain/entities/pick_fetch_result.dart';
import 'package:wms_app/features/picking/domain/repositories/picking_repository.dart';
import 'package:wms_app/features/user/data/models/user_configuration_model.dart';
import 'package:wms_app/src/presentation/views/transferencias/data/transferencias_repository.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/PickhWithProducts_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/response_pick_model.dart';

/// Implementation of [PickingRepository].
/// Coordinates between remote and local data sources.
@LazySingleton(as: PickingRepository)
class PickingRepositoryImpl implements PickingRepository {
  final PickingRemoteDataSource remoteDataSource;
  final PickingLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final TransferenciasRepository transferRepository;

  PickingRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.transferRepository,
  });

  // ── fetchPicks ─────────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, PickFetchResult>> fetchPicks() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No hay conexión a Internet'));
    }

    try {
      await localDataSource.clearPicks();

      final result = await remoteDataSource.fetchPicks();
      final needsUpdate = result.updateVersion ?? false;
      final rawPicks = result.result ?? [];

      if (rawPicks.isNotEmpty) {
        await localDataSource.savePicksToDb(rawPicks);

        final products = _extractAllProducts(rawPicks).toList();
        final sentProducts = _getAllSentProducts(rawPicks).toList();
        final barcodes = _extractAllBarcodes(rawPicks).toList();

        await localDataSource.insertPickProducts(products);
        await localDataSource.insertPickProducts(sentProducts);

        if (barcodes.isNotEmpty) {
          await localDataSource.insertBarcodes(barcodes);
        }
      }

      final localPicks = await localDataSource.getPicksFromDb();
      final picks =
          localPicks.map((r) => PickModel.fromResultPick(r)).toList();

      return Right(PickFetchResult(picks: picks, needsUpdate: needsUpdate));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al obtener picks: $e'));
    }
  }

  // ── fetchPicksHistory ──────────────────────────────────────────────────────
  @override
  Future<Either<Failure, List<Pick>>> fetchPicksHistory(String date) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No hay conexión a Internet'));
    }

    try {
      final rawPicks = await remoteDataSource.fetchPicksHistory(date);
      final picks =
          rawPicks.map((r) => PickModel.fromResultPick(r)).toList();
      return Right(picks);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al obtener historial: $e'));
    }
  }

  // ── assignUserToPick ───────────────────────────────────────────────────────
  @override
  Future<Either<Failure, Unit>> assignUserToPick(int pickId) async {
    try {
      final userId = await PrefUtils.getUserId();
      final userName = await PrefUtils.getUserName();

      final ok = await transferRepository.assignUserToTransfer(
        false,
        userId,
        pickId,
      );

      if (!ok) {
        return const Left(
            ServerFailure('La transferencia ya tiene un responsable asignado'));
      }

      await localDataSource.assignUserLocally(pickId, userId, userName);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al asignar usuario: $e'));
    }
  }

  // ── recordPickTime ─────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, Unit>> recordPickTime(
      int pickId, String timeType) async {
    try {
      final time =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      await localDataSource.recordTimeLocally(pickId, timeType, time);

      await transferRepository.sendTime(
        pickId,
        timeType,
        time,
        false,
      );

      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al registrar tiempo: $e'));
    }
  }

  // ── getPickWithProducts ────────────────────────────────────────────────────
  @override
  Future<Either<Failure, PickWithProducts>> getPickWithProducts(
      int pickId) async {
    try {
      final result = await localDataSource.getPickWithProducts(pickId);
      if (result != null) {
        return Right(result);
      }
      return const Left(CacheFailure('No se encontraron productos para el pick'));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Error al obtener productos del pick: $e'));
    }
  }

  // ── getPickConfigurations ──────────────────────────────────────────────────
  @override
  Future<Either<Failure, UserConfigurationModel>> getPickConfigurations() async {
    try {
      final userId = await PrefUtils.getUserId();
      final result = await localDataSource.getConfigurations(userId);
      if (result != null) {
        return Right(result);
      }
      return const Left(CacheFailure('No se encontraron configuraciones'));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Error al obtener configuraciones: $e'));
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Iterable<ProductsBatch> _extractAllProducts(
      List<ResultPick> picks) sync* {
    for (final pick in picks) {
      if (pick.lineasTransferencia != null) {
        yield* pick.lineasTransferencia!;
      }
    }
  }

  Iterable<ProductsBatch> _getAllSentProducts(
      List<ResultPick> picks) sync* {
    for (final pick in picks) {
      if (pick.lineasTransferenciaEnviadas != null) {
        yield* pick.lineasTransferenciaEnviadas!;
      }
    }
  }

  Iterable<Barcodes> _extractAllBarcodes(List<ResultPick> picks) sync* {
    for (final pick in picks) {
      if (pick.lineasTransferencia == null) continue;
      for (final product in pick.lineasTransferencia!) {
        if (product.productPacking != null) yield* product.productPacking!;
        if (product.otherBarcode != null) yield* product.otherBarcode!;
      }
    }
  }
}
