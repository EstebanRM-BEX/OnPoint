import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/features/recepcion_multiusuario/data/models/recepcion_pool_item_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/recepcion_multiusuario/tbl_recepcion_session_pool/recepcion_session_pool_table.dart';

/// Repositorio para tbl_recepcion_session_pool. A diferencia de
/// RecepcionSessionsRepository (upsert por id), acá cada fetch reemplaza por
/// completo el pool de una sesión: un producto que deja de venir en la
/// respuesta significa que otro operario ya lo tomó, así que debe
/// desaparecer localmente (ver [deleteBySession] + [insertPool]).
class RecepcionSessionPoolRepository {
  Future<void> insertPool(
    int sessionId,
    List<RecepcionPoolItemModel> items,
  ) async {
    try {
      final Database db = await DataBaseSqlite().getDatabaseInstance();

      await db.transaction((txn) async {
        await txn.delete(
          RecepcionSessionPoolTable.tableName,
          where: '${RecepcionSessionPoolTable.columnSessionId} = ?',
          whereArgs: [sessionId],
        );

        if (items.isEmpty) return;

        final batch = txn.batch();
        for (final item in items) {
          batch.insert(
            RecepcionSessionPoolTable.tableName,
            item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    } catch (e, s) {
      debugPrint("Error al insertar tbl_recepcion_session_pool: $e\n$s");
      rethrow;
    }
  }

  Future<List<RecepcionPoolItemModel>> getPoolBySession(int sessionId) async {
    try {
      final Database db = await DataBaseSqlite().getDatabaseInstance();
      final maps = await db.query(
        RecepcionSessionPoolTable.tableName,
        where: '${RecepcionSessionPoolTable.columnSessionId} = ?',
        whereArgs: [sessionId],
        orderBy: '${RecepcionSessionPoolTable.columnProductName} ASC',
      );
      return maps.map((m) => RecepcionPoolItemModel.fromMap(m)).toList();
    } catch (e, s) {
      debugPrint("Error al obtener tbl_recepcion_session_pool: $e\n$s");
      return [];
    }
  }

  Future<void> deleteBySession(int sessionId) async {
    try {
      final Database db = await DataBaseSqlite().getDatabaseInstance();
      await db.delete(
        RecepcionSessionPoolTable.tableName,
        where: '${RecepcionSessionPoolTable.columnSessionId} = ?',
        whereArgs: [sessionId],
      );
    } catch (e, s) {
      debugPrint("Error al eliminar tbl_recepcion_session_pool: $e\n$s");
    }
  }

  /// Borra el pool completo de todas las sesiones — usado al cerrar sesión
  /// de la app (no de una sesión de recepción puntual).
  Future<void> deleteAll() async {
    try {
      final Database db = await DataBaseSqlite().getDatabaseInstance();
      await db.delete(RecepcionSessionPoolTable.tableName);
    } catch (e, s) {
      debugPrint("Error al eliminar todo tbl_recepcion_session_pool: $e\n$s");
    }
  }
}
