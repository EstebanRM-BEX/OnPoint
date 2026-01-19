// batch_picking_repository.dart

import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'batch_picking_table.dart'; // Importa el archivo de la tabla

class BatchPickingRepository {
  Future<void> insertAllBatches(
      List<BatchsModel> listOfBatchs, int userId, String type) async {
    final db = await DataBaseSqlite().getDatabaseInstance();

    await db.transaction((txn) async {
      final batch = txn.batch();

      for (var batchItem in listOfBatchs) {
        if (batchItem.id != null && batchItem.name != null) {
          final data = {
            BatchPickingTable.columnId: batchItem.id,
            BatchPickingTable.columnName: batchItem.name ?? '',
            BatchPickingTable.columnType: type,
            BatchPickingTable.columnScheduledDate:
                batchItem.scheduleddate.toString(),
            BatchPickingTable.columnPickingTypeId: batchItem.pickingTypeId,
            BatchPickingTable.columnMuelle: batchItem.muelle,
            BatchPickingTable.columnIdMuellePadre: batchItem.idMuellePadre,
            BatchPickingTable.columnBarcodeMuelle: batchItem.barcodeMuelle,
            BatchPickingTable.columnIdMuelle: batchItem.idMuelle,
            BatchPickingTable.columnState: batchItem.state,
            BatchPickingTable.columnUserId: userId,
            BatchPickingTable.columnUserName: batchItem.userName,
            BatchPickingTable.columnIsWave: batchItem.isWave.toString(),
            BatchPickingTable.columnCountItems: batchItem.countItems,
            BatchPickingTable.columnTotalQuantityItems:
                batchItem.totalQuantityItems.toInt(),
            BatchPickingTable.columnOrderBy: batchItem.orderBy,
            BatchPickingTable.columnOrderPicking: batchItem.orderPicking,
            BatchPickingTable.columnIndexList: 0,
            BatchPickingTable.columnStartTimePick: batchItem.startTimePick,
            BatchPickingTable.columnEndTimePick: batchItem.endTimePick,
            BatchPickingTable.columnZonaEntrega: batchItem.zonaEntrega,
          };

          // Elimina si existe (por ID), y luego inserta
          batch.delete(
            BatchPickingTable.tableName,
            where: '${BatchPickingTable.columnId} = ?',
            whereArgs: [batchItem.id],
          );

          batch.insert(
            BatchPickingTable.tableName,
            data,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // Ejecutar todas las operaciones en lote
      await batch.commit(noResult: true);
    });
  }

  // Método para obtener un batch por su ID
  Future<BatchsModel?> getBatchById(int batchId, String type) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      // Realiza la consulta a la tabla tblbatchs
      final List<Map<String, dynamic>> maps = await db.query(
        BatchPickingTable.tableName,
        where: '${BatchPickingTable.columnId} = ? AND ${BatchPickingTable.columnType} = ?',
        whereArgs: [batchId, type],
      );

      // Si se encontró un registro, lo mapea a un objeto BatchsModel
      if (maps.isNotEmpty) {
        return BatchsModel.fromMap(maps.first);
      }

      // Si no se encontró ningún registro, devuelve null
      return null;
    } catch (e) {
      print("Error al obtener el batch por ID: $e");
      return null; // Devuelve null en caso de error
    }
  }

//metodo para obtener todos los batchs de un usuario
  Future<List<BatchsModel>> getAllBatchs(int userId, String type) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();

      // Consulta optimizada: solo columnas necesarias
      final List<Map<String, dynamic>> maps = await db.query(
        BatchPickingTable.tableName,
        columns: [
          BatchPickingTable.columnId,
          BatchPickingTable.columnName,
          BatchPickingTable.columnType,
          BatchPickingTable.columnScheduledDate,
          BatchPickingTable.columnPickingTypeId,
          BatchPickingTable.columnMuelle,
          BatchPickingTable.columnIdMuellePadre,
          BatchPickingTable.columnBarcodeMuelle,
          BatchPickingTable.columnIdMuelle,
          BatchPickingTable.columnState,
          BatchPickingTable.columnUserId,
          BatchPickingTable.columnUserName,
          BatchPickingTable.columnIsWave,
          BatchPickingTable.columnCountItems,
          BatchPickingTable.columnTotalQuantityItems,
          BatchPickingTable.columnOrderBy,
          BatchPickingTable.columnOrderPicking,
          BatchPickingTable.columnIndexList,
          BatchPickingTable.columnStartTimePick,
          BatchPickingTable.columnEndTimePick,
          BatchPickingTable.columnZonaEntrega,
          BatchPickingTable.columnIsSeparate,
        ],
        where: '${BatchPickingTable.columnUserId} = ? AND ${BatchPickingTable.columnType} = ?',
        whereArgs: [userId, type],
      );

      // Mapeo directo
      return maps.map((map) => BatchsModel.fromMap(map)).toList();
    } catch (e, s) {
      print("Error getBatchsByUserId: $e => $s");
      return [];
    }
  }

  Future<List<BatchsModel>> getFilteredBatchs(int userId) async {
    final db = await DataBaseSqlite().getDatabaseInstance();

    final maps = await db.query(
      BatchPickingTable.tableName,
      where:
          '${BatchPickingTable.columnUserId} = ? AND ${BatchPickingTable.columnIsSeparate} IS NULL',
      whereArgs: [userId],
    );

    return maps.map((map) => BatchsModel.fromMap(map)).toList();
  }

  // Método para actualizar un campo específico de un batch de picking
  Future<int?> setFieldTableBatch(
      int batchId, String field, dynamic setValue, String type) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();

      // Usamos rawUpdate para actualizar el campo específico
      final resUpdate = await db.rawUpdate(
          'UPDATE ${BatchPickingTable.tableName} SET $field = ? WHERE ${BatchPickingTable.columnId} = ? AND ${BatchPickingTable.columnType} = ?',
          [setValue, batchId, type]);

      return resUpdate;
    } catch (e) {
      print("Error al actualizar el campo $field en tblbatchs: $e");
      return null;
    }
  }

// Método para obtener el valor de un campo específico de un batch de picking
  Future<String> getFieldTableBatch(int batchId, String field, String type) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();

      // Ejecutar consulta raw para obtener el valor del campo
      final res = await db.rawQuery('''
      // SELECT $field FROM ${BatchPickingTable.tableName} WHERE ${BatchPickingTable.columnId} = ? AND ${BatchPickingTable.columnType} = ? LIMIT 1
    ''', [batchId, type]);

      if (res.isNotEmpty) {
        // Devuelve el valor del campo como String
        return res[0][field].toString();
      }
      return "";
    } catch (e) {
      print("Error al obtener el campo $field de tblbatchs: $e");
      return "";
    }
  }

  // Método para iniciar el cronómetro de un batch de picking
  Future<int?> startStopwatchBatch(int batchId, String date, String type) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();

      // Actualiza el campo 'start_time_pick' con la fecha proporcionada
      final resUpdate = await db.rawUpdate(
          "UPDATE ${BatchPickingTable.tableName} SET ${BatchPickingTable.columnStartTimePick} = ? WHERE ${BatchPickingTable.columnId} = ? AND ${BatchPickingTable.columnType} = ?",
          [date, batchId, type]);

      print("startStopwatchBatch: $resUpdate");
      return resUpdate;
    } catch (e) {
      print("Error al iniciar el cronómetro para el batch $batchId: $e");
      return null;
    }
  }

  // Método para finalizar el cronómetro de un batch de picking
  Future<int?> endStopwatchBatch(int batchId, String date, String type) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();

      // Actualiza el campo 'end_time_pick' con la fecha proporcionada
      final resUpdate = await db.rawUpdate(
          "UPDATE ${BatchPickingTable.tableName} SET ${BatchPickingTable.columnEndTimePick} = ? WHERE ${BatchPickingTable.columnId} = ? AND ${BatchPickingTable.columnType} = ?",
          [date, batchId, type]);

      print("endStopwatchBatch: $resUpdate");
      return resUpdate;
    } catch (e) {
      print("Error al finalizar el cronómetro para el batch $batchId: $e");
      return null;
    }
  }
}
