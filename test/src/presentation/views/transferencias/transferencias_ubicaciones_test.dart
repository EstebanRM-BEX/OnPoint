import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wms_app/features/transferencia_multiusuario/presentation/bloc/location_dest/transferencia_multiusuario_location_dest_bloc.dart'
    as multi;
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_ubicaciones/ubicaciones_repository.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_ubicaciones/ubicaciones_table.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/bloc/crate_transfer_bloc.dart'
    as crear;
import 'package:wms_app/src/presentation/views/transferencias/modules/transfer-interna/bloc/transferencia_bloc.dart'
    as interna;

class _Db extends Mock implements DataBaseSqlite {}

/// Transferencias (interna, crear y multiusuario) consultan las ubicaciones
/// por página en SQLite (docs/plan_ubicaciones_sqlite.md, U2).
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
  });

  tearDown(() => db.close());

  group('Transferencia interna (legacy)', () {
    late interna.TransferenciaBloc bloc;
    setUp(() => bloc = interna.TransferenciaBloc()..db = dbMock);
    tearDown(() => bloc.close());

    test('carga, filtro "almacén contiene", cargar más y escaneo', () async {
      bloc.add(interna.LoadLocations());
      await bloc.stream.firstWhere((s) => s is interna.LoadLocationsSuccess);
      expect(bloc.ubicacionesFilters, hasLength(50));

      bloc.add(interna.FilterUbicacionesAlmacenEvent('sur'));
      await bloc.stream
          .firstWhere((s) => s is interna.FilterUbicacionesSuccess);
      expect(bloc.ubicacionesFilters.every((u) => u.warehouseName == 'Sur'),
          isTrue);

      bloc.add(interna.LoadMoreUbicacionesTransferEvent());
      await bloc.stream.firstWhere((s) => s is interna.SearchLocationSuccess);
      expect(bloc.ubicacionesFilters, hasLength(60));
      expect(bloc.hayMasUbicaciones, isFalse);

      expect((await bloc.buscarUbicacionPorBarcode('loc8'))?.id, 8);
    });
  });

  group('Crear transferencia (legacy)', () {
    late crear.CreateTransferBloc bloc;
    setUp(() => bloc = crear.CreateTransferBloc()..db = dbMock);
    tearDown(() => bloc.close());

    test('el escaneo no depende de la última búsqueda', () async {
      bloc.add(crear.SearchLocationEvent('UB-12'));
      await bloc.stream.firstWhere((s) => s is crear.SearchLocationSuccess);
      expect(bloc.ubicacionesFilters.map((u) => u.id), [120]);
      // Antes se buscaba en la lista filtrada: LOC5 no se encontraba.
      expect((await bloc.buscarUbicacionPorBarcode('LOC5'))?.id, 5);
    });
  });

  group('Transferencia multiusuario', () {
    late multi.TransferenciaMultiusuarioLocationDestBloc bloc;
    setUp(() {
      bloc = multi.TransferenciaMultiusuarioLocationDestBloc()
        ..repositorio = () => repo;
    });
    tearDown(() => bloc.close());

    Future<multi.TransferenciaMultiusuarioLocationDestLoaded> loaded() async =>
        await bloc.stream.firstWhere(
          (s) => s is multi.TransferenciaMultiusuarioLocationDestLoaded,
        ) as multi.TransferenciaMultiusuarioLocationDestLoaded;

    test('almacén (exacto) + búsqueda, cargar más', () async {
      bloc.add(const multi.FetchTransferenciaUbicacionesDestEvent());
      expect((await loaded()).ubicaciones, hasLength(50));

      bloc.add(
        const multi.FilterTransferenciaUbicacionesAlmacenEvent('Bodega Norte'),
      );
      final s1 = await loaded();
      expect(s1.ubicaciones.every((u) => u.warehouseName == 'Bodega Norte'),
          isTrue);
      expect(s1.hayMas, isTrue);

      bloc.add(const multi.LoadMoreTransferenciaUbicacionesDestEvent());
      final s2 = await loaded();
      expect(s2.ubicaciones, hasLength(60));
      expect(s2.version, s1.version);
    });
  });
}
