import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wms_app/core/services/productos_sync_service.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_barcode/barcodes_inventario_table.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/product_inventario_repository.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/product_inventario_table.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/bloc/crate_transfer_bloc.dart';

class _Db extends Mock implements DataBaseSqlite {}

class _Sync extends Mock implements ProductosSyncService {}

/// Crear Transferencia consulta SQLite por páginas en vez de cargar el
/// catálogo completo en memoria (plan_fix_oom_catalogo_productos, fase 3).
void main() {
  late Database db;
  late CreateTransferBloc bloc;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final sync = _Sync();
    when(() => sync.isLoading).thenReturn(false);
    ProductosSyncService.instance = sync;
  });

  Future<void> crearBloc({bool conProductos = true}) async {
    db = await openDatabase(inMemoryDatabasePath);
    await db.execute(ProductInventarioTable.createTable());
    await db.execute(BarcodesInventarioTable.createTable());
    for (final sql in [
      ...ProductInventarioTable.indices,
      ...BarcodesInventarioTable.indices,
    ]) {
      await db.execute(sql);
    }
    if (conProductos) {
      final batch = db.batch();
      // 80 productos; los múltiplos de 10 son de "ACME" (maneja propietario).
      for (var i = 1; i <= 80; i++) {
        batch.insert(ProductInventarioTable.tableName, {
          ProductInventarioTable.columnProductId: i,
          ProductInventarioTable.columnProductName: 'Producto $i',
          ProductInventarioTable.columnProductCode: 'REF-$i',
          ProductInventarioTable.columnBarcode: '770$i',
          ProductInventarioTable.columnLocationId: i == 40 ? 5 : 0,
          ProductInventarioTable.columnManejoPropietario: i % 10 == 0 ? 1 : 0,
          ProductInventarioTable.columnPropietario: i % 10 == 0 ? 'ACME' : '',
        });
      }
      batch.insert(BarcodesInventarioTable.tableName, {
        BarcodesInventarioTable.columnIdProduct: 7,
        BarcodesInventarioTable.columnBarcode: 'CAJA-7',
      });
      await batch.commit(noResult: true);
    }

    final dbMock = _Db();
    when(() => dbMock.getDatabaseInstance()).thenAnswer((_) async => db);
    when(() => dbMock.productoInventarioRepository)
        .thenReturn(ProductInventarioRepository(database: dbMock));
    bloc = CreateTransferBloc()..db = dbMock;
  }

  tearDown(() async {
    await bloc.close();
    await db.close();
  });

  Future<void> esperarResultados() =>
      bloc.stream.firstWhere((s) => s is SearchProductSuccess);

  test('búsqueda paginada: 50 y luego el resto', () async {
    await crearBloc();
    bloc.add(SearchProductEvent(''));
    await esperarResultados();
    expect(bloc.productosFilters, hasLength(50));
    expect(bloc.hayMasProductos, isTrue);

    bloc.add(LoadMoreProductsCreateTransferEvent());
    await esperarResultados();
    expect(bloc.productosFilters, hasLength(80));
    expect(bloc.hayMasProductos, isFalse);
  });

  test('la ubicación de origen va primero', () async {
    await crearBloc();
    bloc.currentUbication = ResultUbicaciones(id: 5);
    bloc.add(SearchProductEvent(''));
    await esperarResultados();
    expect(bloc.productosFilters.first.productId, 40);
  });

  test('filtro de propietario en SQL', () async {
    await crearBloc();
    expect(await bloc.propietariosProductos(), ['ACME']);

    bloc.propietarioProductos = 'ACME';
    bloc.add(SearchProductEvent(''));
    await esperarResultados();
    expect(
      bloc.productosFilters.map((p) => p.productId).toList(),
      [10, 20, 30, 40, 50, 60, 70, 80],
    );

    bloc.add(SearchProductEvent('producto 3'));
    await esperarResultados();
    expect(bloc.productosFilters.map((p) => p.productId).toList(), [30]);
  });

  test('escaneo por barcode, código o código alterno', () async {
    await crearBloc();
    expect((await bloc.buscarProductoEscaneado('7703'))?.productId, 3);
    expect((await bloc.buscarProductoEscaneado('ref-4'))?.productId, 4);
    expect((await bloc.buscarProductoEscaneado('caja-7'))?.productId, 7);
    expect(await bloc.buscarProductoEscaneado('NO-EXISTE'), isNull);
  });

  test('sin catálogo descargado avisa con GetProductsFailure', () async {
    await crearBloc(conProductos: false);
    bloc.add(GetProductsFromDBEvent());
    await bloc.stream.firstWhere((s) => s is GetProductsFailure);
  });
}
