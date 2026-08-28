import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/features/recepcion_multiusuario/data/models/recepcion_session_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/recepcion_multiusuario/tbl_recepcion_sessions/recepcion_sessions_table.dart';

/// Repositorio para tbl_recepcion_sessions. Mismo patrón upsert-por-id que
/// ExpedicionPedidosRepository.
class RecepcionSessionsRepository {
  Future<void> insertOrUpdateSessions(
      List<RecepcionSessionModel> sessions) async {
    if (sessions.isEmpty) return;
    try {
      final Database db = await DataBaseSqlite().getDatabaseInstance();

      await db.transaction((txn) async {
        final batch = txn.batch();

        final Set<int> idsToProcess = sessions
            .where((s) => s.sessionId != null)
            .map((s) => s.sessionId!)
            .toSet();

        Set<int> existingIds = {};
        if (idsToProcess.isNotEmpty) {
          final existingRows = await txn.query(
            RecepcionSessionsTable.tableName,
            columns: [RecepcionSessionsTable.columnSessionId],
            where:
                '${RecepcionSessionsTable.columnSessionId} IN (${List.filled(idsToProcess.length, '?').join(',')})',
            whereArgs: idsToProcess.toList(),
          );
          existingIds = existingRows
              .map((row) => row[RecepcionSessionsTable.columnSessionId] as int)
              .toSet();
        }

        for (final session in sessions) {
          final data = session.toMap();
          if (session.sessionId != null &&
              existingIds.contains(session.sessionId)) {
            batch.update(
              RecepcionSessionsTable.tableName,
              data,
              where: '${RecepcionSessionsTable.columnSessionId} = ?',
              whereArgs: [session.sessionId],
            );
          } else {
            batch.insert(
              RecepcionSessionsTable.tableName,
              data,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        await batch.commit(noResult: true);
      });
    } catch (e, s) {
      debugPrint("Error al insertar/actualizar tbl_recepcion_sessions: $e\n$s");
      rethrow;
    }
  }

  Future<List<RecepcionSessionModel>> getAllSessions() async {
    try {
      final Database db = await DataBaseSqlite().getDatabaseInstance();
      final maps = await db.query(
        RecepcionSessionsTable.tableName,
        orderBy: '${RecepcionSessionsTable.columnName} ASC',
      );
      return maps.map((m) => RecepcionSessionModel.fromMap(m)).toList();
    } catch (e, s) {
      debugPrint("Error al obtener tbl_recepcion_sessions: $e\n$s");
      return [];
    }
  }

  Future<void> deleteAllSessions() async {
    try {
      final Database db = await DataBaseSqlite().getDatabaseInstance();
      await db.delete(RecepcionSessionsTable.tableName);
    } catch (e, s) {
      debugPrint("Error al eliminar tbl_recepcion_sessions: $e\n$s");
    }
  }
}
