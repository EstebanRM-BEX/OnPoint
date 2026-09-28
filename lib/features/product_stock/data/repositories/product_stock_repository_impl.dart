import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/network/network_guard.dart';

import '../../domain/entities/product_stock_info.dart';
import '../../domain/repositories/product_stock_repository.dart';
import '../datasources/product_stock_remote_data_source.dart';

@LazySingleton(as: ProductStockRepository)
class ProductStockRepositoryImpl implements ProductStockRepository {
  final ProductStockRemoteDataSource remoteDataSource;

  ProductStockRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, ProductStockInfo>> getProductStockInfo(
      int productId) async {
    if (!await hasNetwork()) {
      return const Left(NetworkFailure('Sin conexión a Internet'));
    }
    try {
      return Right(await remoteDataSource.getProductStockInfo(productId));
    } on SessionExpiredException catch (e) {
      return Left(SessionExpiredFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException catch (e) {
      return Left(NetworkFailure('Error de red: ${e.message}'));
    } catch (e, s) {
      debugPrint('❌ getProductStockInfo: $e\n$s');
      return Left(ServerFailure('Error al consultar el stock: $e'));
    }
  }
}
