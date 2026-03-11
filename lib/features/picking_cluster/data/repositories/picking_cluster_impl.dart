import 'dart:developer';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import '../../domain/entities/batch_product.dart';
import '../../domain/entities/lote_producto.dart';
import '../../domain/entities/picking_batch.dart';
import '../../domain/repositories/picking_cluster_repository.dart';
import '../datasources/picking_cluster_local_data_source.dart';
import '../datasources/picking_remote_data_source.dart';

@LazySingleton(as: IPickingClusterRepository)
class PickingClusterRepositoryImpl implements IPickingClusterRepository {
  final PickingClusterRemoteDataSource remoteDataSource;
  final PickingClusterLocalDataSource localDataSource;

  PickingClusterRepositoryImpl(this.remoteDataSource, this.localDataSource);

  @override
  Future<Either<Failure, List<PickingBatch>>> getPickingBatches() async {
    try {
      final models = await remoteDataSource.getPickingBatches();
      final entities = models.map((model) => model.toEntity()).toList();

      // Cache the fetched batches transparently
      await localDataSource.cachePickingBatches(entities);

      return Right(entities);
    } catch (e, s) {
      log('❌ Error en getPickingBatches: $e',
          stackTrace: s, name: 'PickingClusterRepo');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LoteProducto>>> getLotesProducto(
      int productId) async {
    try {
      final models = await remoteDataSource.getLotesProducto(productId);
      final entities =
          models.map((model) => model.toLoteProductoEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LoteProducto>> crearLoteProducto(
      int productId, String name, String? expirationDate) async {
    try {
      final model = await remoteDataSource.crearLoteProducto(
          productId, name, expirationDate);
      return Right(model.toLoteProductoEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ─── Local ───────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<PickingBatch>>> getCachedPickingBatches() async {
    try {
      final cachedBatches = await localDataSource.getCachedPickingBatches();
      return Right(cachedBatches);
    } catch (e, s) {
      log('❌ Error en getCachedPickingBatches: $e',
          stackTrace: s, name: 'PickingClusterRepo');
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BatchProduct>>> getBatchProducts(
      int batchId) async {
    try {
      final products = await localDataSource.getBatchProducts(batchId);
      return Right(products);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setFieldTableBatchProducts(
      int batchId,
      int productId,
      String field,
      dynamic value,
      int idMove,
      String type) async {
    try {
      await localDataSource.setFieldTableBatchProducts(
          batchId, productId, field, value, idMove, type);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setFieldTableBatch(
      int batchId, String field, dynamic value, String type) async {
    try {
      await localDataSource.setFieldTableBatch(batchId, field, value, type);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BatchBarcode>>> getBarcodesProduct(
      int batchId, int productId, int idMove, String type) async {
    try {
      final barcodes = await localDataSource.getBarcodesProduct(
          batchId, productId, idMove, type);
      return Right(barcodes);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> incremenQtytProductSeparate(int batchId,
      int productId, int idMove, dynamic quantity, String type) async {
    try {
      await localDataSource.incremenQtytProductSeparate(
          batchId, productId, idMove, quantity, type);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> incrementProductSeparateQty(
      int batchId, String type) async {
    try {
      await localDataSource.incrementProductSeparateQty(batchId, type);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getFieldTableProducts(
      int batchId, int productId, int moveId, String field, String type) async {
    try {
      final result = await localDataSource.getFieldTableProducts(
          batchId, productId, moveId, field, type);
      return Right(result);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BatchProduct?>> getProductBatch(
      int batchId, int productId, int idMove, String type) async {
    try {
      final result = await localDataSource.getProductBatch(
          batchId, productId, idMove, type);
      return Right(result);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setFieldTableBatchPedidoValidate(
      int batchId, String namePedido, String field, dynamic value) async {
    try {
      await localDataSource.setFieldTableBatchPedidoValidate(
          batchId, namePedido, field, value);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> sendPickingProduct({
    required int idBatch,
    required double timeTotal,
    required int cantItemsSeparados,
    required List<Map<String, dynamic>> listItem,
    required String tipoPicking,
  }) async {
    try {
      final responseText = await remoteDataSource.sendPickingProduct(
        idBatch: idBatch,
        timeTotal: timeTotal,
        listItem: listItem,
        tipoPicking: tipoPicking,
      );
      return Right(responseText);
    } catch (e) {
      return Left(ServerFailure('Connection rejected'));
    }
  }

  @override
  Future<Either<Failure, String>> viewProductImage(
      int idProduct, bool isLoadinDialog) async {
    try {
      final url =
          await remoteDataSource.viewProductImage(idProduct, isLoadinDialog);
      return Right(url);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> timePickingUser(int batchId, String time,
      String endpoint, String field, int userid) async {
    try {
      final result = await remoteDataSource.timePickingUser(
          batchId, time, endpoint, field, userid);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> timePickingBatch(int batchId, String time,
      String endpoint, String field, String field2) async {
    try {
      final result = await remoteDataSource.timePickingBatch(
          batchId, time, endpoint, field, field2);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> endStopwatchBatch(
      int batchId, String time, String typePicking) async {
    try {
      await localDataSource.endStopwatchBatch(batchId, time, typePicking);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
