// lib/features/inventario/data/repositories/inventario_repository_impl.dart

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/features/inventario/data/datasources/inventario_local_data_source.dart';
import 'package:wms_app/features/inventario/data/datasources/inventario_remote_data_source.dart';
import 'package:wms_app/features/inventario/domain/entities/barcode_producto.dart';
import 'package:wms_app/features/inventario/domain/entities/lote_producto_inventario.dart';
import 'package:wms_app/features/inventario/domain/entities/producto_inventario.dart';
import 'package:wms_app/features/inventario/domain/entities/resultado_crear_lote.dart';
import 'package:wms_app/features/inventario/domain/entities/resultado_envio_inventario.dart';
import 'package:wms_app/features/inventario/domain/entities/ubicacion_inventario.dart';
import 'package:wms_app/features/inventario/domain/repositories/inventario_repository.dart';
import 'package:wms_app/features/user/domain/entities/user_configuration.dart';

@LazySingleton(as: InventarioRepository)
class InventarioRepositoryImpl implements InventarioRepository {
  final InventarioRemoteDataSource remoteDataSource;
  final InventarioLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  InventarioRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  // ─── Sync (borra local + fetch remoto en paralelo) ─────────────────────────

  @override
  Future<Either<Failure, void>> syncProductosInventario(
    bool isLoadingDialog, {
    void Function(String phase, int processed, int total)? onProgress,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No hay conexión a Internet'));
    }

    try {
      onProgress?.call('Descargando productos de WMS...', 0, 0);

      // Future.wait propaga la excepción original sin envolverla en
      // ParallelWaitError (a diferencia del record .wait de Dart 3).
      final results = await Future.wait([
        localDataSource.deleteInventario(),
        remoteDataSource.syncProductos(),
      ]);
      final syncResult = results[1] as ProductosSyncResult;

      final total = syncResult.productos.length;
      onProgress?.call('Guardando $total productos en base de datos...', 0, total);

      await localDataSource.saveProductosYBarcodes(
        syncResult.productos,
        syncResult.barcodes,
      );

      onProgress?.call('Sincronización completada', total, total);
      return const Right(null);
    } on SessionExpiredException catch (e) {
      return Left(SessionExpiredFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al sincronizar productos: $e'));
    }
  }

  // ─── Local ──────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<ProductoInventario>>> getProductosLocal() async {
    try {
      final productos = await localDataSource.getProductos();
      return Right(productos.cast<ProductoInventario>());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Error al leer productos locales: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getProductosCount() async {
    try {
      final count = await localDataSource.getProductosCount();
      return Right(count);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Error al obtener conteo: $e'));
    }
  }

  @override
  Future<Either<Failure, List<UbicacionInventario>>>
      getUbicacionesLocal() async {
    try {
      final ubicaciones = await localDataSource.getUbicaciones();
      return Right(ubicaciones.cast<UbicacionInventario>());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Error al leer ubicaciones: $e'));
    }
  }

  @override
  Future<Either<Failure, List<BarcodeProducto>>> getBarcodesProducto(
      int productId) async {
    try {
      final barcodes = await localDataSource.getBarcodesProducto(productId);
      return Right(barcodes.cast<BarcodeProducto>());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Error al leer barcodes: $e'));
    }
  }

  @override
  Future<Either<Failure, List<BarcodeProducto>>>
      getAllBarcodesInventario() async {
    try {
      final barcodes = await localDataSource.getAllBarcodes();
      return Right(barcodes.cast<BarcodeProducto>());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Error al leer todos los barcodes: $e'));
    }
  }

  @override
  Future<Either<Failure, UserConfiguration>>
      getConfiguracionUsuarioInventario() async {
    try {
      final config = await localDataSource.getConfiguracion();
      return Right(config);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Error al obtener configuraciones: $e'));
    }
  }

  // ─── Remote ─────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<LoteProductoInventario>>> getLotesProducto(
      int productId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No hay conexión a Internet'));
    }

    try {
      final lotes = await remoteDataSource.getLotes(productId);
      return Right(lotes.cast<LoteProductoInventario>());
    } on SessionExpiredException catch (e) {
      return Left(SessionExpiredFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al obtener lotes: $e'));
    }
  }

  @override
  Future<Either<Failure, ResultadoEnvioInventario>> enviarProductoInventario({
    required dynamic locationId,
    required dynamic productId,
    required dynamic lotId,
    required dynamic quantity,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No hay conexión a Internet'));
    }

    try {
      final resultado = await remoteDataSource.enviarProducto(
        locationId: locationId,
        productId: productId,
        lotId: lotId,
        quantity: quantity,
      );
      return Right(resultado);
    } on SessionExpiredException catch (e) {
      return Left(SessionExpiredFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al enviar producto: $e'));
    }
  }

  @override
  Future<Either<Failure, ResultadoCrearLote>> crearLoteInventario({
    required int productId,
    required String nameLote,
    required String fechaCaducidad,
    required bool priorityExpiration,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No hay conexión a Internet'));
    }

    try {
      final resultado = await remoteDataSource.crearLote(
        productId: productId,
        nameLote: nameLote,
        fechaCaducidad: fechaCaducidad,
        priorityExpiration: priorityExpiration,
      );
      return Right(resultado);
    } on SessionExpiredException catch (e) {
      return Left(SessionExpiredFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al crear lote: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> getUrlImagenProducto(int productId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No hay conexión a Internet'));
    }

    try {
      final url = await remoteDataSource.getUrlImagenProducto(productId);
      return Right(url);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al obtener imagen: $e'));
    }
  }
}
