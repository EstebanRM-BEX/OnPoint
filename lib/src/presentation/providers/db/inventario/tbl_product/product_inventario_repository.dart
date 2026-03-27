// ignore_for_file: unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/product_inventario_table.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/models/update_product_request.dart';
import 'package:wms_app/src/presentation/views/inventario/models/response_products_model.dart';
import 'dart:core';

class ProductInventarioRepository {
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
        // ✅ TÉCNICA DEFINITIVA (Raw SQL Multi-Insert):
        // En vez de enviar 62,000 "Maps", unimos 40 filas por cada `INSERT INTO` (usando 19 params * 40 = 760 vinculaciones),
        const int itemsPerQuery = 40;
        final Batch batch = txn.batch();

        for (var i = 0; i < productosList.length; i += itemsPerQuery) {
          final end = (i + itemsPerQuery < productosList.length)
              ? i + itemsPerQuery
              : productosList.length;
          final chunk = productosList.sublist(i, end);

          final StringBuffer queryBuffer = StringBuffer();
          queryBuffer.write('INSERT INTO ${ProductInventarioTable.tableName} (');
          queryBuffer.write('${ProductInventarioTable.columnProductCode}, ${ProductInventarioTable.columnProductId}, ${ProductInventarioTable.columnProductName}, ');
          queryBuffer.write('${ProductInventarioTable.columnBarcode}, ${ProductInventarioTable.columnProductracking}, ${ProductInventarioTable.columnLotId}, ');
          queryBuffer.write('${ProductInventarioTable.columnLotName}, ${ProductInventarioTable.columnExpirationDate}, ${ProductInventarioTable.columnWeight}, ');
          queryBuffer.write('${ProductInventarioTable.columnWeightUomName}, ${ProductInventarioTable.columnVolume}, ${ProductInventarioTable.columnVolumeUomName}, ');
          queryBuffer.write('${ProductInventarioTable.columnUom}, ${ProductInventarioTable.columnLocationId}, ${ProductInventarioTable.columnLocationName}, ');
          queryBuffer.write('${ProductInventarioTable.columnQuantity}, ${ProductInventarioTable.columnUseExpirationDate}, ${ProductInventarioTable.columnCategory}, ${ProductInventarioTable.columnIsSynced}) VALUES ');

          final List<dynamic> args = [];
          for (var j = 0; j < chunk.length; j++) {
            if (j > 0) queryBuffer.write(', ');
            queryBuffer.write('(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)'); // 19 params

            var producto = chunk[j];
            args.addAll([
              producto.code == false ? "" : producto.code ?? '',
              producto.productId,
              producto.name ?? '',
              producto.barcode == false ? "" : producto.barcode ?? '',
              producto.tracking == false ? "none" : producto.tracking ?? '',
              producto.lotId == false ? 0 : producto.lotId ?? 0,
              producto.lotName == false ? "" : producto.lotName ?? '',
              producto.expirationDate == false ? "" : producto.expirationDate ?? '',
              producto.weight == false ? 0 : producto.weight ?? 0,
              producto.weightUomName == false ? "" : producto.weightUomName ?? '',
              producto.volume == false ? 0 : producto.volume ?? 0,
              producto.volumeUomName == false ? "" : producto.volumeUomName ?? '',
              producto.uom == false ? "" : producto.uom ?? '',
              producto.locationId == false ? 0 : producto.locationId ?? 0,
              producto.locationName == false ? "" : producto.locationName ?? '',
              producto.quantity == false ? 0.0 : producto.quantity ?? 0.0,
              producto.useExpirationDate == true ? 1 : 0,
              producto.category == false ? "" : producto.category ?? '',
              1
            ]);
          }
          batch.rawInsert(queryBuffer.toString(), args);
        }
        await batch.commit(noResult: true);

        stopwatch.stop();
        debugPrint(
            "📦 Insertados Productos Inventario: ${productosList.length} | Tiempo: ${stopwatch.elapsedMilliseconds} ms");
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
