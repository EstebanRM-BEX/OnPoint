import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_ubicaciones/paginador_ubicaciones.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_ubicaciones/ubicaciones_repository.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_ubicaciones/ubicaciones_table.dart';

class _Db extends Mock implements DataBaseSqlite {}

void main() {
  late Database db;
  late PaginadorUbicaciones paginador;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath);
    await db.execute(UbicacionesTable.createTable());
    final batch = db.batch();
    for (var i = 1; i <= 120; i++) {
      batch.insert(UbicacionesTable.tableName, {
        UbicacionesTable.columnId: i,
        UbicacionesTable.columnName: 'UB-${i.toString().padLeft(3, '0')}',
        UbicacionesTable.columnBarcode: 'LOC$i',
        UbicacionesTable.columnWarehouseName: i.isEven ? 'PAR' : 'IMPAR',
      });
    }
    await batch.commit(noResult: true);
    final dbMock = _Db();
    when(() => dbMock.getDatabaseInstance()).thenAnswer((_) async => db);
    final repo = UbicacionesRepository(database: dbMock);
    paginador = PaginadorUbicaciones(() => repo);
  });

  tearDown(() => db.close());

  test('primera página, cargar más hasta el final', () async {
    expect(await paginador.buscar(), isTrue);
    expect(paginador.items, hasLength(50));
    expect(paginador.hayMas, isTrue);
    expect(await paginador.cargarMas(), isTrue);
    expect(await paginador.cargarMas(), isTrue);
    expect(paginador.items, hasLength(120));
    expect(paginador.hayMas, isFalse);
    expect(await paginador.cargarMas(), isFalse);
  });

  test('cargar más respeta la búsqueda y el filtro vigentes', () async {
    await paginador.buscar(
      filtro: const FiltroUbicaciones(warehouseName: 'PAR'),
    );
    await paginador.cargarMas();
    expect(paginador.items, hasLength(60));
    expect(paginador.items.every((u) => u.warehouseName == 'PAR'), isTrue);
  });

  test('una búsqueda que llega tarde se descarta', () async {
    final vieja = paginador.buscar(query: 'UB-0');
    final nueva = paginador.buscar(query: 'UB-120');
    expect(await vieja, isFalse);
    expect(await nueva, isTrue);
    expect(paginador.items.map((u) => u.id), [120]);
  });

  test('version sube con cada búsqueda, no al cargar más', () async {
    await paginador.buscar();
    final v = paginador.version;
    await paginador.cargarMas();
    expect(paginador.version, v);
    await paginador.buscar(query: 'UB-1');
    expect(paginador.version, v + 1);
    paginador.reset();
    expect(paginador.items, isEmpty);
    expect(paginador.version, v + 2);
  });

  test('escaneo por barcode sin distinguir mayúsculas', () async {
    expect((await paginador.porBarcode('loc77'))?.id, 77);
    expect(await paginador.porBarcode('NO'), isNull);
  });
}
