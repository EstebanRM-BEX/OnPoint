// lib/features/inventario/data/datasources/inventario_local_data_source.dart

import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
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
    } catch (e) {
      throw CacheException('Error al guardar productos en local: $e');
    }
  }

  @override
  Future<List<ProductoInventarioModel>> getProductos() async {
    try {
      final legacyList =
          await database.productoInventarioRepository.getAllProducts();
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
      final legacyList =
          await database.ubicacionesRepository.getAllUbicaciones();
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
      final legacyList =
          await database.barcodesInventarioRepository.getAllBarcodes();
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
          await database.configurationsRepository.getConfiguration(userId);
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
