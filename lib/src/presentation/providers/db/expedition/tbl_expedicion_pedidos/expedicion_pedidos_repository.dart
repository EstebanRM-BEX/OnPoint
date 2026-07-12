import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/features/expedition/data/models/expedicion_pedido_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/expedition/tbl_expedicion_pedidos/expedicion_pedidos_table.dart';

/// Repositorio para tbl_expedicion_pedidos. Mismo patrón upsert-por-id que
/// PedidoPackRepository (db/packing/packing_pedido).
class ExpedicionPedidosRepository {
  Future<void> insertOrUpdateExpediciones(
      List<ExpedicionPedidoModel> pedidos) async {
    if (pedidos.isEmpty) return;
    try {
      final Database db = await DataBaseSqlite().getDatabaseInstance();

      await db.transaction((txn) async {
        final batch = txn.batch();

        final Set<int> idsToProcess = pedidos
            .where((p) => p.expeditionId != null)
            .map((p) => p.expeditionId!)
            .toSet();

        Set<int> existingIds = {};
        if (idsToProcess.isNotEmpty) {
          final existingRows = await txn.query(
            ExpedicionPedidosTable.tableName,
            columns: [ExpedicionPedidosTable.columnExpeditionId],
            where:
                '${ExpedicionPedidosTable.columnExpeditionId} IN (${List.filled(idsToProcess.length, '?').join(',')})',
            whereArgs: idsToProcess.toList(),
          );
          existingIds = existingRows
              .map((row) => row[ExpedicionPedidosTable.columnExpeditionId] as int)
              .toSet();
        }

        for (final pedido in pedidos) {
          final data = pedido.toMap();
          if (pedido.expeditionId != null &&
              existingIds.contains(pedido.expeditionId)) {
            batch.update(
              ExpedicionPedidosTable.tableName,
              data,
              where: '${ExpedicionPedidosTable.columnExpeditionId} = ?',
              whereArgs: [pedido.expeditionId],
            );
          } else {
            batch.insert(
              ExpedicionPedidosTable.tableName,
              data,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        await batch.commit(noResult: true);
      });
    } catch (e, s) {
      debugPrint("Error al insertar/actualizar tbl_expedicion_pedidos: $e\n$s");
      rethrow;
    }
  }

  Future<List<ExpedicionPedidoModel>> getAllExpediciones() async {
    try {
      final Database db = await DataBaseSqlite().getDatabaseInstance();
      final maps = await db.query(
        ExpedicionPedidosTable.tableName,
        orderBy: '${ExpedicionPedidosTable.columnFecha} DESC',
      );
      return maps.map((m) => ExpedicionPedidoModel.fromMap(m)).toList();
    } catch (e, s) {
      debugPrint("Error al obtener tbl_expedicion_pedidos: $e\n$s");
      return [];
    }
  }

  Future<ExpedicionPedidoModel?> getExpedicionById(int expeditionId) async {
    try {
      final Database db = await DataBaseSqlite().getDatabaseInstance();
      final maps = await db.query(
        ExpedicionPedidosTable.tableName,
        where: '${ExpedicionPedidosTable.columnExpeditionId} = ?',
        whereArgs: [expeditionId],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return ExpedicionPedidoModel.fromMap(maps.first);
    } catch (e, s) {
      debugPrint("Error al obtener expedición $expeditionId: $e\n$s");
      return null;
    }
  }

  Future<int> updateField(
      int expeditionId, String field, dynamic value) async {
    try {
      final Database db = await DataBaseSqlite().getDatabaseInstance();
      return await db.update(
        ExpedicionPedidosTable.tableName,
        {field: value},
        where: '${ExpedicionPedidosTable.columnExpeditionId} = ?',
        whereArgs: [expeditionId],
      );
    } catch (e, s) {
      debugPrint(
          "Error al actualizar campo '$field' de expedición $expeditionId: $e\n$s");
      return 0;
    }
  }

  Future<void> deleteAllExpediciones() async {
    try {
      final Database db = await DataBaseSqlite().getDatabaseInstance();
      await db.delete(ExpedicionPedidosTable.tableName);
    } catch (e, s) {
      debugPrint("Error al eliminar tbl_expedicion_pedidos: $e\n$s");
    }
  }
}
