import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/devoluciones/tbl_terceros/terceros_table.dart';
import 'package:wms_app/src/presentation/views/devoluciones/models/response_terceros_model.dart';

import 'package:flutter/foundation.dart'; // import necesario para compute

// Funciones Top-Level (Isolate para asegurar 60 FPS fluidos)
List<Map<String, dynamic>> _processTercerosRawArgs(List<Terceros> tercerosList) {
  final List<Map<String, dynamic>> queries = [];
  // LÍMITE ABSOLUTO DE VARIABLES SQLITE: 999.
  // Tenemos apenas 5 columnas, entonces 999 / 5 = 199.8.
  // Usaremos 199 iteraciones masivas por comando de MethodChannel.
  const int itemsPerQuery = 199; 
  
  for (var i = 0; i < tercerosList.length; i += itemsPerQuery) {
    final end = math.min(i + itemsPerQuery, tercerosList.length);
    final chunk = tercerosList.sublist(i, end);

    final StringBuffer queryBuffer = StringBuffer();
    queryBuffer.write('INSERT INTO ${TercerosTable.tableName} (');
    queryBuffer.write('${TercerosTable.columnId}, ${TercerosTable.columnDocument}, ${TercerosTable.columnSucursal}, ${TercerosTable.columnName}, ${TercerosTable.columnAlmacen}) VALUES ');

    final List<dynamic> args = [];
    for (var j = 0; j < chunk.length; j++) {
      if (j > 0) queryBuffer.write(',');
      queryBuffer.write('(?,?,?,?,?)'); // 5 params

      final tercero = chunk[j];
      args.addAll([
        tercero.id,
        tercero.document,
        tercero.sucursal,
        tercero.name,
        tercero.almacen,
      ]);
    }
    queries.add({
      'sql': queryBuffer.toString(),
      'args': args,
    });
  }
  return queries;
}

class TercerosRepository {
  /// Inserción masiva usando Raw SQL Multi-Values y Extrema Optimización
  Future<void> insertTerceros(List<Terceros> tercerosList) async {
    if (tercerosList.isEmpty) return;

    Stopwatch stopwatch = Stopwatch();
    stopwatch.start();

    try {
      // 1. Delegamos el mapeo de listas a un hilo secundario
      final List<Map<String, dynamic>> queries = await compute(_processTercerosRawArgs, tercerosList);

      Database db = await DataBaseSqlite().getDatabaseInstance();

      // 2. Apagamos la integridad de I/O temporalmente volcando logs a RAM
      await db.rawQuery('PRAGMA synchronous = OFF;');
      await db.rawQuery('PRAGMA journal_mode = MEMORY;');
      await db.rawQuery('PRAGMA temp_store = MEMORY;');

      // 3. Inyección directa
      await db.transaction((txn) async {
        final Batch batch = txn.batch();
        for (var query in queries) {
          batch.rawInsert(query['sql'] as String, query['args'] as List<dynamic>);
        }
        await batch.commit(noResult: true);
      });

      // Restauramos
      await db.rawQuery('PRAGMA synchronous = NORMAL;');
      await db.rawQuery('PRAGMA journal_mode = WAL;');

      stopwatch.stop();
      debugPrint("📦 [BENCHMARK] Insertados Terceros SQLite: ${tercerosList.length} | Tiempo: ${stopwatch.elapsedMilliseconds} ms");
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
