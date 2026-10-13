import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wms_app/features/print_labels/presentation/bloc/print_labels_bloc.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_ubicaciones/ubicaciones_repository.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_ubicaciones/ubicaciones_table.dart';

class _Db extends Mock implements DataBaseSqlite {}

/// Etiquetas de ubicaciones: búsqueda paginada y rango en SQLite
/// (docs/plan_ubicaciones_sqlite.md, U4).
void main() {
  late Database db;
  late PrintLabelsBloc bloc;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<void> crear(int cantidad) async {
    db = await openDatabase(inMemoryDatabasePath);
    await db.execute(UbicacionesTable.createTable());
    for (final sql in UbicacionesTable.indices) {
      await db.execute(sql);
    }
    final b = db.batch();
    for (var i = 1; i <= cantidad; i++) {
      b.insert(UbicacionesTable.tableName, {
        UbicacionesTable.columnId: i,
        // Fuera de orden a propósito: la lista sale ordenada por nombre.
        UbicacionesTable.columnName:
            'A-${(cantidad - i + 1).toString().padLeft(4, '0')}',
        UbicacionesTable.columnBarcode: 'LOC$i',
      });
    }
    await b.commit(noResult: true);
    final dbMock = _Db();
    when(() => dbMock.getDatabaseInstance()).thenAnswer((_) async => db);
    when(() => dbMock.ubicacionesRepository)
        .thenReturn(UbicacionesRepository(database: dbMock));
    bloc = PrintLabelsBloc()..db = dbMock;
  }

  tearDown(() async {
    await bloc.close();
    await db.close();
  });

  test('primera página ordenada por nombre y cargar más', () async {
    await crear(120);
    bloc.add(GetListLocationsEvent());
    await bloc.stream.firstWhere((s) => s is LoadLocationsSuccess);
    expect(bloc.hayUbicaciones, isTrue);
    expect(bloc.ubicacionesFilters.first.name, 'A-0001');
    expect(bloc.ubicacionesFilters, hasLength(50));

    bloc.add(LoadMoreLocationsEvent());
    await bloc.stream.firstWhere((s) => s is SearchLocationSuccess);
    expect(bloc.ubicacionesFilters, hasLength(100));
  });

  test('rango por prefijo y desde–hasta, sin distinguir mayúsculas', () async {
    await crear(120);
    bloc.add(SearchRangeLocationEvent('a-001', ''));
    await bloc.stream.firstWhere((s) => s is SearchRangeLocationSuccess);
    expect(bloc.ubicacionesRange.map((u) => u.name).first, 'A-0010');
    expect(bloc.ubicacionesRange, hasLength(10));
    expect(bloc.rangoEnTope, isFalse);

    bloc.add(SearchRangeLocationEvent('A-0005', 'a-0007'));
    await bloc.stream.firstWhere((s) => s is SearchRangeLocationSuccess);
    expect(bloc.ubicacionesRange.map((u) => u.name),
        ['A-0005', 'A-0006', 'A-0007']);
  });

  test('rango amplio: se corta en el tope y avisa', () async {
    await crear(PrintLabelsBloc.topeRango + 20);
    bloc.add(SearchRangeLocationEvent('A', ''));
    await bloc.stream.firstWhere((s) => s is SearchRangeLocationSuccess);
    expect(bloc.ubicacionesRange, hasLength(PrintLabelsBloc.topeRango));
    expect(bloc.rangoEnTope, isTrue);
  });
}
