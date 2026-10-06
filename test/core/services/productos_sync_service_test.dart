import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/services/productos_cache_service.dart';
import 'package:wms_app/core/services/productos_sync_service.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/inventario/domain/usecases/get_productos_count.dart';
import 'package:wms_app/features/inventario/domain/usecases/sync_productos_inventario.dart';

class _MockSync extends Mock implements SyncProductosInventario {}

class _MockCount extends Mock implements GetProductosCount {}

class _MockCache extends Mock implements ProductosCacheService {}

class _FakeSyncParams extends Fake implements SyncProductosParams {}

class _FakeNoParams extends Fake implements NoParams {}

void main() {
  late _MockSync sync;
  late _MockCount count;
  late _MockCache cache;
  late ProductosSyncService service;

  setUpAll(() {
    registerFallbackValue(_FakeSyncParams());
    registerFallbackValue(_FakeNoParams());
  });

  setUp(() {
    sync = _MockSync();
    count = _MockCount();
    cache = _MockCache();
    service = ProductosSyncService(
      syncProductos: sync,
      getProductosCount: count,
      cache: cache,
    );
  });

  void syncOk() =>
      when(() => sync(any())).thenAnswer((_) async => const Right(null));

  group('download', () {
    test(
      'éxito: invalida el caché, actualiza el conteo y limpia el estado',
      () async {
        syncOk();
        when(() => count(any())).thenAnswer((_) async => const Right(120));

        final outcome = await service.download();

        expect(outcome, isA<ProductosSyncSuccess>());
        expect((outcome as ProductosSyncSuccess).count, 120);
        expect(service.count, 120);
        expect(service.error, isNull);
        expect(service.isLoading, isFalse);
        expect(service.progress, isNull);
        verify(() => cache.invalidate()).called(1);
      },
    );

    test(
      'fallo de red: devuelve Failure, guarda el error y no toca el caché',
      () async {
        when(
          () => sync(any()),
        ).thenAnswer((_) async => const Left(NetworkFailure('sin red')));

        final outcome = await service.download();

        expect(outcome, isA<ProductosSyncFailure>());
        expect((outcome as ProductosSyncFailure).message, 'sin red');
        expect(service.error, 'sin red');
        expect(service.isLoading, isFalse);
        verifyNever(() => cache.invalidate());
        verifyNever(() => count(any()));
      },
    );

    test('sesión expirada se distingue de un fallo normal', () async {
      when(() => sync(any())).thenAnswer(
        (_) async => const Left(SessionExpiredFailure('sesión vencida')),
      );

      final outcome = await service.download();

      expect(outcome, isA<ProductosSyncSessionExpired>());
      expect(service.error, 'sesión vencida');
      expect(service.isLoading, isFalse);
    });

    test('catálogo vacío tras el sync es un fallo', () async {
      syncOk();
      when(() => count(any())).thenAnswer((_) async => const Right(0));

      final outcome = await service.download();

      expect(outcome, isA<ProductosSyncFailure>());
      expect(service.error, 'No se encontraron productos');
      expect(service.count, 0);
    });

    test('falla la lectura del conteo: Failure con el mensaje', () async {
      syncOk();
      when(
        () => count(any()),
      ).thenAnswer((_) async => const Left(CacheFailure('db rota')));

      final outcome = await service.download();

      expect(outcome, isA<ProductosSyncFailure>());
      expect(service.error, 'db rota');
      verify(() => cache.invalidate()).called(1);
    });

    test('una excepción no deja el servicio cargando para siempre', () async {
      when(() => sync(any())).thenThrow(StateError('boom'));

      final outcome = await service.download();

      expect(outcome, isA<ProductosSyncFailure>());
      expect(service.isLoading, isFalse);
      expect(service.error, 'No se pudieron descargar los productos');
    });

    test('segunda llamada con una descarga en curso: AlreadyRunning', () async {
      var released = false;
      when(() => sync(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        released = true;
        return const Right(null);
      });
      when(() => count(any())).thenAnswer((_) async => const Right(5));

      final first = service.download();
      expect(service.isLoading, isTrue);
      final second = await service.download();
      expect(second, isA<ProductosSyncAlreadyRunning>());
      expect(released, isFalse);

      await first;
      expect(service.isLoading, isFalse);
      verify(() => sync(any())).called(1);
    });

    test('reporta el progreso y lo limpia al terminar', () async {
      final seen = <String>[];
      service.addListener(() {
        final p = service.progress;
        if (p != null) seen.add(p.label);
      });
      when(() => sync(any())).thenAnswer((inv) async {
        final params = inv.positionalArguments.first as SyncProductosParams;
        params.onProgress?.call('Descargando', 0, 0);
        params.onProgress?.call('Guardando', 50, 100);
        return const Right(null);
      });
      when(() => count(any())).thenAnswer((_) async => const Right(100));

      await service.download();

      expect(seen, ['Descargando', 'Guardando\n50 / 100 productos']);
      expect(service.progress, isNull);
    });

    test('notifica a los listeners al empezar y al terminar', () async {
      syncOk();
      when(() => count(any())).thenAnswer((_) async => const Right(3));
      final loadingStates = <bool>[];
      service.addListener(() => loadingStates.add(service.isLoading));

      await service.download();

      expect(loadingStates.first, isTrue);
      expect(loadingStates.last, isFalse);
    });

    test('una descarga nueva limpia el error anterior', () async {
      when(
        () => sync(any()),
      ).thenAnswer((_) async => const Left(ServerFailure('falló')));
      await service.download();
      expect(service.error, 'falló');

      syncOk();
      when(() => count(any())).thenAnswer((_) async => const Right(9));
      await service.download();

      expect(service.error, isNull);
      expect(service.count, 9);
    });
  });

  group('refreshCount', () {
    test('actualiza el conteo y notifica solo si cambió', () async {
      var notified = 0;
      service.addListener(() => notified++);
      when(() => count(any())).thenAnswer((_) async => const Right(42));

      await service.refreshCount();
      await service.refreshCount();

      expect(service.count, 42);
      expect(notified, 1);
    });

    test('si falla la lectura conserva el conteo anterior', () async {
      when(() => count(any())).thenAnswer((_) async => const Right(7));
      await service.refreshCount();
      when(
        () => count(any()),
      ).thenAnswer((_) async => const Left(CacheFailure('x')));

      await service.refreshCount();

      expect(service.count, 7);
    });
  });
}
