import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/bloc/location_dest/recepcion_multiusuario_location_dest_bloc.dart'
    as multi;
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_ubicaciones/ubicaciones_repository.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_ubicaciones/ubicaciones_table.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/batchs/bloc/recepcion_batch_bloc.dart'
    as batch;
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/bloc/recepcion_bloc.dart'
    as individual;

class _Db extends Mock implements DataBaseSqlite {}

/// Recepción (individual, batch y multiusuario) consulta las ubicaciones
/// destino por página en SQLite (docs/plan_ubicaciones_sqlite.md, U1).
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
    // 120 ubicaciones: las pares en "Bodega Norte", las impares en "Sur".
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
  });

  tearDown(() => db.close());

  group('Recepción individual (legacy)', () {
    late individual.RecepcionBloc bloc;
    setUp(() => bloc = individual.RecepcionBloc()..db = dbMock);
    tearDown(() => bloc.close());

    test('carga, cargar más y escaneo', () async {
      bloc.add(individual.GetLocationsDestEvent());
      await bloc.stream.firstWhere((s) => s is individual.LoadLocationsSuccess);
      expect(bloc.ubicacionesFilters, hasLength(50));
      expect(bloc.hayMasUbicaciones, isTrue);

      bloc.add(individual.LoadMoreUbicacionesEvent());
      await bloc.stream
          .firstWhere((s) => s is individual.SearchLocationSuccess);
      expect(bloc.ubicacionesFilters, hasLength(100));

      expect((await bloc.buscarUbicacionPorBarcode('loc7'))?.id, 7);
    });

    test('filtro "almacén contiene" y búsqueda que lo quita', () async {
      bloc.add(individual.FilterUbicacionesAlmacenEvent('norte'));
      await bloc.stream
          .firstWhere((s) => s is individual.FilterUbicacionesSuccess);
      expect(bloc.selectedAlmacen, 'norte');
      expect(
        bloc.ubicacionesFilters.every((u) => u.warehouseName == 'Bodega Norte'),
        isTrue,
      );

      bloc.add(individual.SearchLocationEvent('UB-11'));
      await bloc.stream
          .firstWhere((s) => s is individual.SearchLocationSuccess);
      expect(bloc.selectedAlmacen, '');
      // Busca en todos los almacenes: UB-110 … UB-119 (pares e impares).
      expect(bloc.ubicacionesFilters.map((u) => u.id),
          [110, 111, 112, 113, 114, 115, 116, 117, 118, 119]);
    });
  });

  group('Recepción batch (legacy)', () {
    late batch.RecepcionBatchBloc bloc;
    setUp(() => bloc = batch.RecepcionBatchBloc()..db = dbMock);
    tearDown(() => bloc.close());

    test('gana la última búsqueda y el escaneo usa el índice', () async {
      bloc
        ..add(batch.SearchLocationEvent('UB-1'))
        ..add(batch.SearchLocationEvent('UB-12'))
        ..add(batch.SearchLocationEvent('UB-120'));
      await bloc.stream.firstWhere((s) => s is batch.SearchLocationSuccess);
      expect(bloc.ubicacionesFilters.map((u) => u.id), [120]);
      expect((await bloc.buscarUbicacionPorBarcode('LOC3'))?.id, 3);
    });
  });

  group('Recepción multiusuario', () {
    late multi.RecepcionMultiusuarioLocationDestBloc bloc;
    setUp(() {
      bloc = multi.RecepcionMultiusuarioLocationDestBloc()
        ..repositorio = () => repo;
    });
    tearDown(() => bloc.close());

    Future<multi.RecepcionMultiusuarioLocationDestLoaded> loaded() async =>
        await bloc.stream.firstWhere(
          (s) => s is multi.RecepcionMultiusuarioLocationDestLoaded,
        ) as multi.RecepcionMultiusuarioLocationDestLoaded;

    test('primera página y cargar más', () async {
      bloc.add(const multi.FetchUbicacionesDestEvent());
      var s = await loaded();
      expect(s.ubicaciones, hasLength(50));
      expect(s.hayMas, isTrue);

      bloc.add(const multi.LoadMoreUbicacionesDestEvent());
      s = await loaded();
      expect(s.ubicaciones, hasLength(100));
    });

    test('almacén (exacto) y búsqueda se combinan; version cambia', () async {
      bloc.add(const multi.FetchUbicacionesDestEvent());
      final v0 = (await loaded()).version;

      bloc.add(const multi.FilterUbicacionesAlmacenEvent('Sur'));
      final s1 = await loaded();
      expect(s1.version, greaterThan(v0));
      expect(s1.ubicaciones.every((u) => u.warehouseName == 'Sur'), isTrue);

      bloc.add(const multi.SearchUbicacionDestEvent('UB-01'));
      final s2 = await loaded();
      expect(s2.ubicaciones.map((u) => u.id), [11, 13, 15, 17, 19]);
    });
  });
}
