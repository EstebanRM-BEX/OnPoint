import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/recepcion/entradas/tbl_entradas_batch/entrada_batch_table.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/recepcion_response_batch_model.dart';

class EntradaBatchRepository {
  Future<void> insertEntradaBatch(List<ReceptionBatch> entradas) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();

      await db.transaction((txn) async {
        final batch = txn.batch();

        // Obtener IDs existentes correctamente
        final ids = entradas.map((e) => e.id ?? 0).toList();
        final existing = await txn.query(
          EntradaBatchTable.tableName,
          columns: [EntradaBatchTable.columnId],
          where:
              '${EntradaBatchTable.columnId} IN (${List.filled(ids.length, '?').join(',')})',
          whereArgs: ids,
        );

        final existingIds =
            existing.map((e) => e[EntradaBatchTable.columnId] as int).toSet();

        for (final entrada in entradas) {
          final data = {
            EntradaBatchTable.columnId: entrada.id ?? 0,
            EntradaBatchTable.columnName: entrada.name ?? "",
            EntradaBatchTable.columnFechaCreacion: entrada.fechaCreacion ?? "",
            EntradaBatchTable.columnProveedorId: entrada.proveedorId ?? 0,
            EntradaBatchTable.columnProveedor: entrada.proveedor ?? "",
            EntradaBatchTable.columnLocationDestId: entrada.locationDestId ?? 0,
            EntradaBatchTable.columnLocationDestName:
                entrada.locationDestName ?? "",
            EntradaBatchTable.columnPurchaseOrderId:
                entrada.purchaseOrderId ?? 0,
            EntradaBatchTable.columnPurchaseOrderName:
                entrada.purchaseOrderName ?? "",
            EntradaBatchTable.columnNumeroLineas: entrada.numeroLineas ?? 0,
            EntradaBatchTable.columnNumeroItems: entrada.numeroItems ?? 0,
            EntradaBatchTable.columnState: entrada.state ?? "",
            EntradaBatchTable.columnWarehouseName: entrada.warehouseName ?? "",
            EntradaBatchTable.columnLocationId: entrada.locationId ?? 0,
            EntradaBatchTable.columnLocationName: entrada.locationName ?? "",
            EntradaBatchTable.columnResponsableId: entrada.responsableId ?? 0,
            EntradaBatchTable.columnResponsable: entrada.responsable ?? "",
            EntradaBatchTable.columnPickingType: entrada.pickingType ?? '',
            EntradaBatchTable.columnDateStart: entrada.startTimeReception ?? "",
            EntradaBatchTable.columnDateFinish: entrada.endTimeReception ?? '',
            EntradaBatchTable.columnShowCheckAvailability:
                entrada.showCheckAvailability ?? 0,
            EntradaBatchTable.columnZonaEntrega: entrada.zonaEntrega ?? "",
            EntradaBatchTable.columnOrderBy: entrada.orderBy ?? "",
            EntradaBatchTable.columnOrderPicking: entrada.orderPicking ?? "",
            //propietario
            EntradaBatchTable.columnPropietario: entrada.propietario ?? "",
          };

          if (existingIds.contains(entrada.id)) {
            batch.update(
              EntradaBatchTable.tableName,
              data,
              where: '${EntradaBatchTable.columnId} = ?',
              whereArgs: [entrada.id],
            );
          } else {
            batch.insert(
              EntradaBatchTable.tableName,
              data,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        await batch.commit(noResult: true); // ⚡ para mejor rendimiento
      });

      debugPrint('✅ Entradas por batch insertadas correctamente');
    } catch (e, s) {
      debugPrint('❌ Error en insertEntradaBatch: $e -> $s');
    }
  }

  Future<List<ReceptionBatch>> getAllEntradaBatch() async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> result = await db.query(
        EntradaBatchTable.tableName,
        orderBy: '${EntradaBatchTable.columnFechaCreacion} DESC',
      );

      return result.map((e) => ReceptionBatch.fromMap(e)).toList();
    } catch (e, s) {
      debugPrint('❌ Error al obtener recepciones por batch: $e -> $s');
      return [];
    }
  }

  //metodo para obtener una entrada por id
  Future<ReceptionBatch?> getEntradaById(int id) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> entradas = await db.query(
        EntradaBatchTable.tableName,
        where: '${EntradaBatchTable.columnId} = ?',
        whereArgs: [id],
      );
      if (entradas.isNotEmpty) {
        return ReceptionBatch.fromMap(entradas.first);
      }
      return null;
    } catch (e, s) {
      debugPrint('Error en getEntradaById: $e ->$s');
      return null;
    }
  }

  // Método: Actualizar un campo específico en la tabla productos_pedidos
  Future<int?> setFieldTableEntradaBatch(
    int idEntrada,
    String field,
    dynamic setValue,
  ) async {
    Database db = await DataBaseSqlite().getDatabaseInstance();

    final resUpdate = await db.rawUpdate(
        'UPDATE ${EntradaBatchTable.tableName} SET $field = ? WHERE ${EntradaBatchTable.columnId} = ?',
        [
          setValue,
          idEntrada,
        ]);

    debugPrint(
        "update TableEntrada (idEntrada ----($idEntrada)  ) -------($field): $resUpdate");

    return resUpdate;
  }
}
