// ignore_for_file: unrelated_type_equality_checks, avoid_print

import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/devoluciones/tbl_product/product_devolucion_table.dart';
import 'package:wms_app/src/presentation/views/devoluciones/models/product_devolucion_model.dart';
import 'dart:core';

class ProductDevolucionRepository {
  final DataBaseSqlite _databaseProvider;

  ProductDevolucionRepository(this._databaseProvider);

  // Tamaño del bloque para inserción masiva (Batching)
  static const int _batchSize = 500;

  /// --------------------------------------------------------------------------
  /// METODO OPTIMIZADO: insertProductosDevoluciones (Estrategia Mark & Sweep)
  /// --------------------------------------------------------------------------
  Future<void> insertProductosDevoluciones(
      List<ProductDevolucion> productosList) async {
    
    if (productosList.isEmpty) return;

    Stopwatch stopwatch = Stopwatch();
    stopwatch.start();

    try {
      Database db = await _databaseProvider.getDatabaseInstance();

      // Iniciamos una Transacción Exclusiva
      await db.transaction((txn) async {
        
        // PASO 1: MARCA (Resetear flag)
        // Marcamos todo lo existente como "no sincronizado" (0)
        await txn.rawUpdate(
          'UPDATE ${ProductDevolucionTable.tableName} SET ${ProductDevolucionTable.columnIsSynced} = 0'
        );

        // PASO 2: UPSERT POR LOTES (Chunking)
        for (var i = 0; i < productosList.length; i += _batchSize) {
          final end = (i + _batchSize < productosList.length)
              ? i + _batchSize
              : productosList.length;
          final batchList = productosList.sublist(i, end);

          Batch batch = txn.batch();

          for (var producto in batchList) {
            Map<String, dynamic> productoMap = {
              ProductDevolucionTable.columnProductCode:
                  producto.code == false ? "" : producto.code ?? '',
              ProductDevolucionTable.columnProductId: producto.productId,
              ProductDevolucionTable.columnProductName: producto.name ?? '',
              ProductDevolucionTable.columnBarcode:
                  producto.barcode == false ? "" : producto.barcode ?? '',
              ProductDevolucionTable.columnProductracking:
                  producto.tracking == false ? "none" : producto.tracking ?? '',
              ProductDevolucionTable.columnLotId:
                  producto.lotId == false ? 0 : producto.lotId ?? 0,
              ProductDevolucionTable.columnLotName:
                  producto.lotName == false ? "" : producto.lotName ?? '',
              ProductDevolucionTable.columnExpirationDate:
                  producto.expirationDate == false
                      ? ""
                      : producto.expirationDate ?? '',
              ProductDevolucionTable.columnWeight:
                  producto.weight == false ? 0 : producto.weight ?? 0,
              ProductDevolucionTable.columnWeightUomName:
                  producto.weightUomName == false
                      ? ""
                      : producto.weightUomName ?? '',
              ProductDevolucionTable.columnVolume:
                  producto.volume == false ? 0 : producto.volume ?? 0,
              ProductDevolucionTable.columnVolumeUomName:
                  producto.volumeUomName == false
                      ? ""
                      : producto.volumeUomName ?? '',
              ProductDevolucionTable.columnUom:
                  producto.uom == false ? "" : producto.uom ?? '',
              ProductDevolucionTable.columnLocationId:
                  producto.locationId == false ? 0 : producto.locationId ?? 0,
              ProductDevolucionTable.columnLocationName:
                  producto.locationName == false
                      ? ""
                      : producto.locationName ?? '',
              ProductDevolucionTable.columnQuantity:
                  producto.quantity == false ? 0.0 : producto.quantity ?? 0.0,
              ProductDevolucionTable.columnUseExpirationDate:
                  producto.useExpirationDate == false ? 0 : 1,
              
              // ✅ Marcamos este registro como sincronizado/válido
              ProductDevolucionTable.columnIsSynced: 1,
            };

            batch.insert(
              ProductDevolucionTable.tableName,
              productoMap,
              // ✅ UPSERT: Si existe (Prod + Lot), actualiza. Si no, inserta.
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          // Ejecutar el lote actual
          await batch.commit(noResult: true);
        }

        // PASO 3: BARRIDO (Limpiar basura)
        // Borramos los productos que ya no vienen del servidor (quedaron en 0)
        int deleted = await txn.delete(
          ProductDevolucionTable.tableName,
          where: '${ProductDevolucionTable.columnIsSynced} = ?',
          whereArgs: [0],
        );

        print("📦 Sync Devoluciones: Procesados ${productosList.length} | Eliminados Obsoletos: $deleted");
      });

      stopwatch.stop();
      print("Tiempo de inserción optimizada: ${stopwatch.elapsedMilliseconds} ms");

    } catch (e, s) {
      print("❌ Error en insertProductosDevoluciones: $e ==> $s");
    }
  }

  /// --------------------------------------------------------------------------
  /// METODOS INDIVIDUALES Y DE GESTIÓN
  /// --------------------------------------------------------------------------

  // Insertar un solo producto (Útil para actualizaciones manuales)
  Future<void> insertProductoDevolucion(ProductDevolucion producto) async {
    try {
      Database db = await _databaseProvider.getDatabaseInstance();

      Map<String, dynamic> productoMap = {
        ProductDevolucionTable.columnProductCode:
            producto.code == false ? "" : producto.code ?? '',
        ProductDevolucionTable.columnProductId: producto.productId,
        ProductDevolucionTable.columnProductName: producto.name ?? '',
        ProductDevolucionTable.columnBarcode:
            producto.barcode == false ? "" : producto.barcode ?? '',
        ProductDevolucionTable.columnProductracking:
            producto.tracking == false ? "none" : producto.tracking ?? '',
        ProductDevolucionTable.columnLotId:
            producto.lotId == false ? 0 : producto.lotId ?? 0,
        ProductDevolucionTable.columnLotName:
            producto.lotName == false ? "" : producto.lotName ?? '',
        ProductDevolucionTable.columnExpirationDate:
            producto.expirationDate == false
                ? ""
                : producto.expirationDate ?? '',
        ProductDevolucionTable.columnWeight:
            producto.weight == false ? 0 : producto.weight ?? 0,
        ProductDevolucionTable.columnWeightUomName:
            producto.weightUomName == false ? "" : producto.weightUomName ?? '',
        ProductDevolucionTable.columnVolume:
            producto.volume == false ? 0 : producto.volume ?? 0,
        ProductDevolucionTable.columnVolumeUomName:
            producto.volumeUomName == false ? "" : producto.volumeUomName ?? '',
        ProductDevolucionTable.columnUom:
            producto.uom == false ? "" : producto.uom ?? '',
        ProductDevolucionTable.columnLocationId:
            producto.locationId == false ? 0 : producto.locationId ?? 0,
        ProductDevolucionTable.columnLocationName:
            producto.locationName == false ? "" : producto.locationName ?? '',
        ProductDevolucionTable.columnQuantity:
            producto.quantity == false ? 0.0 : producto.quantity ?? 0.0,
        ProductDevolucionTable.columnUseExpirationDate:
            producto.useExpirationDate == false ? 0 : 1,
        
        // ✅ También marcamos como sincronizado en inserción individual
        ProductDevolucionTable.columnIsSynced: 1,
      };

      await db.insert(
        ProductDevolucionTable.tableName,
        productoMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print("✅ Producto insertado individualmente: ${producto.code}");
    } catch (e, s) {
      print("❌ Error en insertProductoDevolucion: $e ==> $s");
    }
  }

  // Eliminar un producto específico
  Future<void> deleteProductoDevolucion(int productId, int lotId) async {
    try {
      Database db = await _databaseProvider.getDatabaseInstance();
      await db.delete(
        ProductDevolucionTable.tableName,
        where:
            '${ProductDevolucionTable.columnProductId} = ? AND ${ProductDevolucionTable.columnLotId} = ?',
        whereArgs: [productId, lotId],
      );
    } catch (e, s) {
      print("Error al eliminar producto en deleteProductoDevolucion: $e ==> $s");
    }
  }

  // Eliminar TODOS los productos (Reset manual)
  Future<void> deleteAllProductosDevoluciones() async {
    try {
      Database db = await _databaseProvider.getDatabaseInstance();
      await db.delete(ProductDevolucionTable.tableName);
    } catch (e, s) {
      print("Error al eliminar todos los productos: $e ==> $s");
    }
  }

  // Obtener todos los productos
  Future<List<ProductDevolucion>> getAllProductosDevoluciones() async {
    try {
      Database db = await _databaseProvider.getDatabaseInstance();
      final List<Map<String, dynamic>> maps =
          await db.query(ProductDevolucionTable.tableName);

      return List.generate(maps.length, (i) {
        return ProductDevolucion.fromMap(maps[i]);
      });
    } catch (e, s) {
      print("Error al obtener todos los productos: $e ==> $s");
      return [];
    }
  }

  // Obtener un producto por ID
  Future<ProductDevolucion?> getProductoDevolucionById(int productId) async {
    try {
      Database db = await _databaseProvider.getDatabaseInstance();
      final List<Map<String, dynamic>> maps = await db.query(
        ProductDevolucionTable.tableName,
        where: '${ProductDevolucionTable.columnProductId} = ?',
        whereArgs: [productId],
        limit: 1, // Optimización pequeña
      );
      if (maps.isNotEmpty) {
        return ProductDevolucion.fromMap(maps.first);
      } else {
        return null; 
      }
    } catch (e, s) {
      print("Error al obtener producto por ID: $e ==> $s");
      return null;
    }
  }

  // Actualizar un producto (Update tradicional)
  Future<void> updateProductoDevolucion(ProductDevolucion producto) async {
    try {
      Database db = await _databaseProvider.getDatabaseInstance();

      Map<String, dynamic> productoMap = {
        ProductDevolucionTable.columnProductCode:
            producto.code == false ? "" : producto.code ?? '',
        ProductDevolucionTable.columnProductId: producto.productId,
        ProductDevolucionTable.columnProductName: producto.name ?? '',
        ProductDevolucionTable.columnBarcode:
            producto.barcode == false ? "" : producto.barcode ?? '',
        ProductDevolucionTable.columnProductracking:
            producto.tracking == false ? "none" : producto.tracking ?? '',
        ProductDevolucionTable.columnLotId:
            producto.lotId == false ? 0 : producto.lotId ?? 0,
        ProductDevolucionTable.columnLotName:
            producto.lotName == false ? "" : producto.lotName ?? '',
        ProductDevolucionTable.columnExpirationDate:
            producto.expirationDate == false
                ? ""
                : producto.expirationDate ?? '',
        ProductDevolucionTable.columnWeight:
            producto.weight == false ? 0 : producto.weight ?? 0,
        ProductDevolucionTable.columnWeightUomName:
            producto.weightUomName == false ? "" : producto.weightUomName ?? '',
        ProductDevolucionTable.columnVolume:
            producto.volume == false ? 0 : producto.volume ?? 0,
        ProductDevolucionTable.columnVolumeUomName:
            producto.volumeUomName == false ? "" : producto.volumeUomName ?? '',
        ProductDevolucionTable.columnUom:
            producto.uom == false ? "" : producto.uom ?? '',
        ProductDevolucionTable.columnLocationId:
            producto.locationId == false ? 0 : producto.locationId ?? 0,
        ProductDevolucionTable.columnLocationName:
            producto.locationName == false ? "" : producto.locationName ?? '',
        ProductDevolucionTable.columnQuantity:
            producto.quantity == false ? 0.0 : producto.quantity ?? 0.0,
        ProductDevolucionTable.columnUseExpirationDate:
            producto.useExpirationDate == false ? 0 : 1,
        // Al actualizar manualmente, asumimos que sigue sincronizado o lo marcamos
        ProductDevolucionTable.columnIsSynced: 1,
      };

      await db.update(
        ProductDevolucionTable.tableName,
        productoMap,
        where:
            '${ProductDevolucionTable.columnProductId} = ? AND ${ProductDevolucionTable.columnLotId} = ?',
        whereArgs: [producto.productId, producto.lotId],
      );

      print("✅ Producto actualizado: ${producto.code}");
    } catch (e, s) {
      print("❌ Error en updateProductoDevolucion: $e ==> $s");
    }
  }

  // Actualizar un campo específico (rawUpdate)
  Future<int?> setFieldTableProductDevolucion(
      int productId, String field, dynamic setValue, int lotId) async {
    try {
      Database db = await _databaseProvider.getDatabaseInstance();
      final resUpdate = await db.rawUpdate(
          'UPDATE ${ProductDevolucionTable.tableName} SET $field = ? '
          'WHERE ${ProductDevolucionTable.columnProductId} = ? '
          'AND ${ProductDevolucionTable.columnLotId} = ?',
          [setValue, productId, lotId]);
      
      print("Update Campo ($field) para Prod: $productId. Result: $resUpdate");
      return resUpdate;
    } catch (e, s) {
      print("❌ Error en setFieldTableProductDevolucion: $e ==> $s");
      return null;
    }
  }
}