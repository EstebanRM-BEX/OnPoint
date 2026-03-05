import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/conteo/tbl_ordenes/orden_table.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/conteo/models/conteo_response_model.dart';

class OrdenConteoRepository {
  // Método para insertar/actualizar múltiples órdenes de conteo
  Future<void> insertOrUpdateOrdenes(List<DatumConteo> ordenes) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();

      await db.transaction((txn) async {
        final Batch batch = txn.batch();

        final ordenIds = ordenes.map((e) => e.id ?? 0).toList();

        // Obtener órdenes existentes en una sola consulta
        final List<Map<String, dynamic>> existing = await txn.query(
          OrdenTable.tableName,
          columns: [OrdenTable.columnId],
          where:
              '${OrdenTable.columnId} IN (${List.filled(ordenIds.length, '?').join(',')})',
          whereArgs: ordenIds,
        );

        final Set<int> existingIds =
            existing.map((e) => e[OrdenTable.columnId] as int).toSet();

        for (final orden in ordenes) {
          final id = orden.id ?? 0;
          final data = {
            OrdenTable.columnId: id,
            OrdenTable.columnName: orden.name ?? "",
            OrdenTable.columnState: orden.state ?? "",
            OrdenTable.columnWarehouseId: orden.warehouseId ?? 0,
            OrdenTable.columnWarehouseName: orden.warehouseName ?? "",
            OrdenTable.columnResponsableId: orden.responsableId ?? 0,
            OrdenTable.columnResponsableName: orden.responsableName ?? "",
            OrdenTable.columnCreateDate: orden.createDate.toString() ?? "",
            OrdenTable.columnDateCount: orden.dateCount.toString() ?? "",
            OrdenTable.columnMostrarCantidad:
                orden.mostrarCantidad == true ? 1 : 0,
            OrdenTable.columnCountType: orden.countType ?? "",
            OrdenTable.columnNumberCount: orden.numberCount ?? "",
            OrdenTable.columnNumeroLineas: orden.numeroLineas ?? 0,
            OrdenTable.columnNumeroItemsContados:
                orden.numeroItemsContados ?? 0,
            OrdenTable.columnFilterType: orden.filterType ?? "",
            OrdenTable.columnEnableAllLocations:
                orden.enableAllLocations == true ? 1 : 0,
            OrdenTable.columnEnableAllProducts:
                orden.enableAllProducts == true ? 1 : 0,
            OrdenTable.columnIsSelected: orden.isSelected == true ? 1 : 0,
            OrdenTable.columnIsStarted: orden.isStarted == true ? 1 : 0,
            OrdenTable.columnIsFinished: orden.isFinished == true ? 1 : 0,
            OrdenTable.columnDateStart: orden.startTimeOrden ?? "",
            OrdenTable.columnDateFinish: orden.endTimeOrden ?? "",
            OrdenTable.columnIsDoneItem: orden.isDoneItem == true ? 1 : 0,
            OrdenTable.columnObservationGeneral: orden.observationGeneral ?? "",
          };

          if (existingIds.contains(id)) {
            batch.update(
              OrdenTable.tableName,
              data,
              where: '${OrdenTable.columnId} = ?',
              whereArgs: [id],
            );
          } else {
            batch.insert(
              OrdenTable.tableName,
              data,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        await batch.commit(noResult: true);
      });

      debugPrint('Órdenes de conteo insertadas/actualizadas correctamente');
    } catch (e, s) {
      debugPrint('Error en insertOrUpdateOrdenes: $e -> $s');
      rethrow;
    }
  }

  // Método para obtener todas las órdenes de conteo
  Future<List<DatumConteo>> getAllOrdenes() async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> maps =
          await db.query(OrdenTable.tableName);

      return List.generate(maps.length, (i) {
        return DatumConteo.fromMap(maps[i]);
      });
    } catch (e, s) {
      debugPrint('Error en getAllOrdenes: $e -> $s');
      rethrow;
    }
  }

  // Método para obtener una orden específica por ID
  Future<DatumConteo?> getOrdenById(int id) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> maps = await db.query(
        OrdenTable.tableName,
        where: '${OrdenTable.columnId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return DatumConteo.fromMap(maps.first);
      }
      return null;
    } catch (e, s) {
      debugPrint('Error en getOrdenById: $e -> $s');
      rethrow;
    }
  }

  // Método para eliminar una orden
  Future<int> deleteOrden(int id) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      return await db.delete(
        OrdenTable.tableName,
        where: '${OrdenTable.columnId} = ?',
        whereArgs: [id],
      );
    } catch (e, s) {
      debugPrint('Error en deleteOrden: $e -> $s');
      rethrow;
    }
  }

  // Método para marcar una orden como seleccionada
  Future<void> markAsSelected(int id, bool isSelected) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      await db.update(
        OrdenTable.tableName,
        {OrdenTable.columnIsSelected: isSelected ? 1 : 0},
        where: '${OrdenTable.columnId} = ?',
        whereArgs: [id],
      );
    } catch (e, s) {
      debugPrint('Error en markAsSelected: $e -> $s');
      rethrow;
    }
  }

  // Método: Actualizar un campo específico en la tabla OrdenTable

  Future<void> updateField(int id, String fieldName, dynamic value) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      await db.update(
        OrdenTable.tableName,
        {fieldName: value},
        where: '${OrdenTable.columnId} = ?',
        whereArgs: [id],
      );
      debugPrint(
          'Campo $fieldName actualizado a $value para la orden con ID $id');
    } catch (e, s) {
      debugPrint('Error en updateField: $e -> $s');
      rethrow;
    }
  }

  //metodo para actualizar la cantidad de numero_items_contados de una orden en +1
  Future<void> incrementNumeroItemsContados(int id) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      await db.rawUpdate('''
        UPDATE ${OrdenTable.tableName}
        SET ${OrdenTable.columnNumeroItemsContados} = ${OrdenTable.columnNumeroItemsContados} + 1
        WHERE ${OrdenTable.columnId} = ?
      ''', [id]);
      debugPrint('Incrementado numero_items_contados para la orden con ID $id');
    } catch (e, s) {
      debugPrint('Error en incrementNumeroItemsContados: $e -> $s');
      rethrow;
    }
  }

  //numero_lineas de una orden en +1
  Future<void> incrementNumeroLineas(int id) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      await db.rawUpdate('''
        UPDATE ${OrdenTable.tableName}
        SET ${OrdenTable.columnNumeroLineas} = ${OrdenTable.columnNumeroLineas} + 1
        WHERE ${OrdenTable.columnId} = ?
      ''', [id]);
      debugPrint('Incrementado numero_lineas para la orden con ID $id');
    } catch (e, s) {
      debugPrint('Error en incrementNumeroLineas: $e -> $s');
      rethrow;
    }
  }
}
