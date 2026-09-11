import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/features/transferencia_multiusuario/data/models/transferencia_session_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/transferencia_multiusuario/tbl_transferencia_sessions/transferencia_sessions_table.dart';

/// Repositorio para tbl_transferencia_sessions. Mismo patrón upsert-por-id
/// que RecepcionSessionsRepository.
class TransferenciaSessionsRepository {
  Future<void> insertOrUpdateSessions(
    List<TransferenciaSessionModel> sessions,
  ) async {
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
            TransferenciaSessionsTable.tableName,
            columns: [TransferenciaSessionsTable.columnSessionId],
            where:
                '${TransferenciaSessionsTable.columnSessionId} IN (${List.filled(idsToProcess.length, '?').join(',')})',
            whereArgs: idsToProcess.toList(),
          );
          existingIds = existingRows
              .map(
                (row) =>
                    row[TransferenciaSessionsTable.columnSessionId] as int,
              )
              .toSet();
        }

        for (final session in sessions) {
          final data = session.toMap();
          if (session.sessionId != null &&
              existingIds.contains(session.sessionId)) {
            batch.update(
              TransferenciaSessionsTable.tableName,
              data,
              where: '${TransferenciaSessionsTable.columnSessionId} = ?',
              whereArgs: [session.sessionId],
            );
          } else {
            batch.insert(
              TransferenciaSessionsTable.tableName,
              data,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        await batch.commit(noResult: true);
      });
    } catch (e, s) {
      debugPrint(
        "Error al insertar/actualizar tbl_transferencia_sessions: $e\n$s",
      );
      rethrow;
    }
  }

  Future<List<TransferenciaSessionModel>> getAllSessions() async {
    try {
      final Database db = await DataBaseSqlite().getDatabaseInstance();
      final maps = await db.query(
        TransferenciaSessionsTable.tableName,
        orderBy: '${TransferenciaSessionsTable.columnName} ASC',
      );
      return maps.map((m) => TransferenciaSessionModel.fromMap(m)).toList();
    } catch (e, s) {
      debugPrint("Error al obtener tbl_transferencia_sessions: $e\n$s");
      return [];
    }
  }

  Future<void> deleteAllSessions() async {
    try {
      final Database db = await DataBaseSqlite().getDatabaseInstance();
      await db.delete(TransferenciaSessionsTable.tableName);
    } catch (e, s) {
      debugPrint("Error al eliminar tbl_transferencia_sessions: $e\n$s");
    }
  }
}
