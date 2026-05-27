import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wms_app/src/presentation/providers/db/picking/tbl_pick_products/pick_products_table.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('tbl_pick_products schema', () {
    late Database db;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (database, version) async {
          await database.execute('''
            CREATE TABLE tbl_picking_pick (id INTEGER PRIMARY KEY)
          ''');
          await database.execute(PickProductsTable.createTable());
          await database.insert('tbl_picking_pick', {'id': 100});
        },
      );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'allows two rows with same odoo id and id_product but different id_move',
      () async {
        const sharedOdooId = 999;
        const sharedIdProduct = 42;
        const batchId = 100;

        await db.insert(PickProductsTable.tableName, {
          PickProductsTable.columnId: sharedOdooId,
          PickProductsTable.columnIdProduct: sharedIdProduct,
          PickProductsTable.columnBatchId: batchId,
          PickProductsTable.columnIdMove: 1,
          PickProductsTable.columnQuantity: 5,
        });

        await db.insert(PickProductsTable.tableName, {
          PickProductsTable.columnId: sharedOdooId,
          PickProductsTable.columnIdProduct: sharedIdProduct,
          PickProductsTable.columnBatchId: batchId,
          PickProductsTable.columnIdMove: 2,
          PickProductsTable.columnQuantity: 3,
        });

        final rows = await db.query(
          PickProductsTable.tableName,
          where: '${PickProductsTable.columnBatchId} = ?',
          whereArgs: [batchId],
        );

        expect(rows.length, 2);
        expect(
          rows.map((r) => r[PickProductsTable.columnIdMove]).toSet(),
          {1, 2},
        );
      },
    );

    test(
      'rejects duplicate id_product + batch_id + id_move via UNIQUE constraint',
      () async {
        const batchId = 100;

        await db.insert(PickProductsTable.tableName, {
          PickProductsTable.columnId: 1,
          PickProductsTable.columnIdProduct: 42,
          PickProductsTable.columnBatchId: batchId,
          PickProductsTable.columnIdMove: 1,
        });

        expect(
          () => db.insert(PickProductsTable.tableName, {
            PickProductsTable.columnId: 2,
            PickProductsTable.columnIdProduct: 42,
            PickProductsTable.columnBatchId: batchId,
            PickProductsTable.columnIdMove: 1,
          }),
          throwsA(isA<DatabaseException>()),
        );
      },
    );
  });
}
