import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wms_app/core/services/barcodes_inventario_cache_service.dart';
import 'package:wms_app/features/inventario/data/datasources/inventario_local_data_source.dart';
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

ProductoInventarioModel _p(
  int id, {
  String? name,
  String? code,
  String? barcode,
  int lot = 0,
  String? lotName,
  int loc = 0,
  String? locName,
}) => ProductoInventarioModel(
  productId: id,
  name: name ?? 'P$id',
  code: code,
  barcode: barcode,
  lotId: lot,
  lotName: lotName,
  locationId: loc,
  locationName: locName,
);

BarcodeProductoModel _b(int id, String code) =>
    BarcodeProductoModel(idProduct: id, barcode: code, cantidad: 1);

void main() {
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
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
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
      },
    );
    final dbMock = _Db();
    when(() => dbMock.getDatabaseInstance()).thenAnswer((_) async => db);
    when(
      () => dbMock.productoInventarioRepository,
    ).thenReturn(ProductInventarioRepository());
    when(
      () => dbMock.barcodesInventarioRepository,
    ).thenReturn(BarcodesInventarioRepository());
    local = InventarioLocalDataSourceImpl(dbMock);

    await local.reemplazarCatalogo(
      [
        _p(1, name: 'Leche Entera', code: 'REF-1', barcode: '7701', loc: 9),
        _p(2, name: 'Arroz 50%_x', code: 'REF-2', barcode: '7702'),
        _p(3, name: 'Leche Deslactosada', barcode: '7703', loc: 4),
        _p(4, name: 'Café', lot: 8, lotName: 'LOTE-A', loc: 4, locName: 'B-01'),
      ],
      [_b(4, 'EMP-CAFE')],
    );
  });

  tearDown(() => db.close());

  List<int?> ids(List<ProductoInventarioModel> l) =>
      l.map((p) => p.productId).toList();

  group('buscarProductos', () {
    test('sin texto: ubicación actual primero, luego ubicación 0', () async {
      final r = await local.buscarProductos(
        query: '',
        ubicacionId: 4,
        limit: 50,
        offset: 0,
      );
      expect(ids(r), [3, 4, 2, 1]);
    });

    test('busca en todo el catálogo sin distinguir mayúsculas', () async {
      final r = await local.buscarProductos(
        query: 'LECHE',
        limit: 50,
        offset: 0,
      );
      expect(ids(r), unorderedEquals([1, 3]));
    });

    test('código, lote, ubicación y barcode alterno', () async {
      Future<List<int?>> buscar(String q) async =>
          ids(await local.buscarProductos(query: q, limit: 50, offset: 0));

      expect(await buscar('ref-2'), [2]);
      expect(await buscar('lote-a'), [4]);
      expect(await buscar('b-01'), [4]);
      expect(await buscar('emp-ca'), [4]);
    });

    test('% y _ se buscan literales', () async {
      final r = await local.buscarProductos(
        query: '50%_',
        limit: 50,
        offset: 0,
      );
      expect(ids(r), [2]);
      final ninguno = await local.buscarProductos(
        query: '%',
        limit: 50,
        offset: 0,
      );
      expect(ids(ninguno), [2]);
    });

    test('pagina con limit/offset', () async {
      final p1 = await local.buscarProductos(query: '', limit: 3, offset: 0);
      final p2 = await local.buscarProductos(query: '', limit: 3, offset: 3);
      expect(p1, hasLength(3));
      expect(p2, hasLength(1));
      expect({...ids(p1), ...ids(p2)}, {1, 2, 3, 4});
    });
  });

  group('buscarProductoPorCodigo', () {
    test('por barcode o código, sin distinguir mayúsculas', () async {
      expect((await local.buscarProductoPorCodigo('7702'))?.productId, 2);
      expect((await local.buscarProductoPorCodigo('ref-1'))?.productId, 1);
    });

    test('por barcode alterno o de empaque', () async {
      final p = await local.buscarProductoPorCodigo('emp-cafe');
      expect(p?.productId, 4);
      expect(p?.lotName, 'LOTE-A');
    });

    test('inexistente o vacío devuelve null', () async {
      expect(await local.buscarProductoPorCodigo('NOPE'), isNull);
      expect(await local.buscarProductoPorCodigo('  '), isNull);
    });
  });
}
