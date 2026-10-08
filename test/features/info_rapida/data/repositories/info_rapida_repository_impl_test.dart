import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/info_rapida/data/datasources/info_rapida_local_data_source.dart';
import 'package:wms_app/features/info_rapida/data/datasources/info_rapida_remote_data_source.dart';
import 'package:wms_app/features/info_rapida/data/exceptions/info_rapida_exceptions.dart';
import 'package:wms_app/features/info_rapida/data/repositories/info_rapida_repository_impl.dart';
import 'package:wms_app/features/info_rapida/data/services/info_rapida_entorno.dart';
import 'package:wms_app/features/info_rapida/domain/entities/catalogo_info.dart';
import 'package:wms_app/features/info_rapida/domain/entities/config_info_rapida_usuario.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida_params.dart';
import 'package:wms_app/features/info_rapida/domain/entities/recent_query.dart';
import 'package:wms_app/features/info_rapida/domain/entities/transfer_results.dart';
import 'package:wms_app/features/info_rapida/domain/failures/info_rapida_failures.dart';

class MockRemoteDataSource extends Mock implements InfoRapidaRemoteDataSource {}

class MockLocalDataSource extends Mock implements InfoRapidaLocalDataSource {}

class MockEntorno extends Mock implements InfoRapidaEntorno {}

void main() {
  late MockRemoteDataSource remote;
  late MockLocalDataSource local;
  late MockEntorno entorno;
  late InfoRapidaRepositoryImpl repository;

  final testProducto = const ProductoInfo(
    id: 1,
    nombre: 'Tuerca 1/4',
    referencia: 'TU-14',
    codigoBarras: '770001',
    cantidadDisponible: 100.0,
    unidadMedida: 'un.',
    ubicaciones: [],
  );

  final testUbicacion = const UbicacionInfo(
    id: 10,
    nombre: 'A-01',
    codigoBarras: 'LOC-A01',
    nombreAlmacen: 'Central',
    ubicacionPadre: 'Stock',
    numeroProductos: 5,
    productos: [],
  );

  final testPaquete = const PaqueteInfo(
    id: 20,
    nombre: 'CAJA-100',
    codigoBarras: 'BOX100',
    nombreAlmacen: 'Despacho',
    numeroProductos: 3,
    productos: [],
  );

  final testRecentQuery = RecentQuery(
    query: '770001',
    isManual: false,
    isProduct: true,
    type: 'product',
    title: 'TU-14',
    subtitle: 'Tuerca 1/4',
    badge: '100.0 un.',
    date: DateTime(2026, 10, 8),
  );

  setUpAll(() {
    registerFallbackValue(testRecentQuery);
    registerFallbackValue(
      const ActualizarProductoParams(
        productId: 1,
        name: 'Tuerca 1/4',
        barcode: '770001',
        defaultCode: 'TU-14',
        listPrice: '100',
        weight: '1.0',
        volume: '0.01',
      ),
    );
    registerFallbackValue(
      const ActualizarUbicacionParams(
        locationId: 10,
        name: 'A-01',
        barcode: 'LOC-A01',
      ),
    );
    registerFallbackValue(
      const CrearTransferenciaIndividualParams(
        idAlmacen: 1,
        idMove: 100,
        idProducto: 1,
        idLote: 10,
        idUbicacionOrigen: 10,
        idUbicacionDestino: 11,
        cantidadEnviada: 5.0,
        observacion: 'Transferencia de prueba',
      ),
    );
    registerFallbackValue(
      const CrearTransferenciaMasivaParams(
        dateStart: '2026-10-08 08:00',
        dateEnd: '2026-10-08 08:30',
        idAlmacen: 1,
        idUbicacionOrigen: 10,
        idUbicacionDestino: 11,
        idOperario: 5,
        fechaTransaccion: '2026-10-08',
        listItems: [],
      ),
    );
  });

  setUp(() {
    remote = MockRemoteDataSource();
    local = MockLocalDataSource();
    entorno = MockEntorno();
    repository = InfoRapidaRepositoryImpl(remote, local, entorno);

    when(() => entorno.hayRed()).thenAnswer((_) async => true);
    when(() => entorno.deviceId()).thenAnswer((_) async => 'DEV-123');
    when(() => entorno.versionApp()).thenAnswer((_) async => '2.5.0');
    when(() => local.saveRecentQuery(any())).thenAnswer((_) async {});
  });

  group('consultarPorBarcode', () {
    test('devuelve SinConexionFailure cuando hayRed es false', () async {
      when(() => entorno.hayRed()).thenAnswer((_) async => false);

      final result = await repository.consultarPorBarcode('770001');

      expect(result.getLeft().toNullable(), isA<SinConexionFailure>());
      verifyZeroInteractions(remote);
    });

    test('retorna ProductoInfo sin guardar en recientes (lo decide el bloc)', () async {
      when(
        () => remote.getInfoQuick(
          barcode: '770001',
          deviceId: 'DEV-123',
          versionApp: '2.5.0',
        ),
      ).thenAnswer((_) async => testProducto);

      final result = await repository.consultarPorBarcode('770001');

      expect(result.getRight().toNullable(), testProducto);
      verifyNever(() => local.saveRecentQuery(any()));
    });

    test('retorna UbicacionInfo sin guardar en recientes', () async {
      when(
        () => remote.getInfoQuick(
          barcode: 'LOC-A01',
          deviceId: 'DEV-123',
          versionApp: '2.5.0',
        ),
      ).thenAnswer((_) async => testUbicacion);

      final result = await repository.consultarPorBarcode('LOC-A01');

      expect(result.getRight().toNullable(), testUbicacion);
      verifyNever(() => local.saveRecentQuery(any()));
    });

    test('retorna PaqueteInfo sin guardar en recientes', () async {
      when(
        () => remote.getInfoQuick(
          barcode: 'BOX100',
          deviceId: 'DEV-123',
          versionApp: '2.5.0',
        ),
      ).thenAnswer((_) async => testPaquete);

      final result = await repository.consultarPorBarcode('BOX100');

      expect(result.getRight().toNullable(), testPaquete);
      verifyNever(() => local.saveRecentQuery(any()));
    });

    test('mapea DispositivoNoAutorizadoException a DispositivoNoAutorizadoFailure', () async {
      when(
        () => remote.getInfoQuick(
          barcode: any(named: 'barcode'),
          deviceId: any(named: 'deviceId'),
          versionApp: any(named: 'versionApp'),
        ),
      ).thenThrow(const DispositivoNoAutorizadoException('No autorizado'));

      final result = await repository.consultarPorBarcode('770001');

      expect(
        result.getLeft().toNullable(),
        isA<DispositivoNoAutorizadoFailure>().having(
          (f) => f.message,
          'message',
          'No autorizado',
        ),
      );
    });

    test('mapea NoEncontradoException a NoEncontradoFailure', () async {
      when(
        () => remote.getInfoQuick(
          barcode: any(named: 'barcode'),
          deviceId: any(named: 'deviceId'),
          versionApp: any(named: 'versionApp'),
        ),
      ).thenThrow(const NoEncontradoException('No encontrado'));

      final result = await repository.consultarPorBarcode('770001');

      expect(
        result.getLeft().toNullable(),
        isA<NoEncontradoFailure>().having(
          (f) => f.message,
          'message',
          'No encontrado',
        ),
      );
    });

    test('mapea ActualizarVersionException a ActualizarVersionFailure', () async {
      when(
        () => remote.getInfoQuick(
          barcode: any(named: 'barcode'),
          deviceId: any(named: 'deviceId'),
          versionApp: any(named: 'versionApp'),
        ),
      ).thenThrow(const ActualizarVersionException('Actualización requerida'));

      final result = await repository.consultarPorBarcode('770001');

      expect(
        result.getLeft().toNullable(),
        isA<ActualizarVersionFailure>().having(
          (f) => f.message,
          'message',
          'Actualización requerida',
        ),
      );
    });

    test('mapea SessionExpiredException a SesionExpiradaFailure', () async {
      when(
        () => remote.getInfoQuick(
          barcode: any(named: 'barcode'),
          deviceId: any(named: 'deviceId'),
          versionApp: any(named: 'versionApp'),
        ),
      ).thenThrow(const SessionExpiredException('Sesión caducada'));

      final result = await repository.consultarPorBarcode('770001');

      expect(
        result.getLeft().toNullable(),
        isA<SesionExpiradaFailure>().having(
          (f) => f.message,
          'message',
          'Sesión caducada',
        ),
      );
    });

    test('mapea NetworkException a SinConexionFailure', () async {
      when(
        () => remote.getInfoQuick(
          barcode: any(named: 'barcode'),
          deviceId: any(named: 'deviceId'),
          versionApp: any(named: 'versionApp'),
        ),
      ).thenThrow(const NetworkException('Error de conexión'));

      final result = await repository.consultarPorBarcode('770001');

      expect(
        result.getLeft().toNullable(),
        isA<SinConexionFailure>().having(
          (f) => f.message,
          'message',
          'Error de conexión',
        ),
      );
    });

    test('mapea ServerException a ServerFailure', () async {
      when(
        () => remote.getInfoQuick(
          barcode: any(named: 'barcode'),
          deviceId: any(named: 'deviceId'),
          versionApp: any(named: 'versionApp'),
        ),
      ).thenThrow(const ServerException('Falla en Odoo'));

      final result = await repository.consultarPorBarcode('770001');

      expect(
        result.getLeft().toNullable(),
        isA<ServerFailure>().having(
          (f) => f.message,
          'message',
          'Falla en Odoo',
        ),
      );
    });
  });

  group('consultarPorId', () {
    test('devuelve SinConexionFailure cuando hayRed es false', () async {
      when(() => entorno.hayRed()).thenAnswer((_) async => false);

      final result = await repository.consultarPorId(id: 1, isProduct: true);

      expect(result.getLeft().toNullable(), isA<SinConexionFailure>());
      verifyZeroInteractions(remote);
    });

    test('retorna ProductoInfo sin guardar en recientes', () async {
      when(
        () => remote.getInfoQuickManual(
          id: 1,
          isProduct: true,
          deviceId: 'DEV-123',
          versionApp: '2.5.0',
        ),
      ).thenAnswer((_) async => testProducto);

      final result = await repository.consultarPorId(id: 1, isProduct: true);

      expect(result.getRight().toNullable(), testProducto);
      verifyNever(() => local.saveRecentQuery(any()));
    });
  });

  group('gestión de consultas recientes', () {
    test('getConsultasRecientes devuelve la lista desde localDataSource', () async {
      when(() => local.getRecentQueries()).thenAnswer((_) async => [testRecentQuery]);

      final result = await repository.getConsultasRecientes();

      expect(result.getRight().toNullable(), [testRecentQuery]);
    });

    test('getConsultasRecientes mapea CacheException a CacheFailure', () async {
      when(() => local.getRecentQueries()).thenThrow(const CacheException('Error lectura'));

      final result = await repository.getConsultasRecientes();

      expect(result.getLeft().toNullable(), isA<CacheFailure>());
    });

    test('guardarConsultaReciente delega a localDataSource', () async {
      when(() => local.saveRecentQuery(any())).thenAnswer((_) async {});

      final result = await repository.guardarConsultaReciente(testRecentQuery);

      expect(result.getRight().toNullable(), unit);
      verify(() => local.saveRecentQuery(testRecentQuery)).called(1);
    });

    test('borrarConsultasRecientes delega a localDataSource', () async {
      when(() => local.clearRecentQueries()).thenAnswer((_) async {});

      final result = await repository.borrarConsultasRecientes();

      expect(result.getRight().toNullable(), unit);
      verify(() => local.clearRecentQueries()).called(1);
    });
  });

  group('catálogos y configuración', () {
    test('getCatalogoProductos obtiene catálogo desde localDataSource', () async {
      final prods = <ProductoCatalogo>[
        const ProductoCatalogo(id: 1, name: 'P1', code: '001')
      ];
      when(() => local.getCatalogoProductos(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => prods);

      final result = await repository.getCatalogoProductos(forceRefresh: true);

      expect(result.getRight().toNullable(), prods);
      verify(() => local.getCatalogoProductos(forceRefresh: true)).called(1);
    });

    test('getCatalogoUbicaciones obtiene catálogo desde localDataSource', () async {
      final locs = <UbicacionCatalogo>[
        const UbicacionCatalogo(id: 2, name: 'U1', barcode: '002')
      ];
      when(() => local.getCatalogoUbicaciones(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => locs);

      final result = await repository.getCatalogoUbicaciones(forceRefresh: false);

      expect(result.getRight().toNullable(), locs);
      verify(() => local.getCatalogoUbicaciones(forceRefresh: false)).called(1);
    });

    test('getConfiguracionUsuario obtiene configuración del usuario', () async {
      const config = ConfigInfoRapidaUsuario(
        updateItemInventory: true,
        updateLocationInventory: true,
      );
      when(() => local.getConfiguracionUsuario(userId: any(named: 'userId')))
          .thenAnswer((_) async => config);

      final result = await repository.getConfiguracionUsuario(userId: 5);

      expect(result.getRight().toNullable(), config);
      verify(() => local.getConfiguracionUsuario(userId: 5)).called(1);
    });
  });

  group('actualizaciones y transferencias', () {
    test('actualizarProducto valida red, actualiza remoto y sincroniza local', () async {
      const params = ActualizarProductoParams(
        productId: 1,
        name: 'Tuerca 1/4',
        barcode: '770001',
        defaultCode: 'TU-14',
        listPrice: '100',
        weight: '2.5',
        volume: '0.05',
      );
      when(() => remote.updateProduct(params)).thenAnswer((_) async => testProducto);
      when(() => local.syncLocalProductUpdated(params)).thenAnswer((_) async {});

      final result = await repository.actualizarProducto(params);

      expect(result.getRight().toNullable(), testProducto);
      verify(() => remote.updateProduct(params)).called(1);
      verify(() => local.syncLocalProductUpdated(params)).called(1);
    });

    test('actualizarUbicacion valida red, actualiza remoto y sincroniza local', () async {
      const params = ActualizarUbicacionParams(
        locationId: 10,
        name: 'LOC-NEW',
        barcode: 'LOC-NEW',
      );
      when(() => remote.updateLocation(params)).thenAnswer((_) async => testUbicacion);
      when(() => local.syncLocalLocationUpdated(params)).thenAnswer((_) async {});

      final result = await repository.actualizarUbicacion(params);

      expect(result.getRight().toNullable(), testUbicacion);
      verify(() => remote.updateLocation(params)).called(1);
      verify(() => local.syncLocalLocationUpdated(params)).called(1);
    });

    test('crearTransferenciaIndividual valida red y devuelve resultado', () async {
      const params = CrearTransferenciaIndividualParams(
        idAlmacen: 1,
        idMove: 50,
        idProducto: 1,
        idLote: 10,
        idUbicacionOrigen: 10,
        idUbicacionDestino: 11,
        cantidadEnviada: 2.0,
        observacion: 'Prueba transferencia',
      );
      const transferRes = TransferenciaIndividualResult(
        transferenciaId: 999,
        nombreTransferencia: 'WH/INT/0001',
      );
      when(() => remote.crearTransferenciaIndividual(params))
          .thenAnswer((_) async => transferRes);

      final result = await repository.crearTransferenciaIndividual(params);

      expect(result.getRight().toNullable(), transferRes);
      verify(() => remote.crearTransferenciaIndividual(params)).called(1);
    });

    test('crearTransferenciaMasiva valida red, ejecuta remoto y limpia borradores locales', () async {
      const params = CrearTransferenciaMasivaParams(
        dateStart: '2026-10-08 08:00',
        dateEnd: '2026-10-08 08:30',
        idAlmacen: 1,
        idUbicacionOrigen: 10,
        idUbicacionDestino: 11,
        idOperario: 5,
        fechaTransaccion: '2026-10-08',
        listItems: [],
      );
      const masivaRes = TransferenciaMasivaResult(
        transferenciaId: 1000,
        nombreTransferencia: 'WH/INT/0002',
        totalItems: 3,
      );
      when(() => remote.crearTransferenciaMasiva(params))
          .thenAnswer((_) async => masivaRes);
      when(() => local.clearLocalDraftTransfers()).thenAnswer((_) async {});

      final result = await repository.crearTransferenciaMasiva(params);

      expect(result.getRight().toNullable(), masivaRes);
      verify(() => remote.crearTransferenciaMasiva(params)).called(1);
      verify(() => local.clearLocalDraftTransfers()).called(1);
    });
  });
}
