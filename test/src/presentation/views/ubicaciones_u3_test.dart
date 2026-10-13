import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/features/inventario/data/datasources/inventario_local_data_source.dart';
import 'package:wms_app/features/inventario/data/datasources/inventario_remote_data_source.dart';
import 'package:wms_app/features/inventario/data/repositories/inventario_repository_impl.dart';
import 'package:wms_app/features/inventario/domain/usecases/buscar_producto_por_codigo.dart';
import 'package:wms_app/features/inventario/domain/usecases/buscar_productos_inventario.dart';
import 'package:wms_app/features/inventario/domain/usecases/buscar_ubicaciones_inventario.dart';
import 'package:wms_app/features/inventario/domain/usecases/crear_lote_inventario.dart';
import 'package:wms_app/features/inventario/domain/usecases/enviar_producto_inventario.dart';
import 'package:wms_app/features/inventario/domain/usecases/get_barcodes_producto.dart';
import 'package:wms_app/features/inventario/domain/usecases/get_configuracion_usuario_inventario.dart';
import 'package:wms_app/features/inventario/domain/usecases/get_lotes_producto.dart';
import 'package:wms_app/features/inventario/domain/usecases/get_productos_count.dart';
import 'package:wms_app/features/inventario/domain/usecases/get_ubicacion_por_barcode.dart';
import 'package:wms_app/features/inventario/presentation/bloc/inventario_bloc.dart'
    as inv;
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/product_inventario_repository.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_ubicaciones/ubicaciones_repository.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_ubicaciones/ubicaciones_table.dart';
import 'package:wms_app/src/presentation/views/conteo/models/conteo_response_model.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/bloc/conteo_bloc.dart'
    as conteo;
import 'package:wms_app/src/presentation/views/devoluciones/screens/bloc/devoluciones_bloc.dart'
    as dev;

class _Db extends Mock implements DataBaseSqlite {}

class _Remote extends Mock implements InventarioRemoteDataSource {}

class _Net extends Mock implements NetworkInfo {}

class _BuscarProductos extends Mock implements BuscarProductosInventario {}

class _PorCodigo extends Mock implements BuscarProductoPorCodigo {}

class _Count extends Mock implements GetProductosCount {}

class _Lotes extends Mock implements GetLotesProducto {}

class _Enviar extends Mock implements EnviarProductoInventario {}

class _Crear extends Mock implements CrearLoteInventario {}

class _Barcodes extends Mock implements GetBarcodesProducto {}

class _Config extends Mock implements GetConfiguracionUsuarioInventario {}

/// U3 (docs/plan_ubicaciones_sqlite.md): Conteo, Devoluciones e Inventario
/// rápido consultan las ubicaciones por página en SQLite.
void main() {
  late Database db;
  late _Db dbMock;
  late UbicacionesRepository repo;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath);
    await db.execute(UbicacionesTable.createTable());
    for (final sql in UbicacionesTable.indices) {
      await db.execute(sql);
    }
    final b = db.batch();
    for (var i = 1; i <= 120; i++) {
      b.insert(UbicacionesTable.tableName, {
        UbicacionesTable.columnId: i,
        UbicacionesTable.columnName: 'UB-${i.toString().padLeft(3, '0')}',
        UbicacionesTable.columnBarcode: 'LOC$i',
        UbicacionesTable.columnIdWarehouse: i.isEven ? 1 : 2,
        UbicacionesTable.columnWarehouseName: i.isEven ? 'Bodega Norte' : 'Sur',
      });
    }
    await b.commit(noResult: true);
    dbMock = _Db();
    when(() => dbMock.getDatabaseInstance()).thenAnswer((_) async => db);
    repo = UbicacionesRepository(database: dbMock);
    when(() => dbMock.ubicacionesRepository).thenReturn(repo);
    when(() => dbMock.productoInventarioRepository)
        .thenReturn(ProductInventarioRepository(database: dbMock));
  });

  tearDown(() => db.close());

  group('Conteo', () {
    late conteo.ConteoBloc bloc;
    setUp(() => bloc = conteo.ConteoBloc()..db = dbMock);
    tearDown(() => bloc.close());

    test('general: maestra paginada y escaneo limitado al almacén', () async {
      bloc.ordenConteo = DatumConteo(filterType: 'general', warehouseId: 1);
      bloc.add(conteo.LoadNewProductEvent());
      await bloc.stream.firstWhere((s) => s is conteo.LoadLocationsSuccess);
      expect(bloc.ubicacionesFiltersSearch, hasLength(50));
      expect(bloc.ubicacionesFiltersSearch.every((u) => u.idWarehouse == 1),
          isTrue);
      expect(bloc.hayMasUbicaciones, isTrue);

      bloc.add(conteo.LoadMoreUbicacionesConteoEvent());
      await bloc.stream.firstWhere((s) => s is conteo.SearchLocationSuccess);
      expect(bloc.ubicacionesFiltersSearch, hasLength(60));

      expect((await bloc.buscarUbicacionEscaneada('loc8'))?.id, 8);
      // LOC7 es del almacén 2: la orden no la permite.
      expect(await bloc.buscarUbicacionEscaneada('LOC7'), isNull);
    });

    test('location: solo las ubicaciones de la orden, en memoria', () async {
      bloc
        ..ordenConteo = DatumConteo(filterType: 'location')
        ..ubicacionesConteo = [
          Allowed(id: 3, name: 'UB-003', barcode: 'LOC3'),
          Allowed(id: 4, name: 'UB-004', barcode: 'LOC4'),
        ];
      bloc.add(conteo.LoadNewProductEvent());
      await bloc.stream.firstWhere((s) => s is conteo.LoadNewProductSuccess);
      expect(bloc.ubicacionesFiltersSearch.map((u) => u.id), [3, 4]);
      expect(bloc.hayMasUbicaciones, isFalse);

      final v = bloc.versionUbicaciones;
      bloc.add(conteo.SearchLocationEvent('004'));
      await bloc.stream.firstWhere((s) => s is conteo.SearchLocationSuccess);
      expect(bloc.ubicacionesFiltersSearch.map((u) => u.id), [4]);
      expect(bloc.versionUbicaciones, greaterThan(v));

      expect((await bloc.buscarUbicacionEscaneada('loc3'))?.id, 3);
      expect(await bloc.buscarUbicacionEscaneada('LOC9'), isNull);
    });
  });

  group('Devoluciones', () {
    late dev.DevolucionesBloc bloc;
    setUp(() => bloc = dev.DevolucionesBloc()..db = dbMock);
    tearDown(() => bloc.close());

    test('carga, filtro de almacén, cargar más y escaneo', () async {
      bloc.add(dev.LoadLocationsEvent());
      await bloc.stream.firstWhere((s) => s is dev.LoadLocationsSuccessState);
      expect(bloc.ubicacionesFilters, hasLength(50));

      bloc.add(dev.FilterUbicacionesEvent('norte'));
      await bloc.stream.firstWhere((s) => s is dev.FilterLocationsSuccess);
      expect(bloc.ubicacionesFilters.every((u) => u.idWarehouse == 1), isTrue);

      bloc.add(dev.LoadMoreUbicacionesDevolucionEvent());
      await bloc.stream.firstWhere((s) => s is dev.SearchLocationSuccess);
      expect(bloc.ubicacionesFilters, hasLength(60));

      expect((await bloc.buscarUbicacionPorBarcode('LOC11'))?.id, 11);
    });
  });

  group('Inventario rápido (datasource → repositorio → bloc)', () {
    late inv.InventarioBloc bloc;
    setUp(() {
      final repositorio = InventarioRepositoryImpl(
        remoteDataSource: _Remote(),
        localDataSource: InventarioLocalDataSourceImpl(dbMock),
        networkInfo: _Net(),
      );
      bloc = inv.InventarioBloc(
        buscarProductos: _BuscarProductos(),
        buscarProductoPorCodigoUseCase: _PorCodigo(),
        getProductosCount: _Count(),
        buscarUbicaciones: BuscarUbicacionesInventario(repositorio),
        getUbicacionPorBarcode: GetUbicacionPorBarcode(repositorio),
        getLotesProducto: _Lotes(),
        enviarProductoInventario: _Enviar(),
        crearLoteInventario: _Crear(),
        getBarcodesProducto: _Barcodes(),
        getConfiguracionUsuarioInventario: _Config(),
      );
    });
    tearDown(() => bloc.close());

    test('carga, almacén + búsqueda combinados, cargar más y escaneo',
        () async {
      bloc.add(inv.GetLocationsEvent());
      await bloc.stream.firstWhere((s) => s is inv.LoadLocationsSuccess);
      expect(bloc.hayUbicaciones, isTrue);
      expect(bloc.ubicacionesFilters, hasLength(50));

      bloc.add(inv.FilterUbicacionesAlmacenEvent('Sur'));
      await bloc.stream.firstWhere((s) => s is inv.FilterUbicacionesSuccess);
      bloc.add(inv.SearchLocationEvent('UB-01'));
      await bloc.stream.firstWhere((s) => s is inv.SearchLocationSuccess);
      expect(bloc.ubicacionesFilters.map((u) => u.id), [11, 13, 15, 17, 19]);

      bloc.add(inv.SearchLocationEvent(''));
      await bloc.stream.firstWhere((s) => s is inv.SearchLocationSuccess);
      bloc.add(inv.CargarMasUbicacionesEvent());
      await bloc.stream.firstWhere((s) => s is inv.SearchLocationSuccess);
      expect(bloc.ubicacionesFilters, hasLength(60));
      expect(bloc.hayMasUbicaciones, isFalse);

      expect((await bloc.buscarUbicacionPorBarcode(' loc42 '))?.id, 42);
    });
  });
}
