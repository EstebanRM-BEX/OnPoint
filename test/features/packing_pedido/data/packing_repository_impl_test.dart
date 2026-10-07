import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/packing_pedido/data/datasources/packing_pedido_local_data_source.dart';
import 'package:wms_app/features/packing_pedido/data/datasources/packing_pedido_remote_data_source.dart';
import 'package:wms_app/features/packing_pedido/data/models/packing_api_models.dart';
import 'package:wms_app/features/packing_pedido/data/repositories/packing_pedido_repository_impl.dart';
import 'package:wms_app/features/packing_pedido/data/services/packing_entorno.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/failures/packing_failures.dart';

import '../domain/packing_test_data.dart';

class MockRemote extends Mock implements PackingPedidoRemoteDataSource {}

class MockLocal extends Mock implements PackingPedidoLocalDataSource {}

class MockEntorno extends Mock implements PackingEntorno {}

void main() {
  late MockRemote remote;
  late MockLocal local;
  late MockEntorno entorno;
  late PackingPedidoRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(productoTest());
    registerFallbackValue(paqueteTest());
    registerFallbackValue(pedidoTest);
    registerFallbackValue(<ItemEmpaqueApi>[]);
    registerFallbackValue(<ProductoPacking>[]);
    registerFallbackValue(
      PaqueteCreadoApi(paquete: paqueteTest(), filasEmpacadas: const []),
    );
  });

  setUp(() {
    remote = MockRemote();
    local = MockLocal();
    entorno = MockEntorno();
    repo = PackingPedidoRepositoryImpl(remote, local, entorno);

    when(() => entorno.hayRed()).thenAnswer((_) async => true);
    when(() => entorno.ahora()).thenReturn(DateTime(2026, 10, 7, 8));
    when(() => entorno.userId()).thenAnswer((_) async => 7);
    when(() => entorno.userName()).thenAnswer((_) async => 'Operario');
    when(() => entorno.owner()).thenAnswer((_) async => 'empresa|7');
    when(
      () => local.actualizarPedido(any(), any()),
    ).thenAnswer((_) async => pedidoTest);
  });

  final listo = productoTest(
    estado: EstadoProductoPacking.listo,
    certificado: true,
    quantitySeparate: 4,
  );

  void stubCrear() {
    when(
      () => remote.crearPaquete(
        pedido: any(named: 'pedido'),
        esCluster: any(named: 'esCluster'),
        isSticker: any(named: 'isSticker'),
        certificado: any(named: 'certificado'),
        peso: any(named: 'peso'),
        tipoPaqueteId: any(named: 'tipoPaqueteId'),
        tipoPaqueteNombre: any(named: 'tipoPaqueteNombre'),
        items: any(named: 'items'),
      ),
    ).thenAnswer(
      (_) async =>
          PaqueteCreadoApi(paquete: paqueteTest(), filasEmpacadas: const []),
    );
  }

  test('sin red falla antes de llamar al servidor', () async {
    when(() => entorno.hayRed()).thenAnswer((_) async => false);

    final r = await repo.crearPaquete(
      pedido: pedidoTest,
      productos: [listo],
      certificado: true,
      isSticker: false,
    );

    expect(r.getLeft().toNullable(), isA<NetworkFailure>());
    verifyZeroInteractions(remote);
  });

  test(
    'crearPaquete manda cantidad separada, lote 0 y ubicación destino',
    () async {
      when(() => local.getProducto(any())).thenAnswer((_) async => listo);
      stubCrear();
      when(
        () => local.guardarPaqueteCreado(
          enviados: any(named: 'enviados'),
          creado: any(named: 'creado'),
          certificado: any(named: 'certificado'),
        ),
      ).thenAnswer((_) async => paqueteTest());

      final r = await repo.crearPaquete(
        pedido: pedidoTest,
        productos: [listo],
        certificado: true,
        isSticker: true,
      );
      expect(r.isRight(), isTrue);

      final items =
          verify(
                () => remote.crearPaquete(
                  pedido: any(named: 'pedido'),
                  esCluster: false,
                  isSticker: true,
                  certificado: true,
                  peso: any(named: 'peso'),
                  tipoPaqueteId: 0,
                  tipoPaqueteNombre: any(named: 'tipoPaqueteNombre'),
                  items: captureAny(named: 'items'),
                ),
              ).captured.single
              as List<ItemEmpaqueApi>;

      final item = items.single.toMap();
      expect(item['cantidad_enviada'], 4);
      expect(item['id_lote'], 0);
      expect(item['id_operario'], 7);
      expect(item['observacion'], 'Sin novedad');
      expect(item['time_line'], 2);
    },
  );

  test(
    'si Odoo creó la caja pero falla lo local, avisa que hay que refrescar',
    () async {
      when(() => local.getProducto(any())).thenAnswer((_) async => listo);
      stubCrear();
      when(
        () => local.guardarPaqueteCreado(
          enviados: any(named: 'enviados'),
          creado: any(named: 'creado'),
          certificado: any(named: 'certificado'),
        ),
      ).thenThrow(const CacheException('disco lleno'));

      final r = await repo.crearPaquete(
        pedido: pedidoTest,
        productos: [listo],
        certificado: true,
        isSticker: false,
      );

      final f = r.getLeft().toNullable();
      expect(f, isA<ServerFailure>());
      expect(f!.message, contains('Actualice el pedido'));
    },
  );

  test(
    'validar con productos vencidos devuelve PackingVencidosFailure',
    () async {
      when(
        () => remote.validarPedido(
          pedidoId: any(named: 'pedidoId'),
          crearBackorder: any(named: 'crearBackorder'),
          aceptarVencidos: any(named: 'aceptarVencidos'),
        ),
      ).thenThrow(const VencidosException('expiry.picking.confirmation'));

      final r = await repo.validarPedido(pedidoId: 10, crearBackorder: false);

      expect(r.getLeft().toNullable(), isA<PackingVencidosFailure>());
      verifyNever(() => local.actualizarPedido(10, {'is_terminate': 1}));
    },
  );

  test('validar marca el pedido terminado y registra el fin', () async {
    when(
      () => remote.validarPedido(
        pedidoId: any(named: 'pedidoId'),
        crearBackorder: any(named: 'crearBackorder'),
        aceptarVencidos: any(named: 'aceptarVencidos'),
      ),
    ).thenAnswer((_) async => 'Validado');
    when(
      () => remote.enviarTiempo(
        pedidoId: any(named: 'pedidoId'),
        campo: any(named: 'campo'),
        hora: any(named: 'hora'),
      ),
    ).thenAnswer((_) async {});

    final r = await repo.validarPedido(pedidoId: 10, crearBackorder: true);

    expect(r.toNullable()?.conBackorder, isTrue);
    verify(() => local.actualizarPedido(10, {'is_terminate': 1})).called(1);
    verify(
      () => remote.enviarTiempo(
        pedidoId: 10,
        campo: 'end_time_transfer',
        hora: '2026-10-07 08:00:00',
      ),
    ).called(1);
  });

  test('asignar responsable no falla si el envío del tiempo falla', () async {
    when(
      () => remote.asignarResponsable(
        pedidoId: any(named: 'pedidoId'),
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => remote.enviarTiempo(
        pedidoId: any(named: 'pedidoId'),
        campo: any(named: 'campo'),
        hora: any(named: 'hora'),
      ),
    ).thenThrow(const ServerException('timeout'));
    when(() => local.getPedido(10)).thenAnswer((_) async => pedidoTest);

    final r = await repo.asignarResponsable(10);

    expect(r, const Right(pedidoTest));
    verify(
      () => local.actualizarPedido(10, {
        'responsable_id': 7,
        'responsable': 'Operario',
        'is_selected': 1,
      }),
    ).called(1);
  });

  test(
    'desempaque que no se refleja en el dispositivo queda marcado',
    () async {
      when(
        () => remote.desempacar(
          pedidoId: any(named: 'pedidoId'),
          paqueteId: any(named: 'paqueteId'),
          idMove: any(named: 'idMove'),
          idOperario: any(named: 'idOperario'),
        ),
      ).thenAnswer(
        (_) async => const MovesDevueltosApi(mensaje: 'ok', moves: []),
      );
      registerFallbackValue(const MovesDevueltosApi(mensaje: '', moves: []));
      when(
        () => local.aplicarDesempaque(
          paquete: any(named: 'paquete'),
          empacada: any(named: 'empacada'),
          respuesta: any(named: 'respuesta'),
        ),
      ).thenThrow(const CacheException('no está'));

      final r = await repo.desempacarProducto(
        paquete: paqueteTest(),
        producto: productoTest(
          estado: EstadoProductoPacking.empacado,
          idPackage: 1,
        ),
      );

      expect(r.toNullable()?.desincronizado, isTrue);
    },
  );

  test('sesión expirada se mapea a SessionExpiredFailure', () async {
    when(
      () => remote.fetchPedidos(isLoadingDialog: any(named: 'isLoadingDialog')),
    ).thenThrow(const SessionExpiredException('expirada'));

    final r = await repo.syncPedidos(isLoadingDialog: false);

    expect(r.getLeft().toNullable(), isA<SessionExpiredFailure>());
  });
}
