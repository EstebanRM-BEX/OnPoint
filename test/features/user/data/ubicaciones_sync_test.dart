import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/features/user/data/datasources/user_local_data_source.dart';
import 'package:wms_app/features/user/data/datasources/user_remote_data_source.dart';
import 'package:wms_app/features/user/data/models/user_location_model.dart';
import 'package:wms_app/features/user/data/repositories/user_repository_impl.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_ubicaciones/ubicaciones_repository.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_ubicaciones/ubicaciones_table.dart';

class _Remote extends Mock implements UserRemoteDataSource {}

class _Local extends Mock implements UserLocalDataSource {}

class _Red extends Mock implements NetworkInfo {}

UserLocationModel _u(int id, {String? barcode}) => UserLocationModel(
  id: id,
  name: 'U$id',
  idWarehouse: 1,
  locationId: 10,
  locationName: 'WH',
  barcode: barcode ?? 'B$id',
);

ResultUbicaciones _r(int id, {String? barcode}) =>
    ResultUbicaciones(id: id, name: 'U$id', barcode: barcode ?? 'B$id');

void main() {
  group('parseUbicacionesSync', () {
    String body(Map<String, dynamic> result) =>
        jsonEncode({'jsonrpc': '2.0', 'id': null, 'result': result});
    final fila = {'id': 1, 'name': 'WH/A', 'barcode': '4090', 'id_warehouse': 1};

    test('servidor anterior (sin server_time) es completo', () {
      final r = parseUbicacionesSync(body({'code': 200, 'result': [fila]}));
      expect(r.full, isTrue);
      expect(r.serverTime, isNull);
      expect(r.ubicaciones.single.id, 1);
    });

    test('incremental con activas', () {
      final r = parseUbicacionesSync(body({
        'code': 200,
        'server_time': '2026-10-09 16:02:11',
        'scope': 'abc',
        'full': false,
        'active_location_ids': [1, 2],
        'result': [fila],
      }));
      expect(r.full, isFalse);
      expect(r.scope, 'abc');
      expect(r.activos, [1, 2]);
    });

    test('code distinto de 200 lanza', () {
      expect(
        () => parseUbicacionesSync(body({'code': 400, 'result': []})),
        throwsA(isA<ServerException>()),
      );
    });

    test('sesión expirada', () {
      expect(
        () => parseUbicacionesSync(jsonEncode({
          'error': {'code': 100, 'message': 'Session expired'},
        })),
        throwsA(isA<SessionExpiredException>()),
      );
    });
  });

  group('UbicacionesRepository.aplicarCambios (SQLite real)', () {
    late Database db;
    final repo = UbicacionesRepository();

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      db = await openDatabase(inMemoryDatabasePath, version: 1,
          onCreate: (d, _) => d.execute(UbicacionesTable.createTable()));
      for (final u in [_r(1), _r(2), _r(3)]) {
        await db.insert(UbicacionesTable.tableName, {
          UbicacionesTable.columnId: u.id,
          UbicacionesTable.columnName: u.name,
          UbicacionesTable.columnBarcode: u.barcode,
        });
      }
    });

    tearDown(() => db.close());

    Future<Map<int, String?>> filas() async => {
      for (final m in await db.query(UbicacionesTable.tableName))
        m[UbicacionesTable.columnId] as int:
            m[UbicacionesTable.columnBarcode] as String?,
    };

    test('actualiza, inserta y borra las no activas', () async {
      await repo.aplicarCambios(
        [_r(2, barcode: 'NUEVO'), _r(4)],
        [2, 4],
        db: db,
      );
      expect(await filas(), {2: 'NUEVO', 4: 'B4'});
    });

    test('si le quitaron el barcode, la fila vieja se borra', () async {
      await repo.aplicarCambios([_r(1, barcode: '')], null, db: db);
      expect((await filas()).keys, unorderedEquals([2, 3]));
    });

    test('sin activas no depura', () async {
      await repo.aplicarCambios([_r(4)], null, db: db);
      expect((await filas()).keys, unorderedEquals([1, 2, 3, 4]));
    });

    test('más de 999 ids activos (tandas)', () async {
      await repo.aplicarCambios(
        const [],
        [for (var i = 2; i < 3000; i++) i],
        db: db,
      );
      expect((await filas()).keys, unorderedEquals([2, 3]));
    });
  });

  group('UserRepositoryImpl.getUserLocations', () {
    late _Remote remote;
    late _Local local;
    late UserRepositoryImpl repo;
    const empresa = 'https://cliente.com|bd';
    const marca = (since: '2026-10-09 15:00:00', scope: 'abc');

    void respuesta(UbicacionesSyncResult r) => when(
      () => remote.getUserLocations(
        since: any(named: 'since'),
        scope: any(named: 'scope'),
      ),
    ).thenAnswer((_) async => r);

    setUp(() {
      remote = _Remote();
      local = _Local();
      final red = _Red();
      when(() => red.isConnected).thenAnswer((_) async => true);
      when(() => local.empresaActual()).thenAnswer((_) async => empresa);
      when(() => local.empresaUbicaciones()).thenAnswer((_) async => empresa);
      when(() => local.marcaSyncUbicaciones()).thenAnswer((_) async => null);
      when(() => local.contarUbicaciones()).thenAnswer((_) async => 5);
      when(() => local.borrarUbicaciones()).thenAnswer((_) async {});
      when(() => local.cacheUserLocations(any())).thenAnswer((_) async {});
      when(() => local.aplicarCambiosUbicaciones(any(), any()))
          .thenAnswer((_) async {});
      when(() => local.guardarEmpresaUbicaciones(any())).thenAnswer((_) async {});
      when(() => local.guardarMarcaSyncUbicaciones(any(), any()))
          .thenAnswer((_) async {});
      when(() => local.borrarMarcaSyncUbicaciones()).thenAnswer((_) async {});
      when(() => local.getUbicacionesLocales())
          .thenAnswer((_) async => [_u(1), _u(2)]);
      repo = UserRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
        networkInfo: red,
      );
    });

    test('sin marca: completa, guarda marca y devuelve lo local', () async {
      respuesta(UbicacionesSyncResult(
        ubicaciones: [_u(1)],
        serverTime: '2026-10-09 16:00:00',
        scope: 'abc',
      ));

      final r = await repo.getUserLocations();

      expect(r.getRight().toNullable(), hasLength(2));
      verify(() => remote.getUserLocations(since: null, scope: null)).called(1);
      verify(() => local.cacheUserLocations([_u(1)])).called(1);
      verify(() => local.guardarMarcaSyncUbicaciones(
            '2026-10-09 16:00:00',
            'abc',
          )).called(1);
    });

    test('con marca: incremental', () async {
      when(() => local.marcaSyncUbicaciones()).thenAnswer((_) async => marca);
      respuesta(UbicacionesSyncResult(
        ubicaciones: [_u(3)],
        full: false,
        serverTime: '2026-10-09 16:00:00',
        scope: 'abc',
        activos: const [1, 3],
      ));

      await repo.getUserLocations();

      verify(() => remote.getUserLocations(
            since: marca.since,
            scope: marca.scope,
          )).called(1);
      verify(() => local.aplicarCambiosUbicaciones([_u(3)], [1, 3])).called(1);
      verifyNever(() => local.cacheUserLocations(any()));
    });

    test('si la descarga falla no toca lo local ni la marca', () async {
      when(() => local.marcaSyncUbicaciones()).thenAnswer((_) async => marca);
      when(
        () => remote.getUserLocations(
          since: any(named: 'since'),
          scope: any(named: 'scope'),
        ),
      ).thenThrow(const ServerException('timeout'));

      final r = await repo.getUserLocations();

      expect(r.getLeft().toNullable(), isA<ServerFailure>());
      verifyNever(() => local.borrarUbicaciones());
      verifyNever(() => local.guardarMarcaSyncUbicaciones(any(), any()));
      verifyNever(() => local.borrarMarcaSyncUbicaciones());
    });

    test('completa vacía no borra lo local', () async {
      respuesta(const UbicacionesSyncResult(ubicaciones: []));

      final r = await repo.getUserLocations();

      expect(r.isLeft(), isTrue);
      verifyNever(() => local.cacheUserLocations(any()));
    });

    test('otra empresa: borra ubicaciones y marca antes de descargar', () async {
      when(() => local.empresaUbicaciones()).thenAnswer((_) async => null);
      respuesta(const UbicacionesSyncResult(ubicaciones: []));

      await repo.getUserLocations();

      verify(() => local.borrarUbicaciones()).called(1);
      verify(() => local.borrarMarcaSyncUbicaciones()).called(1);
    });
  });
}
