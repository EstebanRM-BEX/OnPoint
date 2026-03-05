import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/packing/packing_pedido/tbl_packing_pedido/packing_pedido_table.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/response_packing_pedido_model.dart'; // Asegúrate que esta ruta sea correcta

/// Repositorio para la tabla tbl_pedido_pack, gestionando las operaciones CRUD.
class PedidoPackRepository {
  final DataBaseSqlite _databaseProvider;

  // Constructor para inyectar la dependencia de la base de datos.
  // Esto facilita las pruebas y la gestión de la conexión.
  PedidoPackRepository(this._databaseProvider);

  /// Inserta o actualiza una lista de pedidos en la tabla tbl_pedido_pack.
  /// Utiliza transacciones y un batch para optimizar el rendimiento.

  Future<void> insertPedidosPack(List<PedidoPackingResult> pedidosList) async {
    if (pedidosList.isEmpty) {
      return;
    }
    try {
      final Database db = await _databaseProvider.getDatabaseInstance();

      await db.transaction((txn) async {
        final batch = txn.batch();

        // 1. Obtener todos los IDs de los pedidos que intentamos insertar/actualizar.
        // Se utiliza un Set para asegurar IDs únicos y una lista para la cláusula IN.
        final Set<int> pedidoIdsToProcess = pedidosList
            .where((p) => p.id != null) // Solo procesar pedidos con ID válido
            .map((p) => p.id!)
            .toSet();

        if (pedidoIdsToProcess.isEmpty) {
          // Si todos los pedidos en la lista no tienen ID, significa que todos serán INSERTs.
          // En este caso, podemos usar el `conflictAlgorithm: ConflictAlgorithm.abort` si no quieres autoincrement.
          // O `ConflictAlgorithm.ignore` si ya existe y no quieres actualizar.
          for (final pedido in pedidosList) {
            final Map<String, dynamic>? dataToInsert = _mapPedidoToDb(pedido);
            if (dataToInsert != null) {
              batch.insert(
                PedidoPackTable.tableName,
                dataToInsert,
                conflictAlgorithm: ConflictAlgorithm
                    .abort, // Aborta si hay conflicto sin un ID definido
              );
            }
          }
        } else {
          // 2. Consultar la base de datos para ver cuáles de esos IDs ya existen.
          // Esto se hace en una sola consulta para mayor eficiencia.
          final List<Map<String, dynamic>> existingRows = await txn.query(
            PedidoPackTable.tableName,
            columns: [PedidoPackTable.columnId],
            where:
                '${PedidoPackTable.columnId} IN (${List.filled(pedidoIdsToProcess.length, '?').join(',')})',
            whereArgs: pedidoIdsToProcess.toList(),
          );

          // 3. Crear un Set de IDs existentes para búsquedas rápidas.
          final Set<int> existingPedidoIds = existingRows
              .map((row) => row[PedidoPackTable.columnId] as int)
              .toSet();

          // 4. Recorrer la lista de pedidos para determinar si INSERT o UPDATE.
          for (final pedido in pedidosList) {
            final Map<String, dynamic>? dataToProcess = _mapPedidoToDb(pedido);

            if (dataToProcess != null) {
              if (pedido.id != null && existingPedidoIds.contains(pedido.id)) {
                // El pedido ya existe, se realiza un UPDATE.
                batch.update(
                  PedidoPackTable.tableName,
                  dataToProcess,
                  where: '${PedidoPackTable.columnId} = ?',
                  whereArgs: [pedido.id],
                );
              } else {
                // El pedido no existe o no tiene ID, se realiza un INSERT.
                // Aquí usamos REPLACE porque si un pedido sin ID tiene un conflicto en otra columna (ej. unique constraint), lo reemplazará.
                // Si 'id' es PRIMARY KEY AUTOINCREMENT, no deberías preocuparte por conflictos aquí si 'id' es null.
                batch.insert(
                  PedidoPackTable.tableName,
                  dataToProcess,
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
            } else {
              debugPrint(
                  "Advertencia: No se pudo mapear el pedido con ID ${pedido.id ?? 'N/A'} para inserción/actualización. Saltando.");
            }
          }
        }
        // 5. Ejecutar todas las operaciones en el batch.
        await batch.commit(noResult: true);
      });
      debugPrint("Pedidos de packing insertados/actualizados con éxito.");
    } catch (e, s) {
      debugPrint(
          "Error al insertar/actualizar pedidos en tbl_pedido_pack: $e\n$s");
      rethrow;
    }
  }

  /// Método privado para mapear un objeto PedidoPackingResult a un Map compatible con la DB.
  /// Se encarga de la transformación de tipos y el filtrado de datos no válidos.
  Map<String, dynamic>? _mapPedidoToDb(PedidoPackingResult pedido) {
    try {
      final Map<String, dynamic> data = {
        PedidoPackTable.columnId: pedido.id,
        PedidoPackTable.columnBatchId: pedido.batchId,
        PedidoPackTable.columnName: pedido.name,
        PedidoPackTable.columnObservacion: pedido.observacion,
        PedidoPackTable.columnFechaCreacion:
            pedido.fechaCreacion?.toIso8601String(),
        PedidoPackTable.columnLocationId: pedido.locationId,
        PedidoPackTable.columnLocationName:
            pedido.locationName?.toString().split('.').last,
        PedidoPackTable.columnLocationBarcode:
            pedido.locationBarcode?.toString().split('.').last,
        PedidoPackTable.columnLocationDestId: pedido.locationDestId,
        PedidoPackTable.columnLocationDestName:
            pedido.locationDestName?.toString().split('.').last,
        PedidoPackTable.columnLocationDestBarcode: pedido.locationDestBarcode,
        PedidoPackTable.columnProveedor: pedido.proveedor,
        PedidoPackTable.columnNumeroTransferencia: pedido.numeroTransferencia,
        PedidoPackTable.columnPesoTotal: pedido.pesoTotal,
        PedidoPackTable.columnNumeroLineas: pedido.numeroLineas,
        PedidoPackTable.columnNumeroItems: pedido.numeroItems is int ||
                pedido.numeroItems is double
            ? (pedido.numeroItems as num)
                .toInt() // Convertir a int si es número
            : null, // Si no es número, se inserta null. ¡AJUSTA ESTO A TU LÓGICA!
        PedidoPackTable.columnState: pedido.state,
        PedidoPackTable.columnReferencia: pedido.referencia,
        PedidoPackTable.columnContacto: pedido.contacto,
        PedidoPackTable.columnContactoName: pedido.contactoName,
        PedidoPackTable.columnCantidadProductos: pedido.cantidadProductos,
        PedidoPackTable.columnCantidadProductosTotal:
            pedido.cantidadProductosTotal,
        PedidoPackTable.columnPriority: pedido.priority,
        PedidoPackTable.columnWarehouseId: pedido.warehouseId,
        PedidoPackTable.columnWarehouseName: pedido.warehouseName,
        PedidoPackTable.columnResponsableId: pedido.responsableId,
        PedidoPackTable.columnResponsable: pedido.responsable,
        PedidoPackTable.columnPickingType: pedido.pickingType,
        PedidoPackTable.columnStartTimeTransfer: pedido.startTimeTransfer,
        PedidoPackTable.columnEndTimeTransfer: pedido.endTimeTransfer,
        PedidoPackTable.columnBackorderId: pedido.backorderId,
        PedidoPackTable.columnBackorderName: pedido.backorderName,
        PedidoPackTable.columnShowCheckAvailability:
            pedido.showCheckAvailability == true ? 1 : 0,
        PedidoPackTable.columnOrderTms: pedido.orderTms,
        PedidoPackTable.columnZonaEntregaTms: pedido.zonaEntregaTms,
        PedidoPackTable.columnZonaEntrega: pedido.zonaEntrega,
        PedidoPackTable.columnNumeroPaquetes: pedido.numeroPaquetes,
        PedidoPackTable.columnIsTerminate: pedido.isTerminate == true ? 1 : 0,
        PedidoPackTable.columnIsSelected: pedido.isSelected == true ? 1 : 0,
        PedidoPackTable.columnIsStarted: pedido.isStarted == true ? 1 : 0,
        PedidoPackTable.columnCreateBackorder: pedido.createBackorder ?? '',
      };

      // Eliminar cualquier entrada donde el valor sea null, si la columna no acepta nulls.
      // Si la columna acepta nulls, esta línea puede no ser estrictamente necesaria,
      // pero es una buena práctica para asegurar que no se envían claves con valores nulos si no se desean.
      data.removeWhere((key, value) => value == null);

      return data;
    } catch (e, s) {
      debugPrint(
          "Error al mapear PedidoPackingResult a DB Map para Pedido ID ${pedido.id ?? 'N/A'}: $e\n$s");
      return null; // Retorna null si hay un error en el mapeo de un pedido específico.
    }
  }

  /// Obtiene todos los pedidos de la tabla tbl_pedido_pack.
  /// Retorna una lista de objetos PedidoPack.
  Future<List<PedidoPackingResult>> getAllPedidosPack() async {
    try {
      final Database db = await _databaseProvider.getDatabaseInstance();
      // Realiza la consulta a la base de datos para obtener todos los registros.
      // Opcional: ordenar los resultados para una consistencia visual.
      final List<Map<String, dynamic>> maps = await db.query(
        PedidoPackTable.tableName,
        orderBy:
            '${PedidoPackTable.columnFechaCreacion} DESC', // Ordenar por fecha de creación descendente
      );

      // Mapea cada Map de la base de datos a un objeto PedidoPackingResult.
      // La robustez del mapeo recae en la implementación de PedidoPackingResult.fromMap.
      return List.generate(maps.length, (i) {
        // Agrega un print para depurar el map que llega de la DB si el error persiste.
        // debugPrint('DEBUG: getAllPedidosPack - Map from DB: ${maps[i]}');
        return PedidoPackingResult.fromMap(maps[i]);
      });
    } catch (e, s) {
      // Captura y registra cualquier error durante la obtención o mapeo de los pedidos.
      debugPrint(
          "Error al obtener todos los pedidos de tbl_pedido_pack: $e\n$s");
      // Retorna una lista vacía para que la aplicación pueda continuar sin crashear.
      return [];
    }
  }

  /// Obtiene un pedido específico por su ID.
  Future<PedidoPackingResult?> getPedidoPackById(int id) async {
    try {
      final Database db = await _databaseProvider.getDatabaseInstance();
      final List<Map<String, dynamic>> maps = await db.query(
        PedidoPackTable.tableName,
        where: '${PedidoPackTable.columnId} = ?',
        whereArgs: [id],
        limit: 1, // Solo necesitamos un resultado
      );

      if (maps.isNotEmpty) {
        return PedidoPackingResult.fromMap(maps.first);
      }
      return null; // Retorna null si no se encuentra el pedido
    } catch (e, s) {
      debugPrint(
          "Error al obtener pedido con ID $id de tbl_pedido_pack: $e\n$s");
      return null;
    }
  }

  /// Actualiza un campo específico de un pedido en la tabla tbl_pedido_pack.
  /// Retorna la cantidad de filas afectadas.
  Future<int> updatePedidoPackField(
      int pedidoId, String fieldName, dynamic value) async {
    try {
      final Database db = await _databaseProvider.getDatabaseInstance();
      final int rowsAffected = await db.update(
        PedidoPackTable.tableName,
        {fieldName: value},
        where: '${PedidoPackTable.columnId} = ?',
        whereArgs: [pedidoId],
      );
      debugPrint(
          "Campo '$fieldName' del pedido $pedidoId actualizado. Filas afectadas: $rowsAffected");
      return rowsAffected;
    } catch (e, s) {
      debugPrint(
          "Error al actualizar el campo '$fieldName' del pedido $pedidoId: $e\n$s");
      return 0; // Retorna 0 filas afectadas en caso de error
    }
  }

  /// Elimina un pedido de la tabla tbl_pedido_pack por su ID.
  /// Retorna la cantidad de filas eliminadas.
  Future<int> deletePedidoPack(int id) async {
    try {
      final Database db = await _databaseProvider.getDatabaseInstance();
      final int rowsAffected = await db.delete(
        PedidoPackTable.tableName,
        where: '${PedidoPackTable.columnId} = ?',
        whereArgs: [id],
      );
      debugPrint("Pedido con ID $id eliminado. Filas afectadas: $rowsAffected");
      return rowsAffected;
    } catch (e, s) {
      debugPrint(
          "Error al eliminar pedido con ID $id de tbl_pedido_pack: $e\n$s");
      return 0;
    }
  }

  /// Elimina todos los pedidos de la tabla tbl_pedido_pack.
  Future<int> deleteAllPedidosPack() async {
    try {
      final Database db = await _databaseProvider.getDatabaseInstance();
      final int rowsAffected = await db.delete(PedidoPackTable.tableName);
      debugPrint(
          "Todos los pedidos de tbl_pedido_pack eliminados. Filas afectadas: $rowsAffected");
      return rowsAffected;
    } catch (e, s) {
      debugPrint(
          "Error al eliminar todos los pedidos de tbl_pedido_pack: $e\n$s");
      return 0;
    }
  }
}
