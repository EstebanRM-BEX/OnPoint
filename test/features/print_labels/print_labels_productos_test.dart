import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wms_app/features/print_labels/presentation/bloc/print_labels_bloc.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_barcode/barcodes_inventario_table.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/product_inventario_repository.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/product_inventario_table.dart';

class _Db extends Mock implements DataBaseSqlite {}

/// Impresión de etiquetas consulta el catálogo por páginas en SQLite en vez
/// de cargar los ~24 mil productos en memoria.
void main() {
  late Database db;
  late PrintLabelsBloc bloc;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<void> crear({int productos = 80}) async {
    db = await openDatabase(inMemoryDatabasePath);
    await db.execute(ProductInventarioTable.createTable());
    await db.execute(BarcodesInventarioTable.createTable());
    final batch = db.batch();
    for (var i = 1; i <= productos; i++) {
      // Dos filas de stock por producto: el listado muestra una.
      for (final loc in [1, 2]) {
        batch.insert(ProductInventarioTable.tableName, {
          ProductInventarioTable.columnProductId: i,
          ProductInventarioTable.columnProductName: 'Producto $i',
          ProductInventarioTable.columnProductCode: 'REF-$i',
          ProductInventarioTable.columnBarcode: '770$i',
          ProductInventarioTable.columnLocationId: loc,
        });
      }
    }
    await batch.commit(noResult: true);
    final dbMock = _Db();
    when(() => dbMock.getDatabaseInstance()).thenAnswer((_) async => db);
    when(() => dbMock.productoInventarioRepository)
        .thenReturn(ProductInventarioRepository(database: dbMock));
    bloc = PrintLabelsBloc()..db = dbMock;
  }

  tearDown(() async {
    await bloc.close();
    await db.close();
  });

  Future<void> esperar<T>() => bloc.stream.firstWhere((s) => s is T);

  test('primera página y luego el resto, un producto por fila', () async {
    await crear();
    bloc.add(GetProductsList());
    await esperar<GetProductsSuccess>();
    expect(bloc.productosFilters, hasLength(50));
    expect(bloc.hayCatalogo, isTrue);
    expect(bloc.hayMasProductos, isTrue);

    bloc.add(LoadMoreProductsEvent());
    await esperar<SearchProductSuccess>();
    expect(bloc.productosFilters, hasLength(80));
    expect(bloc.productosFilters.map((p) => p.productId).toSet(), hasLength(80));
    expect(bloc.hayMasProductos, isFalse);
  });

  test('búsqueda por nombre o código, sin distinguir mayúsculas', () async {
    await crear();
    bloc.add(SearchProductEvent('ref-7'));
    await esperar<SearchProductSuccess>();
    expect(
      bloc.productosFilters.map((p) => p.productId),
      [7, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79],
    );
  });

  test('gana la última búsqueda', () async {
    await crear();
    bloc
      ..add(SearchProductEvent('producto 1'))
      ..add(SearchProductEvent('producto 80'));
    await esperar<SearchProductSuccess>();
    expect(bloc.productosFilters.map((p) => p.productId), [80]);
  });

  test('la selección se conserva entre búsquedas', () async {
    await crear();
    bloc.add(AddSelectedProductEvent(5));
    await esperar<SearchProductSuccess>();
    bloc.add(SearchProductEvent('producto 9'));
    await esperar<SearchProductSuccess>();
    expect(bloc.selectedProducts, {5: 1});
    expect(bloc.expandedResIds, [5]);
  });

  test('sin catálogo descargado → GetProductsFailure', () async {
    await crear(productos: 0);
    bloc.add(GetProductsList());
    await esperar<GetProductsFailure>();
    expect(bloc.hayCatalogo, isFalse);
  });
}
