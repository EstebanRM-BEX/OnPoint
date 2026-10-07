import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wms_app/src/presentation/providers/db/sql_chunks.dart';

void main() {
  group('sqlChunks', () {
    test('lista vacía no produce tandas', () {
      expect(sqlChunks(<int>[]), isEmpty);
    });

    test('lista menor al tamaño produce una sola tanda', () {
      expect(sqlChunks([1, 2, 3], size: 5).toList(), [
        [1, 2, 3],
      ]);
    });

    test('parte la lista en tandas y conserva todos los elementos', () {
      final values = List.generate(1203, (i) => i);
      final chunks = sqlChunks(values).toList();

      expect(chunks.length, 3);
      expect(chunks.every((c) => c.length <= kSqlVariableChunk), isTrue);
      expect(chunks.expand((c) => c).toList(), values);
    });

    test('ninguna tanda supera el límite de 999 variables de SQLite', () {
      final chunks = sqlChunks(List.generate(10000, (i) => i)).toList();
      expect(chunks.every((c) => c.length < 999), isTrue);
    });
  });

  group('queryWhereIn', () {
    setUpAll(sqfliteFfiInit);

    test('junta las filas de todas las tandas', () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      await db.execute('CREATE TABLE t (product_id INTEGER, id_move INTEGER)');
      // Filas repartidas en la primera, la segunda y la tercera tanda.
      for (final id in [3, 700, 1150, 5000]) {
        await db.insert('t', {'product_id': id, 'id_move': id * 2});
      }

      final rows = await queryWhereIn(
        db,
        't',
        inColumn: 'product_id',
        values: List.generate(1200, (i) => i),
        columns: ['product_id', 'id_move'],
      );

      expect(rows.map((r) => r['product_id']).toList()..sort(), [3, 700, 1150]);
    });

    test('sin valores no consulta nada', () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      await db.execute('CREATE TABLE t (product_id INTEGER)');

      final rows = await queryWhereIn(
        db,
        't',
        inColumn: 'product_id',
        values: <int>[],
      );

      expect(rows, isEmpty);
    });
  });
}
