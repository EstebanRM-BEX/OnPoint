// ignore_for_file: unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/product_inventario_table.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/models/update_product_request.dart';
import 'package:wms_app/src/presentation/views/inventario/models/response_products_model.dart';
import 'dart:core';

class ProductInventarioRepository {
  // Tamaño del bloque para inserción masiva
  static const int _batchSize = 500;

  /// --------------------------------------------------------------------------
  /// METODO OPTIMIZADO: insertProductosInventario (Mark & Sweep)
  /// --------------------------------------------------------------------------
  Future<void> insertProductosInventario(List<Product> productosList) async {
    if (productosList.isEmpty) return;

    Stopwatch stopwatch = Stopwatch();
    stopwatch.start();

    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      await db.transaction((txn) async {
        // PASO 1: MARCA (Resetear flag)
        // Marcamos todo el inventario actual como "no sincronizado"
        await txn.rawUpdate(
            'UPDATE ${ProductInventarioTable.tableName} SET ${ProductInventarioTable.columnIsSynced} = 0');

        // PASO 2: UPSERT POR LOTES (Chunking)
        for (var i = 0; i < productosList.length; i += _batchSize) {
          final end = (i + _batchSize < productosList.length)
              ? i + _batchSize
              : productosList.length;
          final batchList = productosList.sublist(i, end);

          Batch batch = txn.batch();

          for (var producto in batchList) {
            // Mapeo de datos con validaciones de seguridad
            Map<String, dynamic> productoMap = {
              ProductInventarioTable.columnProductCode:
                  producto.code == false ? "" : producto.code ?? '',
              ProductInventarioTable.columnProductId: producto.productId,
              ProductInventarioTable.columnProductName: producto.name ?? '',
              ProductInventarioTable.columnBarcode:
                  producto.barcode == false ? "" : producto.barcode ?? '',
              ProductInventarioTable.columnProductracking:
                  producto.tracking == false ? "none" : producto.tracking ?? '',
              ProductInventarioTable.columnLotId:
                  producto.lotId == false ? 0 : producto.lotId ?? 0,
              ProductInventarioTable.columnLotName:
                  producto.lotName == false ? "" : producto.lotName ?? '',
              ProductInventarioTable.columnExpirationDate:
                  producto.expirationDate == false
                      ? ""
                      : producto.expirationDate ?? '',
              ProductInventarioTable.columnWeight:
                  producto.weight == false ? 0 : producto.weight ?? 0,
              ProductInventarioTable.columnWeightUomName:
                  producto.weightUomName == false
                      ? ""
                      : producto.weightUomName ?? '',
              ProductInventarioTable.columnVolume:
                  producto.volume == false ? 0 : producto.volume ?? 0,
              ProductInventarioTable.columnVolumeUomName:
                  producto.volumeUomName == false
                      ? ""
                      : producto.volumeUomName ?? '',
              ProductInventarioTable.columnUom:
                  producto.uom == false ? "" : producto.uom ?? '',
              ProductInventarioTable.columnLocationId:
                  producto.locationId == false ? 0 : producto.locationId ?? 0,
              ProductInventarioTable.columnLocationName:
                  producto.locationName == false
                      ? ""
                      : producto.locationName ?? '',
              ProductInventarioTable.columnQuantity:
                  producto.quantity == false ? 0.0 : producto.quantity ?? 0.0,
              ProductInventarioTable.columnUseExpirationDate:
                  producto.useExpirationDate == true ? 1 : 0,
              ProductInventarioTable.columnCategory:
                  producto.category == false ? "" : producto.category ?? '',

              // ✅ Marcamos como sincronizado
              ProductInventarioTable.columnIsSynced: 1,
            };

            batch.insert(
              ProductInventarioTable.tableName,
              productoMap,
              // ✅ UPSERT: Si existe (Prod+Lot+Loc), actualiza. Si no, inserta.
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);
        }

        // PASO 3: BARRIDO (Limpiar basura)
        // Borramos los productos/stock que ya no vienen del servidor
        int deleted = await txn.delete(
          ProductInventarioTable.tableName,
          where: '${ProductInventarioTable.columnIsSynced} = ?',
          whereArgs: [0],
        );

        stopwatch.stop();
        debugPrint(
            "📦 Sync Productos Inventario: Procesados ${productosList.length} | Eliminados Obsoletos: $deleted | Tiempo: ${stopwatch.elapsedMilliseconds} ms");
      });
    } catch (e, s) {
      debugPrint("❌ Error al insertar productos en inventario: $e ==> $s");
    }
  }

  // --------------------------------------------------------------------------
  // MÉTODOS DE LECTURA (Optimizados por Índices)
  // --------------------------------------------------------------------------

  Future<List<Product>> getAllProducts() async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      // Si la lista es gigante, considera poner un LIMIT aqui
      List<Map<String, dynamic>> maps =
          await db.query(ProductInventarioTable.tableName);

      if (maps.isNotEmpty) {
        return maps.map((m) => Product.fromMap(m)).toList();
      } else {
        return [];
      }
    } catch (e, s) {
      debugPrint("Error al obtener productos: $e ==> $s");
      return [];
    }
  }

  Future<List<Product>> getAllUniqueProducts() async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();

      // Consulta optimizada para agrupar por productId
      // Gracias al índice en product_id, el GROUP BY es más rápido.
      final maps = await db.rawQuery('''
        SELECT * FROM ${ProductInventarioTable.tableName}
        GROUP BY ${ProductInventarioTable.columnProductId}
      ''');

      return maps.map((map) => Product.fromMap(map)).toList();
    } catch (e, s) {
      debugPrint("Error al obtener productos únicos por ID: $e ==> $s");
      return [];
    }
  }

  Future<Product?> getProductById(int productId) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      // Esta consulta ahora es INSTANTÁNEA gracias al índice idx_inv_product_id
      List<Map<String, dynamic>> maps = await db.query(
          ProductInventarioTable.tableName,
          where: '${ProductInventarioTable.columnProductId} = ?',
          whereArgs: [productId],
          limit: 1 // Optimización
          );

      if (maps.isNotEmpty) {
        return Product.fromMap(maps.first);
      } else {
        return null;
      }
    } catch (e, s) {
      debugPrint("Error al obtener producto por id: $e ==> $s");
      return null;
    }
  }

  Future<void> updateProduct(UpdateProductRequest product) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      await db.update(
        ProductInventarioTable.tableName,
        {
          ProductInventarioTable.columnProductName: product.name,
          ProductInventarioTable.columnBarcode: product.barcode,
          ProductInventarioTable.columnProductCode: product.defaultCode,
          ProductInventarioTable.columnWeight: product.weight,
          ProductInventarioTable.columnVolume: product.volume,
          // Aseguramos que se mantenga como sincronizado al editar manualmente
          ProductInventarioTable.columnIsSynced: 1,
        },
        where: '${ProductInventarioTable.columnProductId} = ?',
        whereArgs: [product.productId],
      );
      debugPrint("Producto actualizado correctamente: ${product.productId}");
    } catch (e, s) {
      debugPrint("Error al actualizar producto: $e ==> $s");
    }
  }
}
