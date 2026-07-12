import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/features/expedition/data/models/item_suelto_expedicion_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/expedition/tbl_expedicion_items_sueltos/expedicion_items_sueltos_table.dart';

/// Repositorio para tbl_expedicion_items_sueltos (productos sueltos —
/// items_validados/items_pendientes — hijos directos de un pedido de
/// expedición). Se resincroniza completa por expedición en cada fetch.
class ExpedicionItemsSueltosRepository {
  Future<void> insertItemsSueltosForExpedicion(
      int expeditionId, List<ItemSueltoExpedicionModel> items) async {
    try {
      final Database db = await DataBaseSqlite().getDatabaseInstance();
      await db.transaction((txn) async {
        await txn.delete(
          ExpedicionItemsSueltosTable.tableName,
          where: '${ExpedicionItemsSueltosTable.columnExpeditionId} = ?',
          whereArgs: [expeditionId],
        );

        if (items.isEmpty) return;

        final batch = txn.batch();
        for (final item in items) {
          batch.insert(
            ExpedicionItemsSueltosTable.tableName,
            item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    } catch (e, s) {
      debugPrint(
          "Error al insertar items sueltos de expedición $expeditionId: $e\n$s");
      rethrow;
    }
  }

  Future<List<ItemSueltoExpedicionModel>> getItemsSueltosByExpedicion(
      int expeditionId) async {
    try {
      final Database db = await DataBaseSqlite().getDatabaseInstance();
      final maps = await db.query(
        ExpedicionItemsSueltosTable.tableName,
        where: '${ExpedicionItemsSueltosTable.columnExpeditionId} = ?',
        whereArgs: [expeditionId],
      );
      return maps.map((m) => ItemSueltoExpedicionModel.fromMap(m)).toList();
    } catch (e, s) {
      debugPrint(
          "Error al obtener items sueltos de expedición $expeditionId: $e\n$s");
      return [];
    }
  }

  Future<void> updateIsValidate({
    required int expeditionId,
    required int packingId,
    required bool value,
  }) async {
    try {
      final Database db = await DataBaseSqlite().getDatabaseInstance();
      await db.update(
        ExpedicionItemsSueltosTable.tableName,
        {ExpedicionItemsSueltosTable.columnIsValidate: value ? 1 : 0},
        where:
            '${ExpedicionItemsSueltosTable.columnExpeditionId} = ? AND ${ExpedicionItemsSueltosTable.columnPackingId} = ?',
        whereArgs: [expeditionId, packingId],
      );
    } catch (e, s) {
      debugPrint(
          "Error al actualizar is_validate del item suelto $packingId ($expeditionId): $e\n$s");
    }
  }

  Future<void> deleteAllItemsSueltos() async {
    try {
      final Database db = await DataBaseSqlite().getDatabaseInstance();
      await db.delete(ExpedicionItemsSueltosTable.tableName);
    } catch (e, s) {
      debugPrint("Error al eliminar tbl_expedicion_items_sueltos: $e\n$s");
    }
  }
}
