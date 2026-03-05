import 'package:flutter/material.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/packing/packing_consolidade/tbl_batchs_packing_consolidate/batch_table.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/packing_response_model.dart';
import 'package:sqflite/sqflite.dart';

class BatchPackingConsolidateRepository {
  //* Método para insertar o actualizar un batch de packing

  Future<void> insertAllBatchPacking(List<BatchPackingModel> batchList) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();

      await db.transaction((txn) async {
        final batch = txn.batch();

        for (final batchItem in batchList) {
          if (batchItem.id == null) continue;

          final data = {
            BatchPackingConsolidateTable.columnId: batchItem.id,
            BatchPackingConsolidateTable.columnName: batchItem.name,
            BatchPackingConsolidateTable.columnScheduledDate:
                batchItem.scheduleddate.toString(),
            BatchPackingConsolidateTable.columnPickingTypeId:
                batchItem.pickingTypeId,
            BatchPackingConsolidateTable.columnState: batchItem.state,
            BatchPackingConsolidateTable.columnUserId: batchItem.userId,
            BatchPackingConsolidateTable.columnUserName: batchItem.userName,
            BatchPackingConsolidateTable.columnCantidadPedidos:
                batchItem.cantidadPedidos,
            BatchPackingConsolidateTable.columnZonaEntrega:
                batchItem.zonaEntrega,
            BatchPackingConsolidateTable.columnZonaEntregaTms:
                batchItem.zonaEntregaTms,
            BatchPackingConsolidateTable.columnStartTimePack:
                batchItem.startTimePack,
            BatchPackingConsolidateTable.columnEndTimePack:
                batchItem.endTimePack,
            BatchPackingConsolidateTable.columnIsSeparate: 0,
            //maneja_temperatura
            BatchPackingConsolidateTable.columnManejaTemperatura:
                batchItem.manejaTemperatura,
            //temperatura
            BatchPackingConsolidateTable.columnTemperatura:
                batchItem.temperatura,
            BatchPackingConsolidateTable.columnOrigins: batchItem.origins,
            BatchPackingConsolidateTable.columnCantidadTotalPedidos:
                batchItem.cantidadTotalPedidos,
            BatchPackingConsolidateTable.columnCantidadTotalProductos:
                batchItem.cantidadTotalProductos,
            BatchPackingConsolidateTable.columnUnidadesProductos:
                batchItem.unidadesProductos,
          };

          // Elimina si ya existe el registro con ese ID
          batch.delete(
            BatchPackingConsolidateTable.tableName,
            where: '${BatchPackingConsolidateTable.columnId} = ?',
            whereArgs: [batchItem.id],
          );

          // Inserta el nuevo registro (reemplaza si hay conflicto)
          batch.insert(
            BatchPackingConsolidateTable.tableName,
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
          await db.query(BatchPackingConsolidateTable.tableName);

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
          'UPDATE ${BatchPackingConsolidateTable.tableName} SET $field = ? WHERE ${BatchPackingConsolidateTable.columnId} = ?',
          [setValue, batchId]);

      debugPrint(
          "setFieldTableBatchPacking: $resUpdate, batchId: $batchId, field: $field, setValue: $setValue");
      return resUpdate;
    } catch (e) {
      debugPrint(
          "Error al actualizar el campo $field en tblbatchs_packing: $e");
      return null;
    }
  }

  //*metodo para eliminar un batch de packing por id
  Future<int?> deleteBatchPackingById(int batchId) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      final resDelete = await db.delete(
        BatchPackingConsolidateTable.tableName,
        where: '${BatchPackingConsolidateTable.columnId} = ?',
        whereArgs: [batchId],
      );
      debugPrint("deleteBatchPackingById: $resDelete, batchId: $batchId");
      return resDelete;
    } catch (e) {
      debugPrint("Error al eliminar el batch de packing con id $batchId: $e");
      return null;
    }
  }

  //metodo para eliminar todos los batchs de packing
  Future<int?> deleteAllBatchPacking() async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      final resDelete = await db.delete(
        BatchPackingConsolidateTable.tableName,
      );
      debugPrint("deleteAllBatchPacking: $resDelete");
      return resDelete;
    } catch (e) {
      debugPrint("Error al eliminar todos los batchs de packing: $e");
      return null;
    }
  }

  // Método para iniciar el cronómetro de un batch de picking
  Future<int?> startStopwatchBatch(int batchId, String date) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();

      // Actualiza el campo 'start_time_pick' con la fecha proporcionada
      final resUpdate = await db.rawUpdate(
          "UPDATE ${BatchPackingConsolidateTable.tableName} SET ${BatchPackingConsolidateTable.columnStartTimePack} = ? WHERE ${BatchPackingConsolidateTable.columnId} = ?",
          [date, batchId]);

      debugPrint("startStopwatchBatchPack: $resUpdate");
      return resUpdate;
    } catch (e) {
      debugPrint(
          "Error al iniciar el cronómetro para el batch en pack: $batchId: $e");
      return null;
    }
  }

  // Método para detener el cronómetro de un batch de picking
  Future<int?> stopStopwatchBatch(int batchId, String date) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();

      // Actualiza el campo 'end_time_pack' con la fecha proporcionada
      final resUpdate = await db.rawUpdate(
          "UPDATE ${BatchPackingConsolidateTable.tableName} SET ${BatchPackingConsolidateTable.columnEndTimePack} = ? WHERE ${BatchPackingConsolidateTable.columnId} = ?",
          [date, batchId]);

      debugPrint("stopStopwatchBatchPack: $resUpdate");
      return resUpdate;
    } catch (e) {
      debugPrint(
          "Error al detener el cronómetro para el batch en pack: $batchId: $e");
      return null;
    }
  }
}
