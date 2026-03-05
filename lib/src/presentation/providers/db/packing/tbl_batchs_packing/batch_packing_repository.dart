import 'package:flutter/material.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/packing/tbl_batchs_packing/batch_table.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/packing_response_model.dart';
import 'package:sqflite/sqflite.dart';

class BatchPackingRepository {
  //* Método para insertar o actualizar un batch de packing

  Future<void> insertAllBatchPacking(List<BatchPackingModel> batchList) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();

      await db.transaction((txn) async {
        final batch = txn.batch();

        for (final batchItem in batchList) {
          if (batchItem.id == null) continue;

          final data = {
            BatchPackingTable.columnId: batchItem.id,
            BatchPackingTable.columnName: batchItem.name,
            BatchPackingTable.columnScheduledDate:
                batchItem.scheduleddate.toString(),
            BatchPackingTable.columnPickingTypeId: batchItem.pickingTypeId,
            BatchPackingTable.columnState: batchItem.state,
            BatchPackingTable.columnUserId: batchItem.userId,
            BatchPackingTable.columnUserName: batchItem.userName,
            BatchPackingTable.columnCantidadPedidos: batchItem.cantidadPedidos,
            BatchPackingTable.columnZonaEntrega: batchItem.zonaEntrega,
            BatchPackingTable.columnZonaEntregaTms: batchItem.zonaEntregaTms,
            BatchPackingTable.columnStartTimePack: batchItem.startTimePack,
            BatchPackingTable.columnEndTimePack: batchItem.endTimePack,
            BatchPackingTable.columnIsSeparate: 0,
            //maneja_temperatura
            BatchPackingTable.columnManejaTemperatura:
                batchItem.manejaTemperatura,
            //temperatura
            BatchPackingTable.columnTemperatura: batchItem.temperatura,
          };

          // Elimina si ya existe el registro con ese ID
          batch.delete(
            BatchPackingTable.tableName,
            where: '${BatchPackingTable.columnId} = ?',
            whereArgs: [batchItem.id],
          );

          // Inserta el nuevo registro (reemplaza si hay conflicto)
          batch.insert(
            BatchPackingTable.tableName,
            data,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Ejecutar todos los inserts/updates en lote
        await batch.commit(noResult: true);
      });
    } catch (e) {
      debugPrint("Error insertAllBatchPacking: $e");
    }
  }

  //* Obtener todos los batchs de packing
  Future<List<BatchPackingModel>> getAllBatchsPacking() async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> maps =
          await db.query(BatchPackingTable.tableName);

      final List<BatchPackingModel> batchs = maps.map((map) {
        return BatchPackingModel.fromMap(map);
      }).toList();

      return batchs;
    } catch (e, s) {
      debugPrint("Error tblbatchs_packing: $e => $s");
    }
    return [];
  }

  //* Método para actualizar un campo específico de un batch de packing
  Future<int?> setFieldTableBatchPacking(
      int batchId, String field, dynamic setValue) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();

      // Usamos rawUpdate para actualizar el campo específico
      final resUpdate = await db.rawUpdate(
          'UPDATE ${BatchPackingTable.tableName} SET $field = ? WHERE ${BatchPackingTable.columnId} = ?',
          [setValue, batchId]);

      return resUpdate;
    } catch (e) {
      debugPrint(
          "Error al actualizar el campo $field en tblbatchs_packing: $e");
      return null;
    }
  }

  // Método para iniciar el cronómetro de un batch de picking
  Future<int?> startStopwatchBatch(int batchId, String date) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();

      // Actualiza el campo 'start_time_pick' con la fecha proporcionada
      final resUpdate = await db.rawUpdate(
          "UPDATE ${BatchPackingTable.tableName} SET ${BatchPackingTable.columnStartTimePack} = ? WHERE ${BatchPackingTable.columnId} = ?",
          [date, batchId]);

      debugPrint("startStopwatchBatchPack: $resUpdate");
      return resUpdate;
    } catch (e) {
      debugPrint(
          "Error al iniciar el cronómetro para el batch en pack: $batchId: $e");
      return null;
    }
  }
}
