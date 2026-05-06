import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/picking/tbl_pick/picking_pick_table.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/PickhWithProducts_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/response_pick_model.dart';
import 'pick_products_table.dart';

class PickProductsRepository {
  final String _table = PickProductsTable.tableName;
  Future<void> insertPickProducts(
      List<ProductsBatch> pickProducts, String typePick) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();

      await db.transaction((txn) async {
        final batch = txn.batch();

        // Obtener todos los registros existentes una sola vez
        final existing = await txn.query(_table);
        final existingSet = existing
            .map((e) =>
                '${e[PickProductsTable.columnIdProduct]}_${e[PickProductsTable.columnBatchId]}_${e[PickProductsTable.columnIdMove]}')
            .toSet();

        for (var product in pickProducts) {
          final key =
              '${product.idProduct}_${product.batchId}_${product.idMove}';

          final data = {
            PickProductsTable.columnId: product.id,
            PickProductsTable.columnIdProduct: product.idProduct,
            PickProductsTable.columnBatchId: product.batchId,
            PickProductsTable.columnExpireDate: product.expireDate ?? '',
            PickProductsTable.columnProductId: product.productId?[1],
            PickProductsTable.columnLocationId: product.locationId?[1],
            PickProductsTable.columnLote: product.lote ?? "",
            PickProductsTable.columnRimovalPriority: product.rimovalPriority,
            PickProductsTable.columnBarcodeLocationDest:
                product.barcodeLocationDest ?? '',
            PickProductsTable.columnBarcodeLocation:
                product.barcodeLocation ?? '',
            PickProductsTable.columnLoteId: product.loteId,
            PickProductsTable.columnIdMove: product.idMove,
            PickProductsTable.columnLocationDestId: product.locationDestId?[1],
            PickProductsTable.columnIdLocationDest: product.locationDestId?[0],
            PickProductsTable.columnQuantity: product.quantity,
            PickProductsTable.columnUnidades: product.unidades,
            PickProductsTable.columnMuelleId: product.locationDestId?[0],
            PickProductsTable.columnBarcode: product.barcode ?? '',
            PickProductsTable.columnWeight: product.weigth,
            PickProductsTable.columnOrigin: product.origin,
            PickProductsTable.columnTypePick: typePick,
            PickProductsTable.columnIsSeparate: product.isSeparate ?? 0,
            PickProductsTable.columnObservation: product.observation ?? '',
            PickProductsTable.columnQuantitySeparate:
                product.quantitySeparate ?? 0,
            PickProductsTable.columnIsSendOdoo:
                product.isSeparate == 0 ? null : product.isSeparate ?? 1,
            //product_code
            PickProductsTable.columnProductCode: product.productCode ?? '',
            //product_tracking
            PickProductsTable.columnProductTracking:
                product.productTracking ?? '',
            // Convertir timeSeparate a segundos
            PickProductsTable.columnTimeSeparateStart:
                _parseDurationToSeconds(product.timeSeparate),
          };

          if (existingSet.contains(key)) {
            batch.update(
              _table,
              data,
              where:
                  '${PickProductsTable.columnIdProduct} = ? AND ${PickProductsTable.columnBatchId} = ? AND ${PickProductsTable.columnIdMove} = ?',
              whereArgs: [
                product.idProduct,
                product.batchId,
                product.idMove,
              ],
            );
          } else {
            batch.insert(
              _table,
              data,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        await batch.commit(noResult: true);
      });
    } catch (e, s) {
      debugPrint('Error insertPickProducts: $e => $s');
    }
  }

  double? _parseDurationToSeconds(dynamic time) {
    try {
      if (time is String && time.contains(':')) {
        final parts = time.split(':').map(int.parse).toList();
        if (parts.length == 3) {
          final duration = Duration(
            hours: parts[0],
            minutes: parts[1],
            seconds: parts[2],
          );
          return duration.inSeconds.toDouble();
        }
      }
    } catch (e) {
      debugPrint('Error parsing time_separate: $e');
    }
    return null; // Si no es válido, devuelve null
  }

  Future<PickWithProducts?> getPickWithProducts(int pickId) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();

      final List<Map<String, dynamic>> pickMaps = await db.query(
        PickingPickTable.tableName,
        where: 'id = ?',
        whereArgs: [pickId],
      );

      if (pickMaps.isEmpty) {
        return null; // No se encontró el picking
      }

      final ResultPick pick = ResultPick.fromMap(pickMaps.first);

      final List<Map<String, dynamic>> productMaps = await db.query(
        PickProductsTable.tableName,
        where: 'batch_id = ?',
        whereArgs: [pickId],
      );

      final List<ProductsBatch> products =
          productMaps.map((map) => ProductsBatch.fromMap(map)).toList();

      return PickWithProducts(pick: pick, products: products);
    } catch (e, s) {
      debugPrint('Error getPickWithProducts: $e => $s');
      return null;
    }
  }

  //* Obtener todos los productos de la tabla
  Future<List<ProductsBatch>> getProducts() async {
    final db = await DataBaseSqlite().getDatabaseInstance();
    final List<Map<String, dynamic>> maps = await db!.query(_table);
    return maps.map((map) => ProductsBatch.fromMap(map)).toList();
  }

  //* Obtener productos filtrados por id de batch
  Future<List<ProductsBatch>> getBatchProducts(int batchId) async {
    final db = await DataBaseSqlite().getDatabaseInstance();
    final List<Map<String, dynamic>> maps = await db!.query(
      _table,
      where: 'batch_id = ?',
      whereArgs: [batchId],
    );
    return maps.map((map) => ProductsBatch.fromMap(map)).toList();
  }

  Future<int?> updateNovedad(
    int batchId,
    int productId,
    String novedad,
    int idMove,
  ) async {
    final db = await DataBaseSqlite().getDatabaseInstance();

    final resUpdate = await db.rawUpdate(
      '''
    UPDATE $_table 
    SET observation = ? 
    WHERE batch_id = ? AND id_product = ? AND id_move = ?
    ''',
      [novedad, batchId, productId, idMove],
    );

    debugPrint("updateNovedad: $resUpdate");
    return resUpdate;
  }

  Future<int?> setFieldTablePickProducts(
    int batchId,
    int productId,
    String field,
    dynamic setValue,
    int idMove,
  ) async {
    final db = await DataBaseSqlite().getDatabaseInstance();

    final resUpdate = await db.rawUpdate(
      '''
    UPDATE $_table 
    SET $field = ? 
    WHERE batch_id = ? AND id_product = ? AND id_move = ?
    ''',
      [setValue, batchId, productId, idMove],
    );

    debugPrint("update $_table ($field): $resUpdate");
    return resUpdate;
  }

  Future<int?> setFieldStringTablePickProducts(
    int batchId,
    int productId,
    String field,
    String setValue,
    int idMove,
  ) async {
    final db = await DataBaseSqlite().getDatabaseInstance();

    final resUpdate = await db.rawUpdate(
      '''
    UPDATE $_table 
    SET $field = ? 
    WHERE batch_id = ? AND id_product = ? AND id_move = ?
    ''',
      [setValue, batchId, productId, idMove],
    );

    debugPrint("update $_table ($field): $resUpdate");
    return resUpdate;
  }

  Future<int?> incremenQtyProductSeparate(
    int batchId,
    int productId,
    int idMove,
    dynamic quantity,
  ) async {
    final db = await DataBaseSqlite().getDatabaseInstance();

    return await db.transaction((txn) async {
      // Obtener el valor actual de quantity_separate y quantity
      final result = await txn.query(
        _table,
        columns: ['quantity_separate', 'quantity'],
        where: 'batch_id = ? AND id_product = ? AND id_move = ?',
        whereArgs: [batchId, productId, idMove],
      );

      if (result.isNotEmpty) {
        dynamic currentQtySeparate = (result.first['quantity_separate']) ?? 0;
        dynamic currentQty = (result.first['quantity']) ?? 0;

        dynamic newQtySeparate = currentQtySeparate + quantity;

        // Limitar a no superar la cantidad total
        if (newQtySeparate > currentQty) {
          newQtySeparate = currentQty;
        }

        // Actualizar la tabla
        return await txn.update(
          _table,
          {'quantity_separate': newQtySeparate},
          where: 'batch_id = ? AND id_product = ? AND id_move = ?',
          whereArgs: [batchId, productId, idMove],
        );
      }

      return null; // No se encontró el registro
    });
  }

  Future<int?> dateTransaccionProduct(
      int batchId, String date, int productId, int moveId) async {
    final db = await DataBaseSqlite().getDatabaseInstance();
    if (db == null) return null;

    final resUpdate = await db.rawUpdate(
      "UPDATE $_table SET fecha_transaccion = ? WHERE batch_id = ? AND id_product = ? AND id_move = ?",
      [date, batchId, productId, moveId],
    );

    debugPrint("dateTransaccionProduct: $resUpdate");
    return resUpdate;
  }

  Future<ProductsBatch?> getProductPick(
      int pickId, int productId, int idMove) async {
    final db = await DataBaseSqlite().getDatabaseInstance();
    if (db == null) return null;

    final List<Map<String, dynamic>> maps = await db.query(
      _table,
      where: 'batch_id = ? AND id_product = ? AND id_move = ?',
      whereArgs: [pickId, productId, idMove],
    );

    if (maps.isNotEmpty) {
      return ProductsBatch.fromMap(maps.first);
    }
    return null;
  }

  Future<int?> startStopwatch(
      int batchId, int productId, int moveId, String date) async {
    final db = await DataBaseSqlite().getDatabaseInstance();
    final resUpdate = await db!.rawUpdate(
        "UPDATE $_table SET time_separate_start = '$date' WHERE batch_id = $batchId AND id_product = $productId AND id_move = $moveId");
    debugPrint("tiemppo de inicio :$date  --> $resUpdate");
    return resUpdate;
  }

  Future<int?> totalStopwatchProduct(
      int batchId, int productId, int moveId, double time) async {
    final db = await DataBaseSqlite().getDatabaseInstance();
    final resUpdate = await db!.rawUpdate(
        "UPDATE $_table SET time_separate = $time WHERE batch_id = $batchId AND id_product = $productId AND id_move = $moveId");
    debugPrint("totalStopwatchProduct: $resUpdate");
    return resUpdate;
  }

  Future<int?> endStopwatchProduct(
      int batchId, String date, int productId, int moveId) async {
    final db = await DataBaseSqlite().getDatabaseInstance();
    final resUpdate = await db!.rawUpdate(
        "UPDATE $_table SET time_separate_end = '$date' WHERE batch_id = $batchId AND id_product = $productId AND id_move = $moveId");
    debugPrint("endStopwatchProduct: $resUpdate");
    return resUpdate;
  }

  Future<String> getFieldTableProductsPick(
      int batchId, int productId, int moveId, String field) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      final res = await db!.rawQuery('''
      SELECT $field FROM  $_table  WHERE batch_id = $batchId AND  id_product = $productId AND id_move = $moveId LIMIT 1
    ''');
      if (res.isNotEmpty) {
        String responsefield = res[0]['${field}'].toString();
        return responsefield;
      }
      return "";
    } catch (e, s) {
      debugPrint("error getFieldTableProductsPick: $e => $s");
    }
    return "";
  }
}
