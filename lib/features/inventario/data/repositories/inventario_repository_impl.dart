// lib/features/inventario/data/repositories/inventario_repository_impl.dart

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/core/utils/performance/catalogo_sync_trace.dart';
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

  // ─── Sync (descarga y reemplaza el catálogo de una vez) ─────────────────────

  @override
  Future<Either<Failure, void>> syncProductosInventario(
    bool isLoadingDialog, {
    void Function(String phase, int processed, int total)? onProgress,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No hay conexión a Internet'));
    }

    final trace = CatalogoSyncTrace.iniciar();
    var resultado = 'error';
    try {
      // El catálogo sobrevive al cierre de sesión: si es de otra empresa (o
      // no se sabe de cuál, p. ej. tras actualizar la app) se borra antes de
      // descargar, para no operar con productos ajenos si la descarga falla.
      String? motivoLocal;
      final empresa = await localDataSource.empresaActual();
      if (await localDataSource.empresaCatalogo() != empresa) {
        await localDataSource.deleteInventario();
        await localDataSource.borrarMarcaSyncCatalogo();
        motivoLocal = 'empresa_distinta';
      }

      // Incremental solo si hay marca y catálogo local al que aplicarla.
      var marca = await localDataSource.marcaSyncCatalogo();
      if (marca == null) {
        motivoLocal ??= 'sin_marca';
      } else if (await localDataSource.getProductosCount() == 0) {
        marca = null;
        motivoLocal ??= 'catalogo_vacio';
      }

      onProgress?.call(
        marca == null
            ? 'Descargando productos de WMS...'
            : 'Actualizando productos de WMS...',
        0,
        0,
      );

      // Antes se borraba el catálogo en paralelo con la descarga: si la red
      // fallaba, la PDA quedaba sin productos. Ahora se escribe solo con la
      // respuesta en la mano.
      final syncResult = await remoteDataSource.syncProductos(
        since: marca?.since,
        scope: marca?.scope,
      );
      final msDescarga = trace.tramo('ms_descarga');

      final total = syncResult.productos.length;
      final tipo = syncResult.full ? 'completa' : 'incremental';
      final motivo = syncResult.full
          ? motivoDescargaCompleta(
              motivoLocal: marca == null ? motivoLocal : null,
              scopeEnviado: marca?.scope,
              serverTime: syncResult.serverTime,
              scopeRecibido: syncResult.scope,
            )
          : 'incremental';
      debugPrint(
        '📦 [Catálogo] $tipo ($motivo) · since=${marca?.since ?? '-'} · '
        '$total filas, ${syncResult.deletedProductIds.length} eliminados, '
        '${syncResult.activeProductIds?.length ?? '-'} activos · '
        'descarga ${msDescarga}ms',
      );
      trace
        ..atributo('tipo', tipo)
        ..atributo('motivo', motivo)
        ..metrica('filas', total)
        ..metrica('barcodes', syncResult.barcodes.length)
        ..metrica('eliminados', syncResult.deletedProductIds.length);

      if (syncResult.full) {
        if (total == 0) {
          resultado = 'sin_productos';
          return const Left(ServerFailure('El servidor no devolvió productos'));
        }
        onProgress?.call(
          'Guardando $total productos en base de datos...',
          0,
          total,
        );
        await localDataSource.reemplazarCatalogo(
          syncResult.productos,
          syncResult.barcodes,
        );
      } else {
        onProgress?.call(
          'Actualizando $total productos en base de datos...',
          0,
          total,
        );
        await localDataSource.aplicarCambiosCatalogo(
          productos: syncResult.productos,
          barcodes: syncResult.barcodes,
          eliminados: syncResult.deletedProductIds,
          activos: syncResult.activeProductIds,
        );
      }
      await localDataSource.guardarEmpresaCatalogo(empresa);

      // La marca se guarda solo con todo aplicado; sin server_time (backend
      // anterior) no hay marca y la próxima vez se pide completo.
      final serverTime = syncResult.serverTime;
      final scope = syncResult.scope;
      if (serverTime != null && scope != null) {
        await localDataSource.guardarMarcaSyncCatalogo(serverTime, scope);
      } else {
        await localDataSource.borrarMarcaSyncCatalogo();
      }
      final msGuardado = trace.tramo('ms_guardado');
      debugPrint(
        '📦 [Catálogo] guardado en ${msGuardado}ms · '
        'próximo since=${serverTime ?? '-'} scope=${scope ?? '-'}',
      );

      onProgress?.call('Sincronización completada', total, total);
      resultado = 'ok';
      return const Right(null);
    } on SessionExpiredException catch (e) {
      resultado = 'sesion_expirada';
      return Left(SessionExpiredFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al sincronizar productos: $e'));
    } finally {
      trace.terminar(resultado);
    }
  }

  // ─── Local ──────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<ProductoInventario>>> buscarProductos({
    required String query,
    int? ubicacionId,
    required int limit,
    required int offset,
  }) async {
    try {
      final productos = await localDataSource.buscarProductos(
        query: query,
        ubicacionId: ubicacionId,
        limit: limit,
        offset: offset,
      );
      return Right(productos.cast<ProductoInventario>());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Error al buscar productos: $e'));
    }
  }

  @override
  Future<Either<Failure, ProductoInventario?>> buscarProductoPorCodigo(
    String codigo,
  ) async {
    try {
      return Right(await localDataSource.buscarProductoPorCodigo(codigo));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Error al buscar el producto: $e'));
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
    int productId,
  ) async {
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
    int productId,
  ) async {
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
