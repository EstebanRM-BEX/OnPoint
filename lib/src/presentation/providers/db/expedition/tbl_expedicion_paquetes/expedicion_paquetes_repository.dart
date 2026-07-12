import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/features/expedition/data/models/paquete_expedicion_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/expedition/tbl_expedicion_paquetes/expedicion_paquetes_table.dart';

/// Repositorio para tbl_expedicion_paquetes (hija de un pedido de expedición).
/// Se resincroniza completa por expedición en cada fetch (borra + reinserta).
class ExpedicionPaquetesRepository {
  Future<void> insertPaquetesForExpedicion(
      int expeditionId, List<PaqueteExpedicionModel> paquetes) async {
    try {
      final Database db = await DataBaseSqlite().getDatabaseInstance();
      await db.transaction((txn) async {
        await txn.delete(
          ExpedicionPaquetesTable.tableName,
          where: '${ExpedicionPaquetesTable.columnExpeditionId} = ?',
          whereArgs: [expeditionId],
        );

        if (paquetes.isEmpty) return;

        final batch = txn.batch();
        for (final paquete in paquetes) {
          batch.insert(
            ExpedicionPaquetesTable.tableName,
            paquete.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    } catch (e, s) {
      debugPrint(
          "Error al insertar paquetes de expedición $expeditionId: $e\n$s");
      rethrow;
    }
  }

  Future<List<PaqueteExpedicionModel>> getPaquetesByExpedicion(
      int expeditionId) async {
    try {
      final Database db = await DataBaseSqlite().getDatabaseInstance();
      final maps = await db.query(
        ExpedicionPaquetesTable.tableName,
        where: '${ExpedicionPaquetesTable.columnExpeditionId} = ?',
        whereArgs: [expeditionId],
      );
      return maps.map((m) => PaqueteExpedicionModel.fromMap(m)).toList();
    } catch (e, s) {
      debugPrint(
          "Error al obtener paquetes de expedición $expeditionId: $e\n$s");
      return [];
    }
  }
}
