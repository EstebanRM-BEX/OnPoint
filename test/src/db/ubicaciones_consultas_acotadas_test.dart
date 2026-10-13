import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_ubicaciones/ubicaciones_repository.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_ubicaciones/ubicaciones_table.dart';

class _Db extends Mock implements DataBaseSqlite {}

/// Consultas acotadas de ubicaciones (docs/plan_ubicaciones_sqlite.md, U0).
void main() {
  late Database db;
  late UbicacionesRepository repo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<void> ubicacion(
    int id,
    String name, {
    String? barcode,
    int warehouse = 1,
    String warehouseName = 'BOD1',
    bool muelle = false,
  }) =>
      db.insert(UbicacionesTable.tableName, {
        UbicacionesTable.columnId: id,
        UbicacionesTable.columnName: name,
        UbicacionesTable.columnBarcode: barcode ?? 'LOC$id',
        UbicacionesTable.columnIdWarehouse: warehouse,
        UbicacionesTable.columnWarehouseName: warehouseName,
        UbicacionesTable.columnIsADock: muelle ? 1 : 0,
      });

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath);
    await db.execute(UbicacionesTable.createTable());
    for (final sql in UbicacionesTable.indices) {
      await db.execute(sql);
    }
    final dbMock = _Db();
    when(() => dbMock.getDatabaseInstance()).thenAnswer((_) async => db);
    repo = UbicacionesRepository(database: dbMock);

    await ubicacion(1, 'A-01-01', barcode: 'Bc-A0101');
    await ubicacion(2, 'A-01-02');
    await ubicacion(3, 'A-02-01');
    await ubicacion(4, 'B-01-01', warehouse: 2, warehouseName: 'BOD2');
    await ubicacion(5, 'MUELLE 1', muelle: true);
    await ubicacion(6, 'a-10_x%');
  });

  tearDown(() => db.close());

  List<int?> ids(List<ResultUbicaciones> l) => l.map((u) => u.id).toList();

  group('getByBarcode', () {
    test('sin distinguir mayúsculas', () async {
      expect((await repo.getByBarcode('bc-a0101'))?.id, 1);
      expect((await repo.getByBarcode(' LOC4 '))?.id, 4);
    });

    test('inexistente o vacío → null', () async {
      expect(await repo.getByBarcode('NO'), isNull);
      expect(await repo.getByBarcode(''), isNull);
    });
  });

  group('buscar', () {
    test('ordenado por nombre y paginado', () async {
      expect(ids(await repo.buscar(limit: 3)), [1, 2, 3]);
      expect(ids(await repo.buscar(limit: 3, offset: 3)), [4, 5, 6]);
    });

    test('texto en nombre o barcode, sin distinguir mayúsculas', () async {
      expect(ids(await repo.buscar(query: 'a-01')), [1, 2]);
      expect(ids(await repo.buscar(query: 'loc4')), [4]);
    });

    test('% y _ se buscan literales', () async {
      expect(ids(await repo.buscar(query: '_x%')), [6]);
    });

    test('filtros por almacén (id o nombre), ids y muelles', () async {
      expect(
        ids(await repo.buscar(filtro: const FiltroUbicaciones(warehouseId: 2))),
        [4],
      );
      expect(
        ids(await repo.buscar(
          filtro: const FiltroUbicaciones(warehouseName: 'BOD2'),
        )),
        [4],
      );
      expect(
        ids(await repo.buscar(filtro: const FiltroUbicaciones(ids: {3, 5}))),
        [3, 5],
      );
      expect(
        ids(await repo.buscar(
          filtro: const FiltroUbicaciones(soloMuelles: true),
        )),
        [5],
      );
    });

    test('ids vacío (orden sin ubicaciones) → nada', () async {
      expect(
        await repo.buscar(filtro: const FiltroUbicaciones(ids: {})),
        isEmpty,
      );
      expect(await repo.contar(filtro: const FiltroUbicaciones(ids: {})), 0);
    });

    test('contar con los mismos filtros', () async {
      expect(await repo.contar(), 6);
      expect(await repo.contar(query: 'a-0'), 3);
    });
  });

  group('rango (etiquetas)', () {
    test('prefijo sin distinguir mayúsculas', () async {
      expect(ids(await repo.rango(desde: 'a-01')), [1, 2]);
    });

    test('desde–hasta inclusive', () async {
      expect(ids(await repo.rango(desde: 'A-01-02', hasta: 'a-02-01')), [2, 3]);
    });

    test('acotado por limit', () async {
      expect(await repo.rango(desde: 'a', limit: 2), hasLength(2));
      expect(await repo.rango(desde: ''), isEmpty);
    });
  });

  test('FiltroUbicaciones.incluye usa la misma regla', () async {
    final u = (await repo.getByBarcode('LOC4'))!;
    expect(const FiltroUbicaciones(warehouseId: 2).incluye(u), isTrue);
    expect(const FiltroUbicaciones(warehouseId: 1).incluye(u), isFalse);
    expect(const FiltroUbicaciones(warehouseName: 'BOD2').incluye(u), isTrue);
    expect(FiltroUbicaciones.todas.incluye(u), isTrue);
  });
}
