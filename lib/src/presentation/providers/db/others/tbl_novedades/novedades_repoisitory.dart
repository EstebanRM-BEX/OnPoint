// novedades_repository.dart

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/features/user/domain/entities/user_novelty.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'novedades_table.dart';

class NovedadesRepository {
  // Tamaño del bloque para inserción masiva
  static const int _batchSize = 500;

  /// --------------------------------------------------------------------------
  /// METODO OPTIMIZADO: syncNovedades (Mark & Sweep)
  /// --------------------------------------------------------------------------
  /// 1. MARCA: Pone todos los registros como "no sincronizados" (0).
  /// 2. UPSERT: Inserta/Actualiza los nuevos y los marca como "sincronizados" (1).
  /// 3. BARRIDO: Elimina los que quedaron en 0 (ya no existen en el servidor).
  Future<void> syncNovedades(List<Novedad> novedadesList) async {
    if (novedadesList.isEmpty) return;

    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      // Transacción exclusiva para velocidad y consistencia
      await db.transaction((txn) async {
        // PASO 1: MARCA (Resetear flag)
        await txn.rawUpdate(
            'UPDATE ${NovedadesTable.tableName} SET ${NovedadesTable.columnIsSynced} = 0');

        // PASO 2: UPSERT POR LOTES (Chunking)
        for (var i = 0; i < novedadesList.length; i += _batchSize) {
          final end = (i + _batchSize < novedadesList.length)
              ? i + _batchSize
              : novedadesList.length;
          final batchList = novedadesList.sublist(i, end);

          Batch batch = txn.batch();

          for (var novedad in batchList) {
            batch.insert(
              NovedadesTable.tableName,
              {
                NovedadesTable.columnId: novedad.id,
                NovedadesTable.columnName: novedad.name,
                NovedadesTable.columnCode: novedad.code,
                // ✅ Marcamos como sincronizado
                NovedadesTable.columnIsSynced: 1,
              },
              // ✅ Si el ID ya existe, actualiza el nombre/código. Si no, inserta.
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);
        }

        // PASO 3: BARRIDO (Eliminar obsoletos)
        int deleted = await txn.delete(
          NovedadesTable.tableName,
          where: '${NovedadesTable.columnIsSynced} = ?',
          whereArgs: [0],
        );

        debugPrint(
            "📋 Sync Novedades: Procesados ${novedadesList.length} | Eliminados Obsoletos: $deleted");
      });
    } catch (e, s) {
      debugPrint("❌ Error al sincronizar novedades: $e => $s");
    }
  }

  // Método para obtener todas las novedades (Sin cambios mayores, solo limpieza)
  Future<List<Novedad>> getAllNovedades() async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      final List<Map<String, dynamic>> maps =
          await db.query(NovedadesTable.tableName);

      return maps.map((map) {
        return Novedad(
          id: map[NovedadesTable.columnId],
          name: map[NovedadesTable.columnName],
          code: map[NovedadesTable.columnCode],
        );
      }).toList();
    } catch (e) {
      debugPrint("Error al obtener novedades: $e");
      return [];
    }
  }
}
