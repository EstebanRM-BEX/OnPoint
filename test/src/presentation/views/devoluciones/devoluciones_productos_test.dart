import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_barcode/barcodes_inventario_table.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/product_inventario_repository.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/product_inventario_table.dart';
import 'package:wms_app/src/presentation/views/devoluciones/models/product_devolucion_model.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/bloc/devoluciones_bloc.dart';

class _Db extends Mock implements DataBaseSqlite {}

/// Devoluciones consulta SQLite (búsqueda paginada y escaneo indexado) en vez
/// de cargar el catálogo completo en memoria (plan_fix_oom_catalogo_productos,
/// fase 4).
void main() {
  late Database db;
  late DevolucionesBloc bloc;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
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
    final batch = db.batch();
    // 70 productos, cada uno con stock en dos ubicaciones (140 filas).
    for (var i = 1; i <= 70; i++) {
      for (final loc in [1, 2]) {
        batch.insert(ProductInventarioTable.tableName, {
          ProductInventarioTable.columnProductId: i,
          ProductInventarioTable.columnProductName: 'Producto $i',
          ProductInventarioTable.columnProductCode: 'REF-$i',
          ProductInventarioTable.columnBarcode: '770$i',
          ProductInventarioTable.columnLocationId: loc,
          ProductInventarioTable.columnProductracking: i == 3 ? 'lot' : 'none',
        });
      }
    }
    batch.insert(BarcodesInventarioTable.tableName, {
      BarcodesInventarioTable.columnIdProduct: 9,
      BarcodesInventarioTable.columnBarcode: 'caja-9',
    });
    await batch.commit(noResult: true);

    final dbMock = _Db();
    when(() => dbMock.getDatabaseInstance()).thenAnswer((_) async => db);
    when(() => dbMock.productoInventarioRepository)
        .thenReturn(ProductInventarioRepository(database: dbMock));
    bloc = DevolucionesBloc()..db = dbMock;
  });

  tearDown(() async {
    await bloc.close();
    await db.close();
  });

  Future<DevolucionesState> esperar(bool Function(DevolucionesState) f) =>
      bloc.stream.firstWhere(f);

  test('búsqueda paginada: una fila por producto', () async {
    bloc.add(SearchProductEvent(''));
    await esperar((s) => s is SearchProductSuccess);
    expect(bloc.productosFilters, hasLength(50));
    expect(bloc.hayMasProductos, isTrue);

    bloc.add(LoadMoreProductsDevolucionEvent());
    await esperar((s) => s is SearchProductSuccess);
    expect(bloc.productosFilters, hasLength(70));
    expect(
      bloc.productosFilters.map((p) => p.productId).toSet(),
      hasLength(70),
    );
    expect(bloc.hayMasProductos, isFalse);
  });

  test('escaneo en mayúsculas (así lo manda la pantalla)', () async {
    bloc.add(GetProductEvent('REF-12', false));
    await esperar((s) => s is GetProductSuccess);
    expect(bloc.currentProduct.productId, 12);
  });

  test('escaneo por código alterno', () async {
    bloc.add(GetProductEvent('CAJA-9', false));
    await esperar((s) => s is GetProductSuccess);
    expect(bloc.currentProduct.productId, 9);
  });

  test('selección manual por id', () async {
    bloc.add(GetProductEvent('', true, 3));
    await esperar((s) => s is GetProductSuccess);
    expect(bloc.currentProduct.productId, 3);
    expect(bloc.currentProduct.tracking, 'lot');
  });

  test('producto ya agregado a la devolución → GetProductExists', () async {
    bloc.productosDevolucion = [ProductDevolucion(productId: 5)];
    bloc.add(GetProductEvent('7705', false));
    final s = await esperar((s) => s is GetProductExists) as GetProductExists;
    expect(s.product.productId, 5);
  });

  test('inexistente → GetProductFailure', () async {
    bloc.add(GetProductEvent('NO-EXISTE', false));
    await esperar((s) => s is GetProductFailure);
  });

  test('escaneos seguidos se resuelven en orden', () async {
    final exitos = <int?>[];
    final sub = bloc.stream
        .where((s) => s is GetProductSuccess)
        .listen((s) => exitos.add((s as GetProductSuccess).product.productId));
    bloc
      ..add(GetProductEvent('7701', false))
      ..add(GetProductEvent('7702', false));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await sub.cancel();
    expect(exitos, [1, 2]);
  });
}
