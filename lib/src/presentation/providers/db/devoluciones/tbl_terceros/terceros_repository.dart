import 'dart:math' as math;
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
  TercerosRepository({DataBaseSqlite? database})
      : _database = database ?? DataBaseSqlite();

  final DataBaseSqlite _database;

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

  // Consultas acotadas: la tabla tiene ~322 mil terceros. Leerla completa en
  // una sola consulta arma un buffer enorme en el heap Java (el mismo
  // OutOfMemoryError del catálogo de productos, ver
  // docs/plan_fix_oom_catalogo_productos.md).

  /// Una página de terceros (orden de la tabla). [query] busca, sin
  /// distinguir mayúsculas, en nombre y documento.
  Future<List<Terceros>> buscar({
    String query = '',
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final db = await _database.getDatabaseInstance();
      final q = query.trim();
      final args = <Object?>[];
      var where = '';
      if (q.isNotEmpty) {
        // LIKE de SQLite ya ignora mayúsculas (ASCII); se escapan % y _ para
        // que se busquen literales.
        final like =
            '%${q.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_')}%';
        where = "WHERE ${TercerosTable.columnName} LIKE ? ESCAPE '\\' "
            "OR ${TercerosTable.columnDocument} LIKE ? ESCAPE '\\' ";
        args.addAll([like, like]);
      }
      final rows = await db.rawQuery(
        'SELECT * FROM ${TercerosTable.tableName} $where'
        'ORDER BY rowid LIMIT ? OFFSET ?',
        [...args, limit, offset],
      );
      return rows.map(_fromRow).toList();
    } catch (e) {
      debugPrint("Error al buscar terceros en SQLite: $e");
      return [];
    }
  }

  /// Tercero por documento escaneado (sin distinguir mayúsculas); `null` si
  /// no existe.
  Future<Terceros?> getByDocumento(String documento) async {
    final d = documento.trim();
    if (d.isEmpty) return null;
    try {
      final db = await _database.getDatabaseInstance();
      final rows = await db.rawQuery(
        'SELECT * FROM ${TercerosTable.tableName} '
        'WHERE ${TercerosTable.columnDocument} = ? COLLATE NOCASE LIMIT 1',
        [d],
      );
      return rows.isEmpty ? null : _fromRow(rows.first);
    } catch (e) {
      debugPrint("Error al buscar tercero por documento: $e");
      return null;
    }
  }

  /// Hay terceros descargados en SQLite.
  Future<bool> hayTerceros() async {
    try {
      final db = await _database.getDatabaseInstance();
      final rows = await db.rawQuery(
        'SELECT 1 FROM ${TercerosTable.tableName} LIMIT 1',
      );
      return rows.isNotEmpty;
    } catch (e) {
      debugPrint("Error al revisar terceros en SQLite: $e");
      return false;
    }
  }

  Terceros _fromRow(Map<String, Object?> map) => Terceros(
        id: map[TercerosTable.columnId] as int?,
        document: map[TercerosTable.columnDocument] as String?,
        sucursal: map[TercerosTable.columnSucursal] as String?,
        name: map[TercerosTable.columnName],
        almacen: map[TercerosTable.columnAlmacen] as String?,
      );

  Future<void> deleTerceros() async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      await db.delete(TercerosTable.tableName);
    } catch (e) {
      debugPrint("Error al limpiar tabla tbl_terceros: $e");
    }
  }
}
