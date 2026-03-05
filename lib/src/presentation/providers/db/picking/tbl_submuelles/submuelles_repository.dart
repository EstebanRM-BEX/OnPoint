// submuelles_repository.dart

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/submeuelle_model.dart';
import 'submuelles_table.dart'; // Importa el archivo de la tabla

class SubmuellesRepository {
  // Método para insertar todos los submuelles sin que se repitan
  Future<void> insertSubmuelles(List<Muelles> submuelles) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      // Ejecutamos las inserciones en una sola transacción usando un batch
      await db.transaction((txn) async {
        Batch batch = txn.batch();

        // Insertamos o reemplazamos los submuelles
        for (var submuelle in submuelles) {
          batch.insert(
            SubmuellesTable.tableName,
            {
              SubmuellesTable.columnId: submuelle.id,
              SubmuellesTable.columnName: submuelle.name,
              SubmuellesTable.columnCompleteName: submuelle.completeName,
              SubmuellesTable.columnLocationId: submuelle.locationId,
              SubmuellesTable.columnBarcode: submuelle.barcode,
            },
            conflictAlgorithm: ConflictAlgorithm
                .replace, // Reemplazamos si el registro ya existe
          );
        }

        // Ejecutamos el batch
        await batch.commit();
      });

      debugPrint("Submuelles insertados/actualizados con éxito.");
    } catch (e) {
      debugPrint("Error al insertar submuelles: $e");
    }
  }

  // Método para obtener todos los submuelles por location_id
  Future<List<Muelles>> getSubmuellesByLocationId(int locationId) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      final List<Map<String, dynamic>> maps = await db.query(
        SubmuellesTable.tableName,
        where: '${SubmuellesTable.columnLocationId} = ?',
        whereArgs: [locationId],
      );

      // Mapeamos los resultados a una lista de objetos Muelles
      final List<Muelles> submuelles = maps.map((map) {
        return Muelles(
          id: map[SubmuellesTable.columnId],
          name: map[SubmuellesTable.columnName],
          completeName: map[SubmuellesTable.columnCompleteName],
          locationId: map[SubmuellesTable.columnLocationId],
          barcode: map[SubmuellesTable.columnBarcode],
        );
      }).toList();

      return submuelles;
    } catch (e) {
      debugPrint("Error al obtener submuelles por location_id: $e");
      return []; // Devuelve una lista vacía en caso de error
    }
  }
}
