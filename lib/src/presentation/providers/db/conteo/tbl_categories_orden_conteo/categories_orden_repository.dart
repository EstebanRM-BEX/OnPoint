import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/conteo/tbl_categories_orden_conteo/categories_orden_table.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/conteo/models/conteo_response_model.dart';

class CategoriasConteoRepository {
  // Insertar/actualizar categorías de conteo
  Future<void> upsertCategoriasConteo(
    List<Allowed> categorias,
  ) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();

      await db.transaction((txn) async {
        final Batch batch = txn.batch();
        for (final categoria in categorias) {
          final categoriaMap = {
            CategoriasConteoTable.columnId: categoria.id,
            CategoriasConteoTable.columnName: categoria.name ?? '',
            CategoriasConteoTable.columnOrdenConteoId:
                categoria.ordenConteoId ?? 0,
          };

          batch.insert(
            CategoriasConteoTable.tableName,
            categoriaMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await batch.commit(noResult: true);
      });

      debugPrint('✅ ${categorias.length} categorías insertadas');
    } catch (e, s) {
      debugPrint('❌ Error en upsertCategoriasConteo: $e');
      debugPrint(s.toString());
      rethrow;
    }
  }

  // Obtener categorías por ID de orden
  Future<List<Allowed>> getCategoriasByOrdenId(int ordenConteoId) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> maps = await db.query(
        CategoriasConteoTable.tableName,
        where: '${CategoriasConteoTable.columnOrdenConteoId} = ?',
        whereArgs: [ordenConteoId],
      );

      return List.generate(maps.length, (i) {
        return Allowed(
          id: maps[i][CategoriasConteoTable.columnId],
          name: maps[i][CategoriasConteoTable.columnName],
        );
      });
    } catch (e, s) {
      debugPrint('Error en getCategoriasByOrdenId: $e');
      debugPrint(s.toString());
      return [];
    }
  }

  // Obtener todas las categorías de conteo
  Future<List<Allowed>> getAllCategoriasConteo() async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> maps =
          await db.query(CategoriasConteoTable.tableName);

      return List.generate(maps.length, (i) {
        return Allowed(
          id: maps[i][CategoriasConteoTable.columnId],
          name: maps[i][CategoriasConteoTable.columnName],
        );
      });
    } catch (e, s) {
      debugPrint('Error en getAllCategoriasConteo: $e');
      debugPrint(s.toString());
      return [];
    }
  }

  // Eliminar categorías de una orden específica
  Future<int> deleteCategoriasByOrdenId(int ordenConteoId) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      return await db.delete(
        CategoriasConteoTable.tableName,
        where: '${CategoriasConteoTable.columnOrdenConteoId} = ?',
        whereArgs: [ordenConteoId],
      );
    } catch (e, s) {
      debugPrint('Error en deleteCategoriasByOrdenId: $e');
      debugPrint(s.toString());
      return 0;
    }
  }
}
