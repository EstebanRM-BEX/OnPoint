import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/devoluciones/tbl_product/product_devolucion_table.dart';
import 'package:wms_app/src/presentation/providers/db/expedition/tbl_expedicion_items/expedicion_items_table.dart';
import 'package:wms_app/src/presentation/providers/db/expedition/tbl_expedicion_items_sueltos/expedicion_items_sueltos_table.dart';
import 'package:wms_app/src/presentation/providers/db/expedition/tbl_expedicion_paquetes/expedicion_paquetes_table.dart';
import 'package:wms_app/src/presentation/providers/db/expedition/tbl_expedicion_pedidos/expedicion_pedidos_table.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_barcode/barcodes_inventario_table.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/product_inventario_table.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_barcodes/barcodes_table.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_ubicaciones/ubicaciones_table.dart';
import 'package:wms_app/src/presentation/providers/db/recepcion_multiusuario/tbl_recepcion_session_pool/recepcion_session_pool_table.dart';

/// En Android `execute` corre solo la primera sentencia: hasta la v67 los
/// índices declarados dentro de `createTable()` nunca se crearon.
void main() {
  late Database db;

  final createTables = [
    UbicacionesTable.createTable(),
    BarcodesInventarioTable.createTable(),
    ProductInventarioTable.createTable(),
    BarcodesPackagesTable.createTable(),
    ProductDevolucionTable.createTable(),
    ExpedicionPedidosTable.createTable(),
    ExpedicionPaquetesTable.createTable(),
    ExpedicionItemsTable.createTable(),
    ExpedicionItemsSueltosTable.createTable(),
    RecepcionSessionPoolTable.createTable(),
  ];

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath);
    // Base como quedaba en Android hasta la v67: tablas sin índices.
    for (final sql in createTables) {
      await db.execute(sql);
    }
  });

  tearDown(() => db.close());

  Future<int> contar(String sql) async =>
      (await db.rawQuery(sql)).first.values.first as int;

  Future<int> indices() => contar(
    "SELECT COUNT(*) FROM sqlite_master WHERE type = 'index' AND sql IS NOT NULL",
  );

  Future<int> filas(String tabla) => contar('SELECT COUNT(*) FROM $tabla');

  test('cada createTable es una sola sentencia (sin índices adentro)', () {
    for (final sql in createTables) {
      final sinFinal = sql.trim().replaceFirst(RegExp(r';$'), '');
      expect(sinFinal.contains(';'), isFalse, reason: sql);
      expect(sql.toUpperCase().contains('CREATE INDEX'), isFalse);
      expect(sql.toUpperCase().contains('CREATE UNIQUE INDEX'), isFalse);
    }
  });

  test('crea todos los índices y es idempotente', () async {
    expect(await indices(), 0);
    await DataBaseSqlite.crearIndices(db);
    final total = DataBaseSqlite.tablasConIndices.fold<int>(
      0,
      (n, t) => n + t.indices.length,
    );
    expect(await indices(), total);
    await DataBaseSqlite.crearIndices(db);
    expect(await indices(), total);
  });

  test('migración: borra duplicados de tablas con índice único', () async {
    for (var i = 0; i < 3; i++) {
      await db.insert(BarcodesInventarioTable.tableName, {
        BarcodesInventarioTable.columnIdProduct: 1,
        BarcodesInventarioTable.columnBarcode: 'A',
        BarcodesInventarioTable.columnCantidad: i,
      });
      await db.insert(ProductDevolucionTable.tableName, {
        ProductDevolucionTable.columnProductId: 1,
        ProductDevolucionTable.columnLotId: 0,
      });
      await db.insert(BarcodesPackagesTable.tableName, {
        BarcodesPackagesTable.columnBatchId: 1,
        BarcodesPackagesTable.columnIdMove: 2,
        BarcodesPackagesTable.columnIdProduct: 3,
        BarcodesPackagesTable.columnBarcode: 'B',
        BarcodesPackagesTable.columnBarcodeType: 'picking',
      });
    }

    await DataBaseSqlite.crearIndices(db, limpiarDuplicados: true);

    expect(await filas(BarcodesInventarioTable.tableName), 1);
    expect(await filas(ProductDevolucionTable.tableName), 1);
    expect(await filas(BarcodesPackagesTable.tableName), 1);
    // Queda la más reciente.
    final b = await db.query(BarcodesInventarioTable.tableName);
    expect(b.single[BarcodesInventarioTable.columnCantidad], 2);
  });

  test('con el índice único, replace actualiza en vez de duplicar', () async {
    await DataBaseSqlite.crearIndices(db);
    for (var i = 0; i < 3; i++) {
      await db.insert(ProductDevolucionTable.tableName, {
        ProductDevolucionTable.columnProductId: 1,
        ProductDevolucionTable.columnLotId: 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    expect(await filas(ProductDevolucionTable.tableName), 1);
  });

  test('inventario admite varios quants del mismo producto/lote/ubicación',
      () async {
    await DataBaseSqlite.crearIndices(db, limpiarDuplicados: true);
    for (final q in [28000.0, 28000.0, 6.0]) {
      await db.insert(ProductInventarioTable.tableName, {
        ProductInventarioTable.columnProductId: 10627,
        ProductInventarioTable.columnLotId: 0,
        ProductInventarioTable.columnLocationId: 55133,
        ProductInventarioTable.columnQuantity: q,
      });
    }
    expect(await filas(ProductInventarioTable.tableName), 3);
  });
}
