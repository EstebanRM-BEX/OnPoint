import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/recepcion/entradas/tbl_entradas/entradas_table.dart';

import 'package:wms_app/src/presentation/views/recepcion/models/recepcion_response_model.dart';

class EntradasRepository {
  //metodo para insertar todas las entradas
  Future<void> insertEntrada(List<ResultEntrada> entradas, String type) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();

      await db.transaction((txn) async {
        final Batch batch = txn.batch();

        final entradaIds = entradas.map((e) => e.id ?? 0).toList();

        // Obtener entradas existentes en una sola consulta
        final List<Map<String, dynamic>> existing = await txn.query(
          EntradasRepeccionTable.tableName,
          columns: [EntradasRepeccionTable.columnId],
          where:
              '${EntradasRepeccionTable.columnId} IN (${List.filled(entradaIds.length, '?').join(',')})',
          whereArgs: entradaIds,
        );

        final Set<int> existingIds = existing
            .map((e) => e[EntradasRepeccionTable.columnId] as int)
            .toSet();

        for (final entrada in entradas) {
          final id = entrada.id ?? 0;
          final data = {
            EntradasRepeccionTable.columnId: id,
            EntradasRepeccionTable.columnName: entrada.name ?? "",
            EntradasRepeccionTable.columnFechaCreacion:
                entrada.fechaCreacion ?? "",
            EntradasRepeccionTable.columnProveedorId: entrada.proveedorId ?? 0,
            EntradasRepeccionTable.columnProveedor: entrada.proveedor ?? "",
            EntradasRepeccionTable.columnLocationDestId:
                entrada.locationDestId ?? 0,
            EntradasRepeccionTable.columnLocationDestName:
                entrada.locationDestName ?? "",
            EntradasRepeccionTable.columnPurchaseOrderId:
                entrada.purchaseOrderId ?? 0,
            EntradasRepeccionTable.columnPurchaseOrderName:
                entrada.purchaseOrderName ?? "",
            EntradasRepeccionTable.columnNumeroEntrada:
                entrada.numeroEntrada ?? 0,
            EntradasRepeccionTable.columnPesoTotal: entrada.pesoTotal ?? 0,
            EntradasRepeccionTable.columnNumeroLineas:
                entrada.numeroLineas ?? 0,
            EntradasRepeccionTable.columnNumeroItems: entrada.numeroItems ?? 0,
            EntradasRepeccionTable.columnState: entrada.state ?? "",
            EntradasRepeccionTable.columnOrigin: entrada.origin ?? "",
            EntradasRepeccionTable.columnPriority: entrada.priority ?? "",
            EntradasRepeccionTable.columnWarehouseId: entrada.warehouseId ?? 0,
            EntradasRepeccionTable.columnWarehouseName:
                entrada.warehouseName ?? "",
            EntradasRepeccionTable.columnLocationId: entrada.locationId ?? 0,
            EntradasRepeccionTable.columnLocationName:
                entrada.locationName ?? "",
            EntradasRepeccionTable.columnResponsableId:
                entrada.responsableId ?? 0,
            EntradasRepeccionTable.columnResponsable: entrada.responsable ?? "",
            EntradasRepeccionTable.columnPickingType: entrada.pickingType ?? '',
            EntradasRepeccionTable.columnDateStart:
                entrada.startTimeReception ?? "",
            EntradasRepeccionTable.columnDateFinish:
                entrada.endTimeReception ?? '',
            EntradasRepeccionTable.columnBackorderId: entrada.backorderId ?? 0,
            EntradasRepeccionTable.columnBackorderName:
                entrada.backorderName ?? "",
            EntradasRepeccionTable.columnType: type,
            //maneja_temperatura
            EntradasRepeccionTable.columnManejaTemperatura:
                entrada.manejaTemperatura ?? 0,
            //temperatura
            EntradasRepeccionTable.columnTemperatura: entrada.temperatura ?? 0,
            //propietario
            EntradasRepeccionTable.columnPropietario: entrada.propietario ?? "",
            //create_backorder
            EntradasRepeccionTable.columnCreateBackorder:
                entrada.createBackorder ?? "",
          };

          if (existingIds.contains(id)) {
            batch.update(
              EntradasRepeccionTable.tableName,
              data,
              where: '${EntradasRepeccionTable.columnId} = ?',
              whereArgs: [id],
            );
          } else {
            batch.insert(
              EntradasRepeccionTable.tableName,
              data,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        await batch.commit(noResult: true);
      });

      debugPrint('Entradas insertadas correctamente');
    } catch (e, s) {
      debugPrint('Error en insertEntrada: $e -> $s');
    }
  }

  //metodo para obtener todas las entradas
  Future<List<ResultEntrada>> getAllEntradas(String type) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> entradas = await db.query(
        EntradasRepeccionTable.tableName,
        where: '${EntradasRepeccionTable.columnType} = ?',
        whereArgs: [type],
      );
      return entradas.map((e) => ResultEntrada.fromMap(e)).toList();
    } catch (e, s) {
      debugPrint('Error en getAllEntradas: $e ->$s');
      return [];
    }
  }

  //metodo para obtener una entrada por id
  Future<ResultEntrada?> getEntradaById(int id) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> entradas = await db.query(
        EntradasRepeccionTable.tableName,
        where: '${EntradasRepeccionTable.columnId} = ?',
        whereArgs: [id],
      );
      if (entradas.isNotEmpty) {
        return ResultEntrada.fromMap(entradas.first);
      }
      return null;
    } catch (e, s) {
      debugPrint('Error en getEntradaById: $e ->$s');
      return null;
    }
  }

  // Método: Actualizar un campo específico en la tabla productos_pedidos
  Future<int?> setFieldTableEntrada(
    int idEntrada,
    String field,
    dynamic setValue,
  ) async {
    Database db = await DataBaseSqlite().getDatabaseInstance();

    final resUpdate = await db.rawUpdate(
        'UPDATE ${EntradasRepeccionTable.tableName} SET $field = ? WHERE ${EntradasRepeccionTable.columnId} = ?',
        [
          setValue,
          idEntrada,
        ]);

    debugPrint(
        "update TableEntrada (idEntrada ----($idEntrada)  ) -------($field): $resUpdate");

    return resUpdate;
  }
}
