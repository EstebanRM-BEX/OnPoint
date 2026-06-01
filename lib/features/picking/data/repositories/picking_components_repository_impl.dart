import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/features/picking/data/datasources/picking_components_local_data_source.dart';
import 'package:wms_app/features/picking/data/datasources/picking_components_remote_data_source.dart';
import 'package:wms_app/features/picking/data/models/pick_model.dart';
import 'package:wms_app/features/picking/domain/entities/pick.dart';
import 'package:wms_app/features/picking/domain/entities/pick_fetch_result.dart';
import 'package:wms_app/features/picking/domain/repositories/picking_components_repository.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/response_pick_model.dart';

/// Implementation of [PickingComponentsRepository].
/// Coordinates between remote and local data sources.
@LazySingleton(as: PickingComponentsRepository)
class PickingComponentsRepositoryImpl implements PickingComponentsRepository {
  final PickingComponentsRemoteDataSource remoteDataSource;
  final PickingComponentsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  PickingComponentsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  // ── fetchComponents ────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, PickFetchResult>> fetchComponents() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No hay conexión a Internet'));
    }

    try {
      final result = await remoteDataSource.fetchComponents();
      final needsUpdate = result.updateVersion ?? false;
      final rawPicks = result.result ?? [];

      if (rawPicks.isNotEmpty) {
        await localDataSource.saveComponentsToDb(rawPicks);

        final products = _extractAllProducts(rawPicks).toList();
        final sentProducts = _getAllSentProducts(rawPicks).toList();
        final barcodes = _extractAllBarcodes(rawPicks).toList();

        await localDataSource.insertComponentProducts(products);
        await localDataSource.insertComponentProducts(sentProducts);

        if (barcodes.isNotEmpty) {
          await localDataSource.insertComponentBarcodes(barcodes);
        }
      }

      final localPicks = await localDataSource.getComponentsFromDb();
      final picks =
          localPicks.map((r) => PickModel.fromResultPick(r)).toList();

      return Right(PickFetchResult(picks: picks, needsUpdate: needsUpdate));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al obtener componentes: $e'));
    }
  }

  // ── fetchComponentsFromDb ──────────────────────────────────────────────────
  @override
  Future<Either<Failure, List<Pick>>> fetchComponentsFromDb() async {
    try {
      final rawPicks = await localDataSource.getComponentsFromDb();
      final picks =
          rawPicks.map((r) => PickModel.fromResultPick(r)).toList();
      return Right(picks);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Error al leer componentes locales: $e'));
    }
  }

  // ── fetchComponentsHistory ─────────────────────────────────────────────────
  @override
  Future<Either<Failure, List<Pick>>> fetchComponentsHistory(
      String date) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No hay conexión a Internet'));
    }

    try {
      final rawPicks = await remoteDataSource.fetchComponentsHistory(date);
      final picks =
          rawPicks.map((r) => PickModel.fromResultPick(r)).toList();
      return Right(picks);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al obtener historial de componentes: $e'));
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Iterable<ProductsBatch> _extractAllProducts(List<ResultPick> picks) sync* {
    for (final pick in picks) {
      if (pick.lineasTransferencia != null) yield* pick.lineasTransferencia!;
    }
  }

  Iterable<ProductsBatch> _getAllSentProducts(List<ResultPick> picks) sync* {
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
