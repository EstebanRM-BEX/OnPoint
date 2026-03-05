import 'package:flutter/material.dart';
import 'package:wms_app/src/presentation/providers/db/conteo/tbl_ubicaciones_orden_conteo/ubicaciones_conteo_table.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/conteo/models/conteo_response_model.dart';

import 'package:sqflite/sqflite.dart';

class UbicacionesConteoRepository {
  // Insertar/actualizar ubicaciones de conteo
  Future<void> upsertUbicacionesConteo(List<Allowed> ubicaciones) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      await db.transaction((txn) async {
        final Batch batch = txn.batch();
        for (final ubicacion in ubicaciones) {
          final ubicacionMap = {
            UbicacionesConteoTable.columnId: ubicacion.id,
            UbicacionesConteoTable.columnName: ubicacion.name ?? '',
            UbicacionesConteoTable.columnOrdenConteoId:
                ubicacion.ordenConteoId ?? 0,
            UbicacionesConteoTable.columnBarcode: ubicacion.barcode ?? '',
          };
          batch.insert(
            UbicacionesConteoTable.tableName,
            ubicacionMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
      debugPrint('✅ ${ubicaciones.length} ubicaciones insertadas/actualizadas');
    } catch (e, s) {
      debugPrint('❌ Error en upsertUbicacionesConteo: $e');
      debugPrint(s.toString());
      rethrow;
    }
  }

  // Obtener todas las ubicaciones de conteo para una orden específica
  Future<List<Allowed>> getUbicacionesByOrdenId(int ordenConteoId) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> maps = await db.query(
        UbicacionesConteoTable.tableName,
        where: '${UbicacionesConteoTable.columnOrdenConteoId} = ?',
        whereArgs: [ordenConteoId],
      );

      debugPrint(
          'Ubicaciones obtenidas para orden $ordenConteoId: ${maps.length}');

      return List.generate(maps.length, (i) {
        return Allowed(
          id: maps[i][UbicacionesConteoTable.columnId],
          name: maps[i][UbicacionesConteoTable.columnName],
          ordenConteoId: maps[i][UbicacionesConteoTable.columnOrdenConteoId],
          barcode: maps[i][UbicacionesConteoTable.columnBarcode],
        );
      });
    } catch (e, s) {
      debugPrint('Error en getUbicacionesByOrdenId: $e');
      debugPrint(s.toString());
      return [];
    }
  }

  // Obtener todas las ubicaciones de conteo (sin filtrar)
  Future<List<Allowed>> getAllUbicacionesConteo() async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> maps =
          await db.query(UbicacionesConteoTable.tableName);

      return List.generate(maps.length, (i) {
        return Allowed(
          id: maps[i][UbicacionesConteoTable.columnId],
          name: maps[i][UbicacionesConteoTable.columnName],
        );
      });
    } catch (e, s) {
      debugPrint('Error en getAllUbicacionesConteo: $e');
      debugPrint(s.toString());
      return [];
    }
  }

  // Eliminar ubicaciones de una orden específica
  Future<int> deleteUbicacionesByOrdenId(int ordenConteoId) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      return await db.delete(
        UbicacionesConteoTable.tableName,
        where: '${UbicacionesConteoTable.columnOrdenConteoId} = ?',
        whereArgs: [ordenConteoId],
      );
    } catch (e, s) {
      debugPrint('Error en deleteUbicacionesByOrdenId: $e');
      debugPrint(s.toString());
      return 0;
    }
  }
}
