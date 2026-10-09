// lib/features/inventario/data/datasources/inventario_local_data_source.dart

import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/core/services/barcodes_inventario_cache_service.dart';
import 'package:wms_app/core/services/configuracion_cache_service.dart';
import 'package:wms_app/core/services/productos_cache_service.dart';
import 'package:wms_app/core/services/ubicaciones_cache_service.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/features/inventario/data/models/barcode_producto_model.dart';
import 'package:wms_app/features/inventario/data/models/producto_inventario_model.dart';
import 'package:wms_app/features/inventario/data/models/ubicacion_inventario_model.dart';
import 'package:wms_app/features/user/domain/entities/user_configuration.dart';
import 'package:wms_app/core/services/interfaces/i_storage_service.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_barcode/barcodes_inventario_table.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/product_inventario_table.dart';

// ─── Interfaz ────────────────────────────────────────────────────────────────

abstract class InventarioLocalDataSource {
  Future<void> deleteInventario();

  /// Reemplaza el catálogo (productos + barcodes) en UNA transacción: si algo
  /// falla, queda el catálogo anterior intacto.
  Future<void> reemplazarCatalogo(
    List<ProductoInventarioModel> productos,
    List<BarcodeProductoModel> barcodes,
  );

  /// Aplica una sincronización incremental en UNA transacción: reemplaza los
  /// productos de [productos] (llegan completos, con todas sus filas), borra
  /// [eliminados] y, si viene [activos], todo lo que no esté en esa lista.
  Future<void> aplicarCambiosCatalogo({
    required List<ProductoInventarioModel> productos,
    required List<BarcodeProductoModel> barcodes,
    required List<int> eliminados,
    List<int>? activos,
  });

  /// `since`/`scope` de la última sincronización exitosa (null = no hay).
  Future<({String since, String scope})?> marcaSyncCatalogo();

  Future<void> guardarMarcaSyncCatalogo(String since, String scope);

  Future<void> borrarMarcaSyncCatalogo();

  /// Empresa (URL + BD) de la sesión actual.
  Future<String> empresaActual();

  /// Empresa a la que pertenece el catálogo local (null = desconocida).
  Future<String?> empresaCatalogo();

  Future<void> guardarEmpresaCatalogo(String empresa);

  Future<List<ProductoInventarioModel>> getProductos();

  Future<int> getProductosCount();

  Future<List<UbicacionInventarioModel>> getUbicaciones();

  Future<List<BarcodeProductoModel>> getBarcodesProducto(int productId);

  Future<List<BarcodeProductoModel>> getAllBarcodes();

  Future<UserConfiguration> getConfiguracion();
}

// ─── Implementación ──────────────────────────────────────────────────────────

@LazySingleton(as: InventarioLocalDataSource)
class InventarioLocalDataSourceImpl implements InventarioLocalDataSource {
  final DataBaseSqlite database;

  InventarioLocalDataSourceImpl(this.database);

  @override
  Future<void> deleteInventario() async {
    try {
      await database.deleInventario();
    } catch (e) {
      throw CacheException('Error al limpiar inventario local: $e');
    }
  }

  @override
  Future<void> reemplazarCatalogo(
    List<ProductoInventarioModel> productos,
    List<BarcodeProductoModel> barcodes,
  ) async {
    try {
      final inserts = [
        ...await database.productoInventarioRepository.construirInserts(
          productos.map((p) => p.toLegacy()).toList(),
        ),
        ...database.barcodesInventarioRepository.construirInserts(
          barcodes.map((b) => b.toLegacy()).toList(),
        ),
      ];

      final db = await database.getDatabaseInstance();
      await db.rawQuery('PRAGMA synchronous = OFF;');
      try {
        await db.transaction((txn) async {
          await txn.delete(ProductInventarioTable.tableName);
          await txn.delete(BarcodesInventarioTable.tableName);
          final batch = txn.batch();
          for (final q in inserts) {
            batch.rawInsert(q['sql'] as String, q['args'] as List<dynamic>);
          }
          await batch.commit(noResult: true);
        });
      } finally {
        await db.rawQuery('PRAGMA synchronous = NORMAL;');
      }

      // El sync recién escribió barcodes frescos en SQLite — invalida el
      // cache compartido para que CreateTransferBloc/DevolucionesBloc/etc.
      // tomen el dato nuevo en vez de una copia vieja en memoria.
      getIt<BarcodesInventarioCacheService>().invalidate();
    } catch (e) {
      throw CacheException('Error al guardar productos en local: $e');
    }
  }

  /// SQLite admite 999 variables por sentencia en las versiones viejas.
  static const _tanda = 500;

  @override
  Future<void> aplicarCambiosCatalogo({
    required List<ProductoInventarioModel> productos,
    required List<BarcodeProductoModel> barcodes,
    required List<int> eliminados,
    List<int>? activos,
  }) async {
    try {
      final inserts = [
        ...await database.productoInventarioRepository.construirInserts(
          productos.map((p) => p.toLegacy()).toList(),
        ),
        ...database.barcodesInventarioRepository.construirInserts(
          barcodes.map((b) => b.toLegacy()).toList(),
        ),
      ];
      final aBorrar = {
        for (final p in productos)
          if (p.productId is num) (p.productId as num).toInt(),
        ...eliminados,
      }.toList();

      const prod = ProductInventarioTable.tableName;
      const prodId = ProductInventarioTable.columnProductId;
      const bc = BarcodesInventarioTable.tableName;
      const bcId = BarcodesInventarioTable.columnIdProduct;

      final db = await database.getDatabaseInstance();
      await db.transaction((txn) async {
        for (var i = 0; i < aBorrar.length; i += _tanda) {
          final ids = aBorrar.sublist(i, min(i + _tanda, aBorrar.length));
          final marcas = List.filled(ids.length, '?').join(',');
          await txn.delete(prod, where: '$prodId IN ($marcas)', whereArgs: ids);
          await txn.delete(bc, where: '$bcId IN ($marcas)', whereArgs: ids);
        }

        final batch = txn.batch();
        for (final q in inserts) {
          batch.rawInsert(q['sql'] as String, q['args'] as List<dynamic>);
        }
        await batch.commit(noResult: true);

        if (activos != null) {
          // Un NOT IN con ~74 mil parámetros no entra: tabla temporal.
          await txn.execute(
            'CREATE TEMP TABLE IF NOT EXISTS tmp_productos_activos '
            '(id INTEGER PRIMARY KEY)',
          );
          await txn.delete('tmp_productos_activos');
          for (var i = 0; i < activos.length; i += _tanda) {
            final ids = activos.sublist(i, min(i + _tanda, activos.length));
            await txn.rawInsert(
              'INSERT OR IGNORE INTO tmp_productos_activos (id) VALUES '
              '${List.filled(ids.length, '(?)').join(',')}',
              ids,
            );
          }
          await txn.rawDelete(
            'DELETE FROM $prod WHERE $prodId NOT IN '
            '(SELECT id FROM tmp_productos_activos)',
          );
          await txn.rawDelete(
            'DELETE FROM $bc WHERE $bcId NOT IN '
            '(SELECT id FROM tmp_productos_activos)',
          );
          await txn.execute('DROP TABLE IF EXISTS tmp_productos_activos');
        }
      });

      getIt<BarcodesInventarioCacheService>().invalidate();
    } catch (e) {
      throw CacheException('Error al actualizar productos en local: $e');
    }
  }

  @override
  Future<({String since, String scope})?> marcaSyncCatalogo() =>
      PrefUtils.getCatalogSync();

  @override
  Future<void> guardarMarcaSyncCatalogo(String since, String scope) =>
      PrefUtils.setCatalogSync(since, scope);

  @override
  Future<void> borrarMarcaSyncCatalogo() => PrefUtils.clearCatalogSync();

  @override
  Future<String> empresaActual() async =>
      '${await PrefUtils.getEnterprise()}|${getIt<IStorageService>().nameDatabase}';

  @override
  Future<String?> empresaCatalogo() => PrefUtils.getCatalogEnterprise();

  @override
  Future<void> guardarEmpresaCatalogo(String empresa) =>
      PrefUtils.setCatalogEnterprise(empresa);

  @override
  Future<List<ProductoInventarioModel>> getProductos() async {
    try {
      // retain:false — el bloc de inventario guarda su propio modelo; no dejar
      // además 72 mil `Product` retenidos en el caché compartido.
      final legacyList = await getIt<ProductosCacheService>().getAll(
        retain: false,
      );
      return legacyList
          .map(ProductoInventarioModel.fromLegacy)
          .toList();
    } catch (e) {
      throw CacheException('Error al obtener productos locales: $e');
    }
  }

  @override
  Future<int> getProductosCount() async {
    try {
      return await database.getProductCount();
    } catch (e) {
      throw CacheException('Error al obtener conteo de productos: $e');
    }
  }

  @override
  Future<List<UbicacionInventarioModel>> getUbicaciones() async {
    try {
      final legacyList = await getIt<UbicacionesCacheService>().getAll();
      return legacyList
          .map(UbicacionInventarioModel.fromLegacy)
          .toList();
    } catch (e) {
      throw CacheException('Error al obtener ubicaciones: $e');
    }
  }

  @override
  Future<List<BarcodeProductoModel>> getBarcodesProducto(
      int productId) async {
    try {
      final legacyList = await database.barcodesInventarioRepository
          .getBarcodesProduct(productId);
      return legacyList
          .map(BarcodeProductoModel.fromLegacy)
          .toList();
    } catch (e) {
      throw CacheException('Error al obtener barcodes del producto: $e');
    }
  }

  @override
  Future<List<BarcodeProductoModel>> getAllBarcodes() async {
    try {
      final legacyList = await getIt<BarcodesInventarioCacheService>().getAll();
      return legacyList
          .map(BarcodeProductoModel.fromLegacy)
          .toList();
    } catch (e) {
      throw CacheException('Error al obtener todos los barcodes: $e');
    }
  }

  @override
  Future<UserConfiguration> getConfiguracion() async {
    try {
      final userId = await PrefUtils.getUserId();
      final config =
          await getIt<ConfiguracionCacheService>().getConfiguration(userId);
      if (config == null) {
        throw const CacheException(
            'No se encontraron configuraciones del usuario');
      }
      return config;
    } on CacheException {
      rethrow;
    } catch (e) {
      throw CacheException('Error al obtener configuraciones: $e');
    }
  }
}
