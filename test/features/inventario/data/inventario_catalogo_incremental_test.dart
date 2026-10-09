import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wms_app/core/services/barcodes_inventario_cache_service.dart';
import 'package:wms_app/features/inventario/data/datasources/inventario_local_data_source.dart';
import 'package:wms_app/features/inventario/data/datasources/inventario_remote_data_source.dart';
import 'package:wms_app/features/inventario/data/models/barcode_producto_model.dart';
import 'package:wms_app/features/inventario/data/models/producto_inventario_model.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_barcode/barcodes_inventario_repository.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_barcode/barcodes_inventario_table.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/product_inventario_repository.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/product_inventario_table.dart';

class _Db extends Mock implements DataBaseSqlite {}

class _Cache extends Mock implements BarcodesInventarioCacheService {}

ProductoInventarioModel _p(int id, {int lot = 0, int loc = 0}) =>
    ProductoInventarioModel(
      productId: id,
      name: 'P$id',
      lotId: lot,
      locationId: loc,
    );

BarcodeProductoModel _b(int id, String code) =>
    BarcodeProductoModel(idProduct: id, barcode: code, cantidad: 1);

void main() {
  group('parseo de product_quants', () {
    String body(Map<String, dynamic> result) =>
        jsonEncode({'jsonrpc': '2.0', 'id': null, 'result': result});

    Map<String, dynamic> fila(int id) => {
      'product_id': id,
      'name': 'P$id',
      'location_id': 0,
      'lot_id': 0,
      'quantity': 0.0,
      'other_barcodes': [
        {'barcode': 'B$id', 'id_product': id, 'cantidad': 1},
      ],
    };

    test('backend anterior (sin server_time) se trata como completo', () {
      final r = parseProductosForTest(body({'data': [fila(1)]}));
      expect(r['full'], isTrue);
      expect(r['serverTime'], isNull);
    });

    test('incremental con ids y barcodes repetidos por fila deduplicados', () {
      final r = parseProductosForTest(body({
        'status': 'success',
        'server_time': '2026-10-09 16:02:11',
        'scope': 'abc',
        'full': false,
        'deleted_product_ids': [9],
        'active_product_ids': [1, 2],
        'data': [fila(1), fila(1)],
      }));
      expect(r['full'], isFalse);
      expect(r['scope'], 'abc');
      expect(r['deleted'], [9]);
      expect(r['active'], [1, 2]);
      expect((r['productos'] as List), hasLength(2));
      expect((r['barcodes'] as List), hasLength(1));
    });

    test('status error no devuelve datos', () {
      final r = parseProductosForTest(
        body({'status': 'error', 'msg': 'falló'}),
      );
      expect(r['error'], 'falló');
    });

    test('sesión expirada', () {
      final r = parseProductosForTest(jsonEncode({
        'error': {'code': 100, 'message': 'Session expired'},
      }));
      expect(r['sessionExpired'], isTrue);
    });
  });

  group('aplicarCambiosCatalogo (SQLite real)', () {
    late Database db;
    late InventarioLocalDataSourceImpl local;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      if (!getIt.isRegistered<BarcodesInventarioCacheService>()) {
        getIt.registerSingleton<BarcodesInventarioCacheService>(_Cache());
      }
    });

    setUp(() async {
      db = await openDatabase(inMemoryDatabasePath, version: 1,
          onCreate: (d, _) async {
        // createTable trae varias sentencias; se ejecutan una por una.
        for (final sql in [
          ProductInventarioTable.createTable(),
          BarcodesInventarioTable.createTable(),
        ]) {
          for (final s in sql.split(';')) {
            final limpio = s
                .split('\n')
                .where((l) => !l.trim().startsWith('--'))
                .join('\n')
                .trim();
            if (limpio.isNotEmpty) await d.execute(limpio);
          }
        }
      });
      final dbMock = _Db();
      when(() => dbMock.getDatabaseInstance()).thenAnswer((_) async => db);
      when(() => dbMock.productoInventarioRepository)
          .thenReturn(ProductInventarioRepository());
      when(() => dbMock.barcodesInventarioRepository)
          .thenReturn(BarcodesInventarioRepository());
      local = InventarioLocalDataSourceImpl(dbMock);

      await local.reemplazarCatalogo(
        [_p(1), _p(2, lot: 5, loc: 7), _p(2, lot: 6, loc: 7), _p(3)],
        [_b(1, 'A'), _b(2, 'B'), _b(3, 'C')],
      );
    });

    tearDown(() => db.close());

    Future<List<int>> ids() async => [
      for (final r in await db.query(
        ProductInventarioTable.tableName,
        orderBy: '${ProductInventarioTable.columnProductId}, '
            '${ProductInventarioTable.columnLotId}',
      ))
        r[ProductInventarioTable.columnProductId] as int,
    ];

    Future<List<String>> codes() async => [
      for (final r in await db.query(
        BarcodesInventarioTable.tableName,
        orderBy: BarcodesInventarioTable.columnBarcode,
      ))
        r[BarcodesInventarioTable.columnBarcode] as String,
    ];

    test('reemplaza el producto entero, borra eliminados y no activos',
        () async {
      await local.aplicarCambiosCatalogo(
        // El 2 ahora tiene una sola fila; el 4 es nuevo.
        productos: [_p(2, lot: 5, loc: 7), _p(4)],
        barcodes: [_b(2, 'B2'), _b(4, 'D')],
        eliminados: [1],
        // El 3 ya no existe en el servidor.
        activos: [2, 4],
      );

      expect(await ids(), [2, 4]);
      expect(await codes(), ['B2', 'D']);
    });

    test('sin activos no depura lo que no vino', () async {
      await local.aplicarCambiosCatalogo(
        productos: [_p(4)],
        barcodes: const [],
        eliminados: const [],
      );
      expect(await ids(), [1, 2, 2, 3, 4]);
    });

    test('más de 999 ids activos (tandas)', () async {
      await local.aplicarCambiosCatalogo(
        productos: const [],
        barcodes: const [],
        eliminados: const [],
        activos: [for (var i = 3; i < 3000; i++) i],
      );
      expect(await ids(), [3]);
    });
  });
}
