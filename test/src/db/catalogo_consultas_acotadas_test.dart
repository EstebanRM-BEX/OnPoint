import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_barcode/barcodes_inventario_table.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/product_inventario_repository.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/product_inventario_table.dart';
import 'package:wms_app/src/presentation/providers/db/models/response_products_model.dart';

class _Db extends Mock implements DataBaseSqlite {}

/// Consultas acotadas del catálogo (plan_fix_oom_catalogo_productos, fase 1):
/// ninguna devuelve el catálogo completo en una sola llamada a sqflite.
void main() {
  late Database db;
  late ProductInventarioRepository repo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<void> stock(
    int productId, {
    required String name,
    String code = '',
    String barcode = '',
    String category = '',
    int locationId = 0,
  }) => db.insert(ProductInventarioTable.tableName, {
    ProductInventarioTable.columnProductId: productId,
    ProductInventarioTable.columnProductName: name,
    ProductInventarioTable.columnProductCode: code,
    ProductInventarioTable.columnBarcode: barcode,
    ProductInventarioTable.columnCategory: category,
    ProductInventarioTable.columnLocationId: locationId,
  });

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath);
    await db.execute(ProductInventarioTable.createTable());
    await db.execute(BarcodesInventarioTable.createTable());
    for (final sql in [
      ...ProductInventarioTable.indices,
      ...BarcodesInventarioTable.indices,
    ]) {
      await db.execute(sql);
    }
    final dbMock = _Db();
    when(() => dbMock.getDatabaseInstance()).thenAnswer((_) async => db);
    repo = ProductInventarioRepository(database: dbMock);

    // Producto 1 con stock en dos ubicaciones (dos filas, un producto).
    await stock(
      1,
      name: 'Leche Entera',
      code: 'REF-1',
      barcode: '7701',
      category: 'Lácteos',
      locationId: 4,
    );
    await stock(
      1,
      name: 'Leche Entera',
      code: 'REF-1',
      barcode: '7701',
      category: 'Lácteos',
      locationId: 9,
    );
    await stock(
      2,
      name: 'Arroz 50%_x',
      code: 'REF-2',
      barcode: '7702',
      category: 'Granos',
    );
    await stock(
      3,
      name: 'Leche Deslactosada',
      barcode: '7703',
      category: 'Lácteos',
    );
    await stock(4, name: 'Café', code: 'CAF', category: 'Bebidas');
    await db.insert(BarcodesInventarioTable.tableName, {
      BarcodesInventarioTable.columnIdProduct: 4,
      BarcodesInventarioTable.columnBarcode: 'EMP-CAFE',
      BarcodesInventarioTable.columnCantidad: 12,
    });
  });

  tearDown(() => db.close());

  List<int?> ids(List<dynamic> l) => l.map((p) => p.productId as int?).toList();

  group('getByCodigo', () {
    test('por barcode, por code y por código alterno', () async {
      expect((await repo.getByCodigo('7702'))?.productId, 2);
      expect((await repo.getByCodigo('CAF'))?.productId, 4);
      expect((await repo.getByCodigo(' EMP-CAFE '))?.productId, 4);
    });

    test('sin distinguir mayúsculas (las pantallas comparan en minúsculas)',
        () async {
      expect((await repo.getByCodigo('ref-2'))?.productId, 2);
      expect((await repo.getByCodigo('caf'))?.productId, 4);
      expect((await repo.getByCodigo('emp-cafe'))?.productId, 4);
    });

    test('prefiere la fila de stock de la ubicación indicada', () async {
      expect(
        (await repo.getByCodigo('7701', ubicacionPreferida: 9))?.locationId,
        9,
      );
      expect(
        (await repo.getByCodigo('7701', ubicacionPreferida: 4))?.locationId,
        4,
      );
    });

    test('inexistente o vacío → null', () async {
      expect(await repo.getByCodigo('NO-EXISTE'), isNull);
      expect(await repo.getByCodigo('  '), isNull);
    });
  });

  group('buscar', () {
    test('una fila por producto, ordenado por product_id', () async {
      expect(ids(await repo.buscar()), [1, 2, 3, 4]);
    });

    test('paginado', () async {
      expect(ids(await repo.buscar(limit: 2)), [1, 2]);
      expect(ids(await repo.buscar(limit: 2, offset: 2)), [3, 4]);
      expect(await repo.buscar(limit: 2, offset: 4), isEmpty);
    });

    test('texto en nombre, código, barcode y código alterno', () async {
      expect(ids(await repo.buscar(query: 'leche')), [1, 3]);
      expect(ids(await repo.buscar(query: 'ref-2')), [2]);
      expect(ids(await repo.buscar(query: '7703')), [3]);
      expect(ids(await repo.buscar(query: 'emp-caf')), [4]);
    });

    test('% y _ se buscan literales', () async {
      expect(ids(await repo.buscar(query: '50%_')), [2]);
      expect(await repo.buscar(query: '%'), hasLength(1));
    });

    test('filtro por productos de la orden', () async {
      expect(
        ids(
          await repo.buscar(filtro: const FiltroCatalogo(productIds: {2, 4})),
        ),
        [2, 4],
      );
    });

    test('filtro por categorías + texto', () async {
      const lacteos = FiltroCatalogo(categorias: {'Lácteos'});
      expect(ids(await repo.buscar(filtro: lacteos)), [1, 3]);
      expect(ids(await repo.buscar(filtro: lacteos, query: 'deslac')), [3]);
    });

    test('productos y categorías a la vez → unión (conteo combined)', () async {
      expect(
        ids(
          await repo.buscar(
            filtro: const FiltroCatalogo(
              productIds: {4},
              categorias: {'Granos'},
            ),
          ),
        ),
        [2, 4],
      );
    });

    test('filtro vacío (orden sin productos) → nada', () async {
      expect(
        await repo.buscar(filtro: const FiltroCatalogo(productIds: {})),
        isEmpty,
      );
      expect(
        await repo.buscar(filtro: const FiltroCatalogo(categorias: {})),
        isEmpty,
      );
    });

    test(
      'muchos productIds no chocan con el límite de 999 variables',
      () async {
        final muchos = {for (var i = 1; i <= 5000; i++) i};
        expect(
          ids(await repo.buscar(filtro: FiltroCatalogo(productIds: muchos))),
          [1, 2, 3, 4],
        );
      },
    );
  });

  group('buscar filas de stock (porProducto: false)', () {
    test('una fila por lote/ubicación, ubicación actual primero y luego 0',
        () async {
      final r = await repo.buscar(porProducto: false, ubicacionPrimero: 9);
      expect(
        r.map((p) => '${p.productId}@${p.locationId}').toList(),
        ['1@9', '2@0', '3@0', '4@0', '1@4'],
      );
    });

    test('con texto y filtro', () async {
      final r = await repo.buscar(
        query: 'leche',
        porProducto: false,
        filtro: const FiltroCatalogo(productIds: {1}),
      );
      expect(r.map((p) => p.locationId).toList(), [4, 9]);
    });
  });

  group('FiltroCatalogo.incluye (validación de un escaneo)', () {
    Future<Product> p(String codigo) async => (await repo.getByCodigo(codigo))!;

    test('sin filtro acepta todo', () async {
      expect(FiltroCatalogo.todos.incluye(await p('7702')), isTrue);
    });

    test('por productos, por categorías y unión', () async {
      const ids = FiltroCatalogo(productIds: {2});
      const cats = FiltroCatalogo(categorias: {'Lácteos'});
      const union = FiltroCatalogo(productIds: {2}, categorias: {'Lácteos'});

      expect(ids.incluye(await p('7702')), isTrue);
      expect(ids.incluye(await p('7703')), isFalse);
      expect(cats.incluye(await p('7703')), isTrue);
      expect(cats.incluye(await p('7702')), isFalse);
      expect(union.incluye(await p('7702')), isTrue);
      expect(union.incluye(await p('7703')), isTrue);
      expect(union.incluye(await p('CAF')), isFalse);
    });
  });

  group('buscarEtiquetas', () {
    test('proyección de 4 columnas, una fila por producto, paginada', () async {
      final p1 = await repo.buscarEtiquetas(limit: 2);
      final p2 = await repo.buscarEtiquetas(limit: 2, offset: 2);
      expect(p1.map((r) => r[ProductInventarioTable.columnProductId]), [1, 2]);
      expect(p2.map((r) => r[ProductInventarioTable.columnProductId]), [3, 4]);
      expect(p1.first.keys.toSet(), {
        ProductInventarioTable.columnProductId,
        ProductInventarioTable.columnProductName,
        ProductInventarioTable.columnProductCode,
        ProductInventarioTable.columnBarcode,
      });
    });

    test('misma búsqueda que buscar (incluye códigos alternos)', () async {
      final r = await repo.buscarEtiquetas(query: 'emp-caf');
      expect(r.map((e) => e[ProductInventarioTable.columnProductId]), [4]);
    });
  });

  group('contar', () {
    test('cuenta productos, no filas de stock', () async {
      expect(await repo.contar(), 4);
      expect(await repo.contar(query: 'leche'), 2);
      expect(
        await repo.contar(filtro: const FiltroCatalogo(productIds: {})),
        0,
      );
    });
  });
}
