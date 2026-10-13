import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regla: ninguna consulta a las tablas grandes (catálogo
/// `tblproductos_inventario`, ~72 mil filas, y `tbl_terceros`, ~322 mil)
/// puede traerlas completas en una sola llamada a sqflite.
///
/// sqflite pasa todo el resultado en un solo buffer del heap Java: con el
/// catálogo entero (33 MB) la app moría por OutOfMemoryError en PDAs con heap
/// de 128 MB (docs/plan_fix_oom_catalogo_productos.md).
///
/// Toda llamada `query(...)`/`rawQuery(...)` sobre esas tablas debe tener
/// `LIMIT`, `limit:` o `COUNT(`. Si está acotada por otro motivo (p. ej.
/// `SELECT DISTINCT` de propietarios), se marca con un comentario
/// `// lectura-acotada: <motivo>` justo antes de la llamada.
void main() {
  test('ninguna consulta a tablas grandes sin LIMIT en lib/', () {
    final infracciones = <String>[];
    final archivos = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final archivo in archivos) {
      infracciones.addAll(
        consultasDelCatalogoSinLimite(
          archivo.readAsStringSync(),
        ).map((linea) => '${archivo.path}:$linea'),
      );
    }

    expect(
      infracciones,
      isEmpty,
      reason: 'Consultas a tablas grandes sin LIMIT (riesgo de '
          'OutOfMemoryError). Paginar con LIMIT/OFFSET o por clave, o marcar '
          'con "// lectura-acotada: <motivo>" si está acotada por otro motivo.',
    );
  });

  group('el detector', () {
    test('detecta un SELECT * sin LIMIT, también vía alias', () {
      expect(
        consultasDelCatalogoSinLimite('''
          final a = await db.query(ProductInventarioTable.tableName);
          const p = ProductInventarioTable.tableName;
          final b = await db.rawQuery('SELECT * FROM \$p GROUP BY product_id');
          final c = await db.rawQuery('SELECT * FROM tblproductos_inventario');
        '''),
        [1, 3, 4],
      );
    });

    test('acepta LIMIT, limit:, COUNT y lectura-acotada', () {
      expect(
        consultasDelCatalogoSinLimite('''
          await db.rawQuery('SELECT * FROM \${ProductInventarioTable.tableName} LIMIT ?', [50]);
          await db.query(ProductInventarioTable.tableName, limit: 1);
          await db.rawQuery('SELECT COUNT(*) FROM \${ProductInventarioTable.tableName}');
          // lectura-acotada: una fila por propietario.
          await db.rawQuery('SELECT DISTINCT propietario FROM \${ProductInventarioTable.tableName}');
          await db.rawQuery('SELECT * FROM tbl_otra');
        '''),
        isEmpty,
      );
    });

    test('también cubre tbl_terceros', () {
      expect(
        consultasDelCatalogoSinLimite('''
          await db.query(TercerosTable.tableName);
          await db.rawQuery('SELECT 1 FROM \${TercerosTable.tableName} LIMIT 1');
        '''),
        [1],
      );
    });
  });
}

final _llamada = RegExp(r'\b(?:rawQuery|query)\(');
/// Tablas grandes: la clase `*Table` y el nombre literal de la tabla.
const _tablas = {
  'ProductInventarioTable': 'tblproductos_inventario',
  'TercerosTable': 'tbl_terceros',
  'UbicacionesTable': 'tblUbicaciones',
};

final _alias = RegExp(
  '(?:const|final|var)\\s+(\\w+)\\s*=\\s*'
  '(?:${_tablas.keys.join('|')})\\.tableName',
);
final _acotada = RegExp(r'\bLIMIT\b|\blimit\s*:|COUNT\(', caseSensitive: false);

/// Líneas (desde 1) de las llamadas a la tabla del catálogo sin límite.
List<int> consultasDelCatalogoSinLimite(String fuente) {
  final alias = _alias.allMatches(fuente).map((m) => m.group(1)!).toList();
  final referenciaTabla = RegExp([
    for (final clase in _tablas.keys) '$clase\\.tableName',
    for (final nombre in _tablas.values) '\\b$nombre\\b',
    for (final a in alias) '\\\$\\{?$a\\b',
  ].join('|'));

  final lineas = <int>[];
  for (final m in _llamada.allMatches(fuente)) {
    final texto = _argumentos(fuente, m.end - 1);
    if (!referenciaTabla.hasMatch(texto)) continue;
    if (_acotada.hasMatch(texto)) continue;
    if (_marcadaComoAcotada(fuente, m.start)) continue;
    lineas.add('\n'.allMatches(fuente.substring(0, m.start)).length + 1);
  }
  return lineas;
}

/// Texto entre el paréntesis de apertura en [abre] y su cierre.
String _argumentos(String fuente, int abre) {
  var nivel = 0;
  for (var i = abre; i < fuente.length; i++) {
    if (fuente[i] == '(') nivel++;
    if (fuente[i] == ')' && --nivel == 0) return fuente.substring(abre, i + 1);
  }
  return fuente.substring(abre);
}

/// Hay un `// lectura-acotada:` en las 2 líneas anteriores a la llamada.
bool _marcadaComoAcotada(String fuente, int inicio) {
  final previas = fuente.substring(0, inicio).split('\n');
  final desde = previas.length > 3 ? previas.length - 3 : 0;
  return previas.sublist(desde).any((l) => l.contains('// lectura-acotada:'));
}
