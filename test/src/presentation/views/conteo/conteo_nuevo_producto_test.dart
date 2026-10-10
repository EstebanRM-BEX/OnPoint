import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_barcode/barcodes_inventario_table.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/product_inventario_repository.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/product_inventario_table.dart';
import 'package:wms_app/src/presentation/views/conteo/models/conteo_response_model.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/bloc/conteo_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';

class _Db extends Mock implements DataBaseSqlite {}

/// "Nuevo producto" de Conteo consulta SQLite por páginas en vez de cargar
/// el catálogo completo en memoria (plan_fix_oom_catalogo_productos, fase 2).
void main() {
  late Database db;
  late ConteoBloc bloc;

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
    // 120 productos; el 1 también tiene stock en la ubicación 7.
    for (var i = 1; i <= 120; i++) {
      batch.insert(ProductInventarioTable.tableName, {
        ProductInventarioTable.columnProductId: i,
        ProductInventarioTable.columnProductName: 'Producto $i',
        ProductInventarioTable.columnProductCode: 'REF-$i',
        ProductInventarioTable.columnBarcode: '770$i',
        ProductInventarioTable.columnCategory: i.isEven ? 'Pares' : 'Impares',
        ProductInventarioTable.columnLocationId: 0,
      });
    }
    batch.insert(ProductInventarioTable.tableName, {
      ProductInventarioTable.columnProductId: 1,
      ProductInventarioTable.columnProductName: 'Producto 1',
      ProductInventarioTable.columnBarcode: '7701',
      ProductInventarioTable.columnCategory: 'Impares',
      ProductInventarioTable.columnLocationId: 7,
      ProductInventarioTable.columnLotId: 33,
    });
    await batch.commit(noResult: true);

    final dbMock = _Db();
    when(() => dbMock.getDatabaseInstance()).thenAnswer((_) async => db);
    when(() => dbMock.productoInventarioRepository)
        .thenReturn(ProductInventarioRepository(database: dbMock));

    bloc = ConteoBloc()
      ..db = dbMock
      ..ordenConteo = DatumConteo(filterType: 'general');
  });

  tearDown(() async {
    await bloc.close();
    await db.close();
  });

  Future<void> esperarResultados() =>
      bloc.stream.firstWhere((s) => s is SearchProductSuccess);

  group('filtroProductosNuevo según filterType', () {
    setUp(() {
      bloc
        ..productosOrdenConteo = [Allowed(id: 3), Allowed(id: 5)]
        ..categoriasConteo = [Allowed(name: 'Pares')];
    });

    FiltroCatalogo filtro(String? tipo) {
      bloc.ordenConteo = DatumConteo(filterType: tipo);
      return bloc.filtroProductosNuevo;
    }

    test('general y location: todo el catálogo', () {
      expect(filtro('general').productIds, isNull);
      expect(filtro('location').categorias, isNull);
    });

    test('product, category y combined', () {
      expect(filtro('product').productIds, {3, 5});
      expect(filtro('category').categorias, {'Pares'});
      final combined = filtro('combined');
      expect(combined.productIds, {3, 5});
      expect(combined.categorias, {'Pares'});
    });

    test('tipo desconocido: ningún producto', () {
      expect(filtro(null).vacio, isTrue);
    });
  });

  group('búsqueda paginada', () {
    test('primera página de 50 y luego el resto, sin duplicar', () async {
      bloc.add(SearchProductEvent(''));
      await esperarResultados();
      expect(bloc.productosFiltersSearch, hasLength(50));
      expect(bloc.hayMasProductos, isTrue);

      bloc.add(LoadMoreProductsConteoEvent());
      await esperarResultados();
      bloc.add(LoadMoreProductsConteoEvent());
      await esperarResultados();

      // 121 filas de stock (el producto 1 está en dos ubicaciones).
      expect(bloc.productosFiltersSearch, hasLength(121));
      expect(bloc.hayMasProductos, isFalse);
      expect(
        bloc.productosFiltersSearch.map((p) => p.productId).toSet(),
        hasLength(120),
      );
    });

    test('la ubicación elegida va primero', () async {
      bloc.currentUbication = ResultUbicaciones(id: 7);
      bloc.add(SearchProductEvent(''));
      await esperarResultados();
      expect(bloc.productosFiltersSearch.first.locationId, 7);
      expect(bloc.productosFiltersSearch.first.lotId, 33);
    });

    test('al escribir rápido gana la última búsqueda', () async {
      bloc
        ..add(SearchProductEvent('Producto 1'))
        ..add(SearchProductEvent('Producto 11'))
        ..add(SearchProductEvent('Producto 119'));
      await esperarResultados();
      expect(
        bloc.productosFiltersSearch.map((p) => p.productId).toList(),
        [119],
      );
    });

    test('respeta el filtro de la orden', () async {
      bloc
        ..ordenConteo = DatumConteo(filterType: 'product')
        ..productosOrdenConteo = [Allowed(id: 4), Allowed(id: 9)];
      bloc.add(SearchProductEvent(''));
      await esperarResultados();
      expect(
        bloc.productosFiltersSearch.map((p) => p.productId).toList(),
        [4, 9],
      );
      expect(bloc.hayMasProductos, isFalse);
    });
  });

  group('buscarProductoEscaneado', () {
    test('por barcode o código, sin distinguir mayúsculas', () async {
      expect((await bloc.buscarProductoEscaneado('7704'))?.productId, 4);
      expect((await bloc.buscarProductoEscaneado('ref-8'))?.productId, 8);
    });

    test('código de la orden (listAllOfBarcodes)', () async {
      bloc.listAllOfBarcodes = [Barcodes(idProduct: 12, barcode: 'CAJA-12')];
      expect((await bloc.buscarProductoEscaneado('caja-12'))?.productId, 12);
    });

    test('no permitido por la orden o inexistente → null', () async {
      bloc
        ..ordenConteo = DatumConteo(filterType: 'category')
        ..categoriasConteo = [Allowed(name: 'Pares')];
      expect((await bloc.buscarProductoEscaneado('7704'))?.productId, 4);
      expect(await bloc.buscarProductoEscaneado('7703'), isNull);
      expect(await bloc.buscarProductoEscaneado('NO-EXISTE'), isNull);
    });

    test('prefiere la fila de la ubicación elegida', () async {
      bloc.currentUbication = ResultUbicaciones(id: 7);
      expect((await bloc.buscarProductoEscaneado('7701'))?.locationId, 7);
    });
  });
}
