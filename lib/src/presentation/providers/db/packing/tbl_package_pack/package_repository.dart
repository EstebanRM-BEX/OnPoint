// packages_repository.dart

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/packing/tbl_package_pack/package_table.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/packing_response_model.dart';

class PackagesRepository {
  // Método para insertar o actualizar un paquete
  Future<void> insertPackage(Paquete package, String type) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      await db.transaction((txn) async {
        // Verificar si el paquete ya existe
        final List<Map<String, dynamic>> existingPackage = await txn.query(
          PackagesTable.tableName,
          where: 'id = ?',
          whereArgs: [package.id],
        );

        if (existingPackage.isNotEmpty) {
          // Actualizar el paquete si ya existe
          final response = await txn.update(
            PackagesTable.tableName,
            {
              PackagesTable.columnId: package.id,
              PackagesTable.columnName: package.name,
              PackagesTable.columnBatchId: package.batchId,
              PackagesTable.columnPedidoId: package.pedidoId,
              PackagesTable.columnCantidadProductos: package.cantidadProductos,
              PackagesTable.columnIsSticker: package.isSticker == true ? 1 : 0,
              PackagesTable.columnType: type,
              PackagesTable.columnConsecutivo: package.consecutivo,
            },
            where: '${PackagesTable.columnId} = ?',
            whereArgs: [package.id],
          );
          debugPrint("response update package: $response");
        } else {
          // Insertar nuevo paquete si no existe
          final response = await txn.insert(
            PackagesTable.tableName,
            {
              PackagesTable.columnId: package.id,
              PackagesTable.columnName: package.name,
              PackagesTable.columnBatchId: package.batchId,
              PackagesTable.columnPedidoId: package.pedidoId,
              PackagesTable.columnCantidadProductos: package.cantidadProductos,
              PackagesTable.columnIsSticker: package.isSticker == true ? 1 : 0,
              PackagesTable.columnType: type,
              PackagesTable.columnConsecutivo: package.consecutivo,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          debugPrint("response insert package: $response");
        }
      });
    } catch (e) {
      debugPrint("Error al insertar package: $e");
    }
  }

  Future<void> insertPackages(List<Paquete> packages, String type) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      await db.transaction((txn) async {
        Batch batch = txn.batch(); // Crear un batch de operaciones

        for (var package in packages) {
          // Verificar si el paquete ya existe
          final List<Map<String, dynamic>> existingPackage = await txn.query(
            PackagesTable.tableName,
            where: 'id = ?',
            whereArgs: [package.id],
          );

          if (existingPackage.isNotEmpty) {
            // Si el paquete existe, agregar la operación de actualización al batch
            batch.update(
              PackagesTable.tableName,
              {
                PackagesTable.columnId: package.id,
                PackagesTable.columnName: package.name,
                PackagesTable.columnBatchId: package.batchId,
                PackagesTable.columnPedidoId: package.pedidoId,
                PackagesTable.columnCantidadProductos:
                    package.cantidadProductos,
                PackagesTable.columnIsSticker:
                    package.isSticker == true ? 1 : 0,
                PackagesTable.columnType: type,
                PackagesTable.columnConsecutivo: package.consecutivo,
              },
              where: '${PackagesTable.columnId} = ?',
              whereArgs: [package.id],
            );
            debugPrint("Se agregó la actualización del paquete: ${package.id}");
          } else {
            // Si el paquete no existe, agregar la operación de inserción al batch
            batch.insert(
              PackagesTable.tableName,
              {
                PackagesTable.columnId: package.id,
                PackagesTable.columnName: package.name,
                PackagesTable.columnBatchId: package.batchId,
                PackagesTable.columnPedidoId: package.pedidoId,
                PackagesTable.columnCantidadProductos:
                    package.cantidadProductos,
                PackagesTable.columnIsSticker:
                    package.isSticker == true ? 1 : 0,
                PackagesTable.columnType: type,
                PackagesTable.columnConsecutivo: package.consecutivo,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            debugPrint("Se agregó la inserción del paquete: ${package.id}");
          }
        }

        // Ejecutar el batch, lo que enviará todas las operaciones a la base de datos
        await batch.commit();
        debugPrint("Batch commit exitoso");
      });
    } catch (e) {
      debugPrint("Error al insertar paquetes: $e");
    }
  }

  // Método para obtener los paquetes de un pedido
  Future<List<Paquete>> getPackagesPedido(int pedidoId) async {
    Database db = await DataBaseSqlite().getDatabaseInstance();
    final List<Map<String, dynamic>> maps = await db.query(
      PackagesTable.tableName,
      where: '${PackagesTable.columnPedidoId} = ?',
      whereArgs: [pedidoId],
    );

    final List<Paquete> productos = maps.map((map) {
      return Paquete(
        id: map[PackagesTable.columnId],
        name: map[PackagesTable.columnName],
        batchId: map[PackagesTable.columnBatchId],
        pedidoId: map[PackagesTable.columnPedidoId],
        cantidadProductos: map[PackagesTable.columnCantidadProductos],
        isSticker: map[PackagesTable.columnIsSticker] == 1,
        type: map[PackagesTable.columnType],
        consecutivo: map[PackagesTable.columnConsecutivo],
      );
    }).toList();
    return productos;
  }

  // Método para actualizar la cantidad de productos de un paquete
  Future<int> updatePackageCantidad(int packageId, int cantidadRestar) async {
    debugPrint("packageId: $packageId, cantidadRestar: $cantidadRestar");
    Database db = await DataBaseSqlite().getDatabaseInstance();

    // Primero, obtenemos el paquete con el ID dado
    final List<Map<String, dynamic>> maps = await db.query(
      PackagesTable.tableName,
      where: '${PackagesTable.columnId} = ?',
      whereArgs: [packageId],
    );

    // Si no se encuentra el paquete, retornamos 0
    if (maps.isEmpty) {
      return 0;
    }

    // Obtenemos la cantidad de productos actual del paquete
    dynamic cantidadActual = maps.first[PackagesTable.columnCantidadProductos];

    // Verificamos si la cantidad a restar no excede la cantidad disponible
    if (cantidadActual < cantidadRestar) {
      throw Exception(
          "La cantidad a restar es mayor que la cantidad disponible");
    }

    // Calculamos la nueva cantidad
    dynamic nuevaCantidad = cantidadActual - cantidadRestar;

    // Actualizamos el paquete con la nueva cantidad
    dynamic result = await db.update(
      PackagesTable.tableName,
      {PackagesTable.columnCantidadProductos: nuevaCantidad},
      where: '${PackagesTable.columnId} = ?',
      whereArgs: [packageId],
    );

    return result; // Retornamos el número de filas afectadas
  }

  // Método para obtener la información de un paquete por su ID
  Future<Paquete?> getPackageById(int packageId) async {
    Database db = await DataBaseSqlite().getDatabaseInstance();
    final List<Map<String, dynamic>> maps = await db.query(
      PackagesTable.tableName,
      where: '${PackagesTable.columnId} = ?',
      whereArgs: [packageId],
    );

    if (maps.isNotEmpty) {
      return Paquete(
        id: maps[0][PackagesTable.columnId],
        name: maps[0][PackagesTable.columnName],
        batchId: maps[0][PackagesTable.columnBatchId],
        pedidoId: maps[0][PackagesTable.columnPedidoId],
        cantidadProductos: maps[0][PackagesTable.columnCantidadProductos],
        isSticker: maps[0][PackagesTable.columnIsSticker] == 1,
        type: maps[0][PackagesTable.columnType],
        consecutivo: maps[0][PackagesTable.columnConsecutivo],
      );
    }
    return null;
  }

  // Método para eliminar un paquete por ID
  Future<void> deletePackageById(int packageId) async {
    Database db = await DataBaseSqlite().getDatabaseInstance();
    await db.delete(
      PackagesTable.tableName,
      where: '${PackagesTable.columnId} = ?',
      whereArgs: [packageId],
    );
  }

  //metodo para actualizar un paquete por id
  Future<void> updatePackageById(Paquete package) async {
    Database db = await DataBaseSqlite().getDatabaseInstance();
    await db.update(
      PackagesTable.tableName,
      {
        PackagesTable.columnName: package.name,
        PackagesTable.columnBatchId: package.batchId,
        PackagesTable.columnPedidoId: package.pedidoId,
        PackagesTable.columnCantidadProductos: package.cantidadProductos,
        PackagesTable.columnIsSticker: package.isSticker == true ? 1 : 0,
        PackagesTable.columnType: package.type,
        PackagesTable.columnConsecutivo: package.consecutivo,
      },
      where: '${PackagesTable.columnId} = ?',
      whereArgs: [package.id],
    );
  }
}
