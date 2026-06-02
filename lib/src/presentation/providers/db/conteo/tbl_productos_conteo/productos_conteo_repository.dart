import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/conteo/tbl_productos_conteo/productos_conteo_table.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/conteo/models/conteo_response_model.dart';

class ProductosConteoRepository {
  Future<void> upsertProductosConteo(List<Allowed> productos) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();

      await db.transaction((txn) async {
        final Batch batch = txn.batch();
        for (final producto in productos) {
          final productoMap = {
            ProductosConteoTable.columnId: producto.id,
            ProductosConteoTable.columnName: producto.name ?? '',
            ProductosConteoTable.columnOrdenConteoId:
                producto.ordenConteoId ?? 0,
            ProductosConteoTable.columnBarcode: producto.barcode ?? '',
          };

          batch.insert(
            ProductosConteoTable.tableName,
            productoMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await batch.commit(noResult: true);
      });

      debugPrint('✅ ${productos.length} productos de conteo insertados');
    } catch (e, s) {
      debugPrint('❌ Error en upsertProductosConteo: $e');
      debugPrint(s.toString());
      rethrow;
    }
  }

  Future<List<Allowed>> getProductosByOrdenId(int ordenConteoId) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> maps = await db.query(
        ProductosConteoTable.tableName,
        where: '${ProductosConteoTable.columnOrdenConteoId} = ?',
        whereArgs: [ordenConteoId],
      );

      return List.generate(maps.length, (i) {
        return Allowed(
          id: maps[i][ProductosConteoTable.columnId],
          name: maps[i][ProductosConteoTable.columnName],
          ordenConteoId: maps[i][ProductosConteoTable.columnOrdenConteoId],
          barcode: maps[i][ProductosConteoTable.columnBarcode],
        );
      });
    } catch (e, s) {
      debugPrint('Error en getProductosByOrdenId: $e');
      debugPrint(s.toString());
      return [];
    }
  }

  Future<int> deleteProductosByOrdenId(int ordenConteoId) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      return await db.delete(
        ProductosConteoTable.tableName,
        where: '${ProductosConteoTable.columnOrdenConteoId} = ?',
        whereArgs: [ordenConteoId],
      );
    } catch (e, s) {
      debugPrint('Error en deleteProductosByOrdenId: $e');
      debugPrint(s.toString());
      return 0;
    }
  }
}
