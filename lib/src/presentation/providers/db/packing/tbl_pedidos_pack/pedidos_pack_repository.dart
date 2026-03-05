// pedidos_packing_repository.dart

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/packing/tbl_pedidos_pack/pedidos_pack_table.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/packing_response_model.dart';

class PedidosPackingRepository {
  // Método para insertar o actualizar pedidos
  Future<void> insertPedidosBatchPacking(
      List<PedidoPacking> pedidosList, String type) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      // Inicia la transacción
      await db.transaction((txn) async {
        // Recorre la lista de pedidos
        for (var pedido in pedidosList) {
          // Verificar si el pedido ya existe
          final List<Map<String, dynamic>> existingPedido = await txn.query(
            PedidosPackingTable.tableName,
            where: '${PedidosPackingTable.columnId} = ?',
            whereArgs: [pedido.id],
          );

          if (existingPedido.isNotEmpty) {
            // Actualizar el pedido si ya existe
            await txn.update(
              PedidosPackingTable.tableName,
              {
                PedidosPackingTable.columnId: pedido.id,
                PedidosPackingTable.columnBatchId: pedido.batchId,
                PedidosPackingTable.columnName: pedido.name,
                PedidosPackingTable.columnReferencia: pedido.referencia ?? '',
                PedidosPackingTable.columnFecha: pedido.fecha.toString(),
                PedidosPackingTable.columnContacto: pedido.contacto,
                PedidosPackingTable.columnTipoOperacion:
                    pedido.tipoOperacion.toString(),
                PedidosPackingTable.columnCantidadProductos:
                    pedido.cantidadProductos,
                PedidosPackingTable.columnNumeroPaquetes: pedido.numeroPaquetes,
                PedidosPackingTable.columnContactoName: pedido.contactoName,
                PedidosPackingTable.columnIsZonaEntrega: pedido.zonaEntrega,
                PedidosPackingTable.columnIsZonaEntregaTms:
                    pedido.zonaEntregaTms,
                PedidosPackingTable.columnIsTerminate: 0,
                PedidosPackingTable.columnType: type,
              },
              where: '${PedidosPackingTable.columnId} = ?',
              whereArgs: [pedido.id],
            );
          } else {
            // Insertar el pedido si no existe
            await txn.insert(
              PedidosPackingTable.tableName,
              {
                PedidosPackingTable.columnId: pedido.id,
                PedidosPackingTable.columnBatchId: pedido.batchId,
                PedidosPackingTable.columnName: pedido.name,
                PedidosPackingTable.columnReferencia: pedido.referencia ?? '',
                PedidosPackingTable.columnFecha: pedido.fecha.toString(),
                PedidosPackingTable.columnContacto: pedido.contacto,
                PedidosPackingTable.columnTipoOperacion:
                    pedido.tipoOperacion.toString(),
                PedidosPackingTable.columnCantidadProductos:
                    pedido.cantidadProductos,
                PedidosPackingTable.columnNumeroPaquetes: pedido.numeroPaquetes,
                PedidosPackingTable.columnContactoName: pedido.contactoName,
                PedidosPackingTable.columnIsZonaEntrega: pedido.zonaEntrega,
                PedidosPackingTable.columnIsZonaEntregaTms:
                    pedido.zonaEntregaTms,
                PedidosPackingTable.columnIsTerminate: 0,
                PedidosPackingTable.columnType: type,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });

      debugPrint("Pedidos de packing insertados/actualizados con éxito.");
    } catch (e, s) {
      debugPrint("Error al insertar/actualizar pedidos: $e ==> $s");
    }
  }

// Obtener los pedidos de packing por batch_id

  // Obtener todos los pedidos de un batch específico
  Future<List<PedidoPacking>> getAllPedidosBatch(int batchId) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> maps = await db.query(
        PedidosPackingTable.tableName,
        where: '${PedidosPackingTable.columnBatchId} = ?',
        whereArgs: [batchId],
      );

      final List<PedidoPacking> pedidos = maps.map((map) {
        return PedidoPacking.fromMap(map);
      }).toList();

      return pedidos;
    } catch (e) {
      debugPrint("Error al obtener todos los pedidos del batch: $e");
      return [];
    }
  }

  //metodo para obtener todos los pedidos de packing
  Future<List<PedidoPacking>> getAllPedidosPacking() async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> maps = await db.query(
        PedidosPackingTable.tableName,
      );

      final List<PedidoPacking> pedidos = maps.map((map) {
        return PedidoPacking.fromMap(map);
      }).toList();

      return pedidos;
    } catch (e) {
      debugPrint("Error al obtener todos los pedidos de packing: $e");
      return [];
    }
  }

  // Método para actualizar un campo específico de un pedido en la tabla
  Future<int?> setFieldTablePedidosPacking(
      int batchId, int pedidoId, String field, dynamic setValue) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      // Realizar la actualización usando rawUpdate
      final resUpdate = await db.rawUpdate(
        'UPDATE ${PedidosPackingTable.tableName} SET $field = ? WHERE id = ? AND batch_id = ?',
        [setValue, pedidoId, batchId],
      );

      // Devolver la cantidad de filas afectadas
      debugPrint(
          "update setFieldTablePedidosPacking  ($field)  pedido $pedidoId batch $batchId => $resUpdate");
      return resUpdate;
    } catch (e) {
      debugPrint("Error al actualizar el campo $field: $e");
      return null;
    }
  }
}
