// lib/features/inventario/data/datasources/inventario_local_data_source.dart

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
import 'package:wms_app/src/presentation/providers/db/database.dart';

// ─── Interfaz ────────────────────────────────────────────────────────────────

abstract class InventarioLocalDataSource {
  Future<void> deleteInventario();

  Future<void> saveProductosYBarcodes(
    List<ProductoInventarioModel> productos,
    List<BarcodeProductoModel> barcodes,
  );

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
  Future<void> saveProductosYBarcodes(
    List<ProductoInventarioModel> productos,
    List<BarcodeProductoModel> barcodes,
  ) async {
    try {
      // Réplica del Future.wait paralelo del legacy (~líneas 567-570).
      await Future.wait([
        database.productoInventarioRepository.insertProductosInventario(
          productos.map((p) => p.toLegacy()).toList(),
        ),
        database.barcodesInventarioRepository.insertOrUpdateBarcodes(
          barcodes.map((b) => b.toLegacy()).toList(),
        ),
      ]);
      // El sync recién escribió barcodes frescos en SQLite — invalida el
      // cache compartido para que CreateTransferBloc/DevolucionesBloc/etc.
      // tomen el dato nuevo en vez de una copia vieja en memoria.
      getIt<BarcodesInventarioCacheService>().invalidate();
    } catch (e) {
      throw CacheException('Error al guardar productos en local: $e');
    }
  }

  @override
  Future<List<ProductoInventarioModel>> getProductos() async {
    try {
      final legacyList = await getIt<ProductosCacheService>().getAll();
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
