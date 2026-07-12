import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/features/expedition/data/models/item_expedicion_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/expedition/tbl_expedicion_items/expedicion_items_table.dart';

/// Repositorio para tbl_expedicion_items (hija de un paquete de expedición).
/// Se resincroniza completa por paquete en cada fetch (borra + reinserta).
class ExpedicionItemsRepository {
  Future<void> insertItemsForPaquete(
      int packingId, List<ItemExpedicionModel> items) async {
    try {
      final Database db = await DataBaseSqlite().getDatabaseInstance();
      await db.transaction((txn) async {
        await txn.delete(
          ExpedicionItemsTable.tableName,
          where: '${ExpedicionItemsTable.columnPackingId} = ?',
          whereArgs: [packingId],
        );

        if (items.isEmpty) return;

        final batch = txn.batch();
        for (final item in items) {
          batch.insert(
            ExpedicionItemsTable.tableName,
            item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    } catch (e, s) {
      debugPrint("Error al insertar items del paquete $packingId: $e\n$s");
      rethrow;
    }
  }

  Future<List<ItemExpedicionModel>> getItemsByPaquete(int packingId) async {
    try {
      final Database db = await DataBaseSqlite().getDatabaseInstance();
      final maps = await db.query(
        ExpedicionItemsTable.tableName,
        where: '${ExpedicionItemsTable.columnPackingId} = ?',
        whereArgs: [packingId],
      );
      return maps.map((m) => ItemExpedicionModel.fromMap(m)).toList();
    } catch (e, s) {
      debugPrint("Error al obtener items del paquete $packingId: $e\n$s");
      return [];
    }
  }

  Future<void> updateIsValidateForPaquete(int packingId, bool value) async {
    try {
      final Database db = await DataBaseSqlite().getDatabaseInstance();
      await db.update(
        ExpedicionItemsTable.tableName,
        {ExpedicionItemsTable.columnIsValidate: value ? 1 : 0},
        where: '${ExpedicionItemsTable.columnPackingId} = ?',
        whereArgs: [packingId],
      );
    } catch (e, s) {
      debugPrint(
          "Error al actualizar is_validate de items del paquete $packingId: $e\n$s");
    }
  }

  Future<void> deleteAllItems() async {
    try {
      final Database db = await DataBaseSqlite().getDatabaseInstance();
      await db.delete(ExpedicionItemsTable.tableName);
    } catch (e, s) {
      debugPrint("Error al eliminar tbl_expedicion_items: $e\n$s");
    }
  }
}
