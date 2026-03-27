// ignore_for_file: unrelated_type_equality_checks

import 'package:flutter/foundation.dart'; // Import para compute
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/product_inventario_table.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/models/update_product_request.dart';
import 'package:wms_app/src/presentation/views/inventario/models/response_products_model.dart';
import 'dart:core';

// Funciones Top-Level
List<Map<String, dynamic>> _processProductsRawArgs(
    List<Product> productosList) {
  final List<Map<String, dynamic>> queries = [];
  // LÍMITE ABSOLUTO DE VARIABLES SQLITE: 999.
  // Tenemos 19 columnas, entonces 999 / 19 = 52.5.
  // Usaremos 52 como el tamaño óptimo de iteración masiva de caché.
  const int itemsPerQuery = 52;

  for (var i = 0; i < productosList.length; i += itemsPerQuery) {
    final end = (i + itemsPerQuery < productosList.length)
        ? i + itemsPerQuery
        : productosList.length;
    final chunk = productosList.sublist(i, end);

    final StringBuffer queryBuffer = StringBuffer();
    queryBuffer.write('INSERT INTO ${ProductInventarioTable.tableName} (');
    queryBuffer.write(
        '${ProductInventarioTable.columnProductCode}, ${ProductInventarioTable.columnProductId}, ${ProductInventarioTable.columnProductName}, ');
    queryBuffer.write(
        '${ProductInventarioTable.columnBarcode}, ${ProductInventarioTable.columnProductracking}, ${ProductInventarioTable.columnLotId}, ');
    queryBuffer.write(
        '${ProductInventarioTable.columnLotName}, ${ProductInventarioTable.columnExpirationDate}, ${ProductInventarioTable.columnWeight}, ');
    queryBuffer.write(
        '${ProductInventarioTable.columnWeightUomName}, ${ProductInventarioTable.columnVolume}, ${ProductInventarioTable.columnVolumeUomName}, ');
    queryBuffer.write(
        '${ProductInventarioTable.columnUom}, ${ProductInventarioTable.columnLocationId}, ${ProductInventarioTable.columnLocationName}, ');
    queryBuffer.write(
        '${ProductInventarioTable.columnQuantity}, ${ProductInventarioTable.columnUseExpirationDate}, ${ProductInventarioTable.columnCategory}, ${ProductInventarioTable.columnIsSynced}) VALUES ');

    final List<dynamic> args = [];
    for (var j = 0; j < chunk.length; j++) {
      if (j > 0) queryBuffer.write(',');
      queryBuffer.write('(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)'); // 19 params

      final producto = chunk[j];
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
    queries.add({
      'sql': queryBuffer.toString(),
      'args': args,
    });
  }
  return queries;
}

List<Product> _parseProductsMap(List<Map<String, dynamic>> maps) {
  return maps.map((m) => Product.fromMap(m)).toList();
}

class ProductInventarioRepository {
  /// --------------------------------------------------------------------------
  /// METODO OPTIMIZADO: insertProductosInventario (Mark & Sweep)
  /// --------------------------------------------------------------------------
  Future<void> insertProductosInventario(List<Product> productosList) async {
    if (productosList.isEmpty) return;

    Stopwatch stopwatch = Stopwatch();
    stopwatch.start();

    try {
      final List<Map<String, dynamic>> queries =
          await compute(_processProductsRawArgs, productosList);

      Database db = await DataBaseSqlite().getDatabaseInstance();

      await db.rawQuery('PRAGMA synchronous = OFF;');

      await db.transaction((txn) async {
        final Batch batch = txn.batch();

        for (var query in queries) {
          batch.rawInsert(
              query['sql'] as String, query['args'] as List<dynamic>);
        }

        await batch.commit(noResult: true);
      });

      // Restauramos la DB
      await db.rawQuery('PRAGMA synchronous = NORMAL;');

      stopwatch.stop();
      debugPrint(
          "📦 [BENCHMARK] Insertados Productos Inventario: ${productosList.length} | Tiempo: ${stopwatch.elapsedMilliseconds} ms");
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
        // Uso de isolados para evitar jank en el thread principal
        return await compute(_parseProductsMap, maps);
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

      if (maps.isNotEmpty) {
        // Optimización Isolate
        return await compute(_parseProductsMap, maps);
      } else {
        return [];
      }
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
