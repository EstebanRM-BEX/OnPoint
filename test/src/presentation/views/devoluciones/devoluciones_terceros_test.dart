import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/devoluciones/tbl_terceros/terceros_repository.dart';
import 'package:wms_app/src/presentation/providers/db/devoluciones/tbl_terceros/terceros_table.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/bloc/devoluciones_bloc.dart';

class _Db extends Mock implements DataBaseSqlite {}

/// Terceros de Devoluciones (~322 mil en producción): se consultan por página
/// en SQLite en vez de cargarse completos en memoria, y el flujo los revisa
/// una sola vez (plan_fix_oom_catalogo_productos, fase 6).
void main() {
  late Database db;
  late _Db dbMock;
  late TercerosRepository repo;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<void> abrir({int cantidad = 120}) async {
    db = await openDatabase(inMemoryDatabasePath);
    await db.execute(TercerosTable.createTable());
    for (final sql in TercerosTable.indices) {
      await db.execute(sql);
    }
    final batch = db.batch();
    for (var i = 1; i <= cantidad; i++) {
      batch.insert(TercerosTable.tableName, {
        TercerosTable.columnId: i,
        TercerosTable.columnDocument: i == 7 ? 'NIT-ABC' : 'DOC$i',
        TercerosTable.columnName: i == 2 ? 'Distribuidora 50%_x' : 'Tercero $i',
      });
    }
    await batch.commit(noResult: true);

    dbMock = _Db();
    when(() => dbMock.getDatabaseInstance()).thenAnswer((_) async => db);
    repo = TercerosRepository(database: dbMock);
    when(() => dbMock.tercerosRepository).thenReturn(repo);
  }

  tearDown(() => db.close());

  group('TercerosRepository', () {
    setUp(abrir);

    test('buscar: paginado en el orden de la tabla', () async {
      final p1 = await repo.buscar();
      final p3 = await repo.buscar(offset: 100);
      expect(p1.map((t) => t.id), List.generate(50, (i) => i + 1));
      expect(p3, hasLength(20));
    });

    test('buscar: nombre o documento, sin distinguir mayúsculas', () async {
      expect((await repo.buscar(query: 'tercero 11')).map((t) => t.id),
          [11, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119]);
      expect((await repo.buscar(query: 'nit-abc')).map((t) => t.id), [7]);
    });

    test('buscar: % y _ se buscan literales', () async {
      expect((await repo.buscar(query: '50%_')).map((t) => t.id), [2]);
    });

    test('getByDocumento sin distinguir mayúsculas', () async {
      expect((await repo.getByDocumento('nit-abc'))?.id, 7);
      expect((await repo.getByDocumento(' DOC9 '))?.id, 9);
      expect(await repo.getByDocumento('NO-EXISTE'), isNull);
      expect(await repo.getByDocumento(''), isNull);
    });

    test('hayTerceros', () async {
      expect(await repo.hayTerceros(), isTrue);
      await db.delete(TercerosTable.tableName);
      expect(await repo.hayTerceros(), isFalse);
    });
  });

  group('DevolucionesBloc', () {
    late DevolucionesBloc bloc;

    setUp(() async {
      await abrir();
      bloc = DevolucionesBloc()..db = dbMock;
    });

    tearDown(() => bloc.close());

    test('InitializeDevolucionesData revisa los terceros una sola vez',
        () async {
      final exitos = <DevolucionesState>[];
      final sub = bloc.stream
          .where((s) => s is LoadTercerosFromDBSuccess)
          .listen(exitos.add);

      bloc.add(InitializeDevolucionesData());
      await Future<void>.delayed(const Duration(milliseconds: 300));
      // Volver de una sub-pantalla recrea index.dart y repite el evento.
      bloc.add(InitializeDevolucionesData());
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(exitos, hasLength(1));
      expect(bloc.hayTercerosLocales, isTrue);
      await sub.cancel();
    });

    test('búsqueda paginada de terceros', () async {
      bloc.add(SearchTerceroEvent(''));
      await bloc.stream.firstWhere((s) => s is SearchTerceroSuccess);
      expect(bloc.tercerosFilters, hasLength(50));
      expect(bloc.hayMasTerceros, isTrue);

      bloc.add(LoadMoreTercerosEvent());
      await bloc.stream.firstWhere((s) => s is SearchTerceroSuccess);
      bloc.add(LoadMoreTercerosEvent());
      await bloc.stream.firstWhere((s) => s is SearchTerceroSuccess);
      expect(bloc.tercerosFilters, hasLength(120));
      expect(bloc.hayMasTerceros, isFalse);
    });

    test('al escribir rápido gana la última búsqueda', () async {
      bloc
        ..add(SearchTerceroEvent('tercero 1'))
        ..add(SearchTerceroEvent('tercero 12'))
        ..add(SearchTerceroEvent('tercero 120'));
      await bloc.stream.firstWhere((s) => s is SearchTerceroSuccess);
      expect(bloc.tercerosFilters.map((t) => t.id), [120]);
    });

    test('escaneo de contacto/propietario por documento', () async {
      expect((await bloc.buscarTerceroPorDocumento('nit-abc'))?.id, 7);
      expect(await bloc.buscarTerceroPorDocumento('NO-EXISTE'), isNull);
    });
  });
}
