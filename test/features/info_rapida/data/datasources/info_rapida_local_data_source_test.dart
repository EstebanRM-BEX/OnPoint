import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wms_app/core/services/configuracion_cache_service.dart';
import 'package:wms_app/core/services/productos_cache_service.dart';
import 'package:wms_app/core/services/ubicaciones_cache_service.dart';
import 'package:wms_app/features/info_rapida/data/datasources/info_rapida_local_data_source.dart';
import 'package:wms_app/features/info_rapida/data/services/info_rapida_entorno.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida_params.dart';
import 'package:wms_app/features/info_rapida/domain/entities/recent_query.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_ubicaciones/ubicaciones_repository.dart';

class _MockEntorno extends Mock implements InfoRapidaEntorno {}

class _MockProductos extends Mock implements ProductosCacheService {}

class _MockUbicaciones extends Mock implements UbicacionesCacheService {}

class _MockConfiguracion extends Mock implements ConfiguracionCacheService {}

class _MockDb extends Mock implements DataBaseSqlite {}

class _MockUbicacionesRepo extends Mock implements UbicacionesRepository {}

void main() {
  late _MockEntorno entorno;
  late _MockUbicaciones ubicacionesCache;
  late _MockUbicacionesRepo ubicacionesRepo;
  late InfoRapidaLocalDataSourceImpl dataSource;

  setUpAll(() => registerFallbackValue(ResultUbicaciones()));

  setUp(() {
    ubicacionesCache = _MockUbicaciones();
    ubicacionesRepo = _MockUbicacionesRepo();
    final db = _MockDb();
    when(() => db.ubicacionesRepository).thenReturn(ubicacionesRepo);
    when(() => ubicacionesRepo.insertOrUpdateSingle(any()))
        .thenAnswer((_) async {});
    when(() => ubicacionesCache.refresh()).thenAnswer((_) async => []);

    entorno = _MockEntorno();
    when(() => entorno.databaseName()).thenReturn('empresa');
    dataSource = InfoRapidaLocalDataSourceImpl.test(
      entorno,
      _MockProductos(),
      ubicacionesCache,
      _MockConfiguracion(),
      db,
    );
  });

  group('syncLocalLocationUpdated (bug 3)', () {
    test('conserva almacén, ubicación padre y muelle de la existente', () async {
      when(() => ubicacionesCache.getAll()).thenAnswer(
        (_) async => [
          ResultUbicaciones(
            id: 10,
            name: 'Viejo',
            barcode: 'OLD',
            locationId: 3,
            locationName: 'WH/Stock',
            idWarehouse: 1,
            warehouseName: 'Central',
            isADockAlter: true,
          ),
        ],
      );

      await dataSource.syncLocalLocationUpdated(
        const ActualizarUbicacionParams(
          locationId: 10,
          name: 'Nuevo',
          barcode: 'NEW',
        ),
      );

      final guardada = verify(
        () => ubicacionesRepo.insertOrUpdateSingle(captureAny()),
      ).captured.single as ResultUbicaciones;
      expect(guardada.name, 'Nuevo');
      expect(guardada.barcode, 'NEW');
      expect(guardada.locationId, 3);
      expect(guardada.locationName, 'WH/Stock');
      expect(guardada.idWarehouse, 1);
      expect(guardada.warehouseName, 'Central');
      expect(guardada.isADockAlter, isTrue);
    });

    test('refresca el caché en memoria', () async {
      when(() => ubicacionesCache.getAll()).thenAnswer((_) async => []);

      await dataSource.syncLocalLocationUpdated(
        const ActualizarUbicacionParams(locationId: 10, name: 'N', barcode: 'B'),
      );

      verify(() => ubicacionesCache.refresh()).called(1);
    });
  });

  group('historial legacy (fase 7)', () {
    const legacyKey = 'info_rapida_recent_empresa';
    const nuevaKey = 'info_rapida_v2_recent_empresa';
    const legacyJson =
        '[{"query":"770001","isManual":false,"isProduct":true,"type":"product",'
        '"title":"REF-1","subtitle":"Tornillo","badge":"5 un.",'
        '"date":"2026-10-01T10:00:00.000"}]';

    test('trae el historial del módulo viejo y borra la clave vieja', () async {
      SharedPreferences.setMockInitialValues({legacyKey: legacyJson});

      final items = await dataSource.getRecentQueries();

      expect(items.single.title, 'REF-1');
      expect(items.single.badge, '5 un.');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(legacyKey), isNull);
      expect(prefs.getString(nuevaKey), isNotNull);
    });

    test('limpiar el historial nuevo no vuelve a traer el viejo', () async {
      SharedPreferences.setMockInitialValues({legacyKey: legacyJson});

      await dataSource.getRecentQueries();
      await dataSource.clearRecentQueries();

      expect(await dataSource.getRecentQueries(), isEmpty);
    });

    test('si ya hay historial nuevo no lo pisa', () async {
      SharedPreferences.setMockInitialValues({
        legacyKey: legacyJson,
        nuevaKey: '[]',
      });

      expect(await dataSource.getRecentQueries(), isEmpty);
    });
  });

  group('saveRecentQuery', () {
    RecentQuery q(String title) => RecentQuery(
          query: title,
          isManual: false,
          isProduct: true,
          type: 'product',
          title: title,
          subtitle: '',
          date: DateTime(2026, 10, 8),
        );

    test('guarda la primera consulta con el historial vacío', () async {
      SharedPreferences.setMockInitialValues({});

      await dataSource.saveRecentQuery(q('REF-1'));

      expect((await dataSource.getRecentQueries()).single.title, 'REF-1');
    });

    test('desduplica y deja la última primero', () async {
      SharedPreferences.setMockInitialValues({});

      await dataSource.saveRecentQuery(q('REF-1'));
      await dataSource.saveRecentQuery(q('REF-2'));
      await dataSource.saveRecentQuery(q('REF-1'));

      expect(
        (await dataSource.getRecentQueries()).map((e) => e.title),
        ['REF-1', 'REF-2'],
      );
    });
  });
}
