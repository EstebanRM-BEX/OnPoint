import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/devoluciones/tbl_terceros/terceros_table.dart';
import 'package:wms_app/src/presentation/views/devoluciones/models/response_terceros_model.dart';

class TercerosRepository {
  /// Inserción masiva usando Raw SQL Multi-Values (Alto Rendimiento)
  Future<void> insertTerceros(List<Terceros> tercerosList) async {
    if (tercerosList.isEmpty) return;

    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      await db.transaction((txn) async {
        const int itemsPerQuery = 40; // Mantenemos el estándar de 40 items
        final Batch batch = txn.batch();

        for (var i = 0; i < tercerosList.length; i += itemsPerQuery) {
          final end = math.min(i + itemsPerQuery, tercerosList.length);
          final chunk = tercerosList.sublist(i, end);

          final StringBuffer queryBuffer = StringBuffer();
          queryBuffer.write('INSERT INTO ${TercerosTable.tableName} (');
          queryBuffer.write('${TercerosTable.columnId}, ${TercerosTable.columnDocument}, ${TercerosTable.columnSucursal}, ${TercerosTable.columnName}, ${TercerosTable.columnAlmacen}) VALUES ');

          final List<dynamic> args = [];
          for (var j = 0; j < chunk.length; j++) {
            if (j > 0) queryBuffer.write(', ');
            queryBuffer.write('(?,?,?,?,?)');
            var tercero = chunk[j];
            args.addAll([
              tercero.id,
              tercero.document,
              tercero.sucursal,
              tercero.name,
              tercero.almacen,
            ]);
          }
          batch.rawInsert(queryBuffer.toString(), args);
        }
        await batch.commit(noResult: true);
        debugPrint("📦 Terceros SQLite: Insertados ${tercerosList.length}");
      });
    } catch (e, s) {
      debugPrint("❌ Error al insertar terceros en SQLite: $e ==> $s");
    }
  }

  Future<List<Terceros>> getAllTerceros() async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> maps = await db.query(TercerosTable.tableName);

      return maps.map((map) {
        return Terceros(
          id: map[TercerosTable.columnId],
          document: map[TercerosTable.columnDocument],
          sucursal: map[TercerosTable.columnSucursal],
          name: map[TercerosTable.columnName],
          almacen: map[TercerosTable.columnAlmacen],
        );
      }).toList();
    } catch (e) {
      debugPrint("Error al obtener terceros de SQLite: $e");
      return [];
    }
  }

  Future<void> deleTerceros() async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      await db.delete(TercerosTable.tableName);
    } catch (e) {
      debugPrint("Error al limpiar tabla tbl_terceros: $e");
    }
  }
}
