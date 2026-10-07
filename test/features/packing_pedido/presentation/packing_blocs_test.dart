import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_resultados.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/pedido_pack.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/failures/packing_failures.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/actualizar_cantidad_separada_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/asignar_responsable_pack_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/asignar_ubicacion_paquetes_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/crear_paquete_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/desempacar_producto_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/deshacer_separacion_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/dividir_producto_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/eliminar_paquete_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/enviar_imagen_novedad_pack_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/enviar_temperatura_pack_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/get_barcodes_producto_pack_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/get_config_packing_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/get_novedades_pack_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/get_pedido_pack_detalle_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/get_pedidos_pack_local_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/get_ubicaciones_muelle_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/leer_temperatura_ia_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/marcar_producto_ok_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/marcar_ubicacion_ok_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/registrar_tiempo_pack_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/separar_producto_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/sync_pedidos_pack_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/validar_pedido_pack_usecase.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/common/packing_operacion.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/confirm/packing_confirm_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/detail/packing_pedido_detail_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/list/packing_pedido_list_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/packages/packing_packages_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/scan/packing_scan_bloc.dart';

import '../domain/packing_test_data.dart';

class MockSync extends Mock implements SyncPedidosPackUseCase {}

class MockGetLocal extends Mock implements GetPedidosPackLocalUseCase {}

class MockAsignar extends Mock implements AsignarResponsablePackUseCase {}

class MockConfig extends Mock implements GetConfigPackingUseCase {}

class MockDetalle extends Mock implements GetPedidoPackDetalleUseCase {}

class MockCrear extends Mock implements CrearPaqueteUseCase {}

class MockDeshacer extends Mock implements DeshacerSeparacionUseCase {}

class MockBarcodes extends Mock implements GetBarcodesProductoPackUseCase {}

class MockNovedades extends Mock implements GetNovedadesPackUseCase {}

class MockUbicOk extends Mock implements MarcarUbicacionOkUseCase {}

class MockProdOk extends Mock implements MarcarProductoOkUseCase {}

class MockCantidad extends Mock implements ActualizarCantidadSeparadaUseCase {}

class MockSeparar extends Mock implements SepararProductoUseCase {}

class MockDividir extends Mock implements DividirProductoUseCase {}

class MockLeerTemp extends Mock implements LeerTemperaturaIaUseCase {}

class MockEnviarTemp extends Mock implements EnviarTemperaturaPackUseCase {}

class MockNovedadImg extends Mock implements EnviarImagenNovedadPackUseCase {}

class MockDesempacar extends Mock implements DesempacarProductoUseCase {}

class MockEliminar extends Mock implements EliminarPaqueteUseCase {}

class MockUbicaciones extends Mock implements GetUbicacionesMuelleUseCase {}

class MockAsignarUbic extends Mock implements AsignarUbicacionPaquetesUseCase {}

class MockValidar extends Mock implements ValidarPedidoPackUseCase {}

class MockTiempo extends Mock implements RegistrarTiempoPackUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(NoParams());
    registerFallbackValue(const SyncPedidosPackParams(isLoadingDialog: false));
    registerFallbackValue(const AsignarResponsablePackParams(pedidoId: 0));
    registerFallbackValue(
      const RegistrarTiempoPackParams(
        pedidoId: 0,
        marca: MarcaTiempoPack.inicio,
      ),
    );
    registerFallbackValue(const GetPedidoPackDetalleParams(pedidoId: 0));
    registerFallbackValue(
      CrearPaqueteParams(
        pedido: pedidoTest,
        productos: const [],
        certificado: true,
        isSticker: false,
      ),
    );
    registerFallbackValue(DeshacerSeparacionParams(producto: productoTest()));
    registerFallbackValue(
      GetBarcodesProductoPackParams(producto: productoTest()),
    );
    registerFallbackValue(MarcarUbicacionOkParams(producto: productoTest()));
    registerFallbackValue(MarcarProductoOkParams(producto: productoTest()));
    registerFallbackValue(
      ActualizarCantidadSeparadaParams(producto: productoTest(), cantidad: 0),
    );
    registerFallbackValue(
      SepararProductoParams(producto: productoTest(), cantidad: 0),
    );
    registerFallbackValue(
      DividirProductoParams(producto: productoTest(), cantidad: 0),
    );
    registerFallbackValue(
      DesempacarProductoParams(
        pedido: pedidoTest,
        paquete: paqueteTest(),
        producto: productoTest(),
      ),
    );
    registerFallbackValue(
      const AsignarUbicacionPaquetesParams(
        pedidoId: 0,
        paquetes: [],
        ubicacion: UbicacionMuelle(id: 0),
      ),
    );
    registerFallbackValue(
      const ValidarPedidoPackParams(pedido: pedidoTest, crearBackorder: false),
    );
    registerFallbackValue(
      EnviarTemperaturaPackParams(producto: productoTest(), temperatura: 0),
    );
    registerFallbackValue(
      EnviarImagenNovedadPackParams(producto: productoTest(), imagePath: ''),
    );
  });

  // ── Lista ─────────────────────────────────────────────────────────────────

  group('PackingPedidoListBloc', () {
    late MockSync sync;
    late MockGetLocal getLocal;
    late MockAsignar asignar;
    late MockConfig config;
    late MockTiempo tiempo;

    const a = PedidoPack(
      id: 1,
      name: 'WH/PACK/1',
      contactoName: 'Panadería Ñandú',
      priority: '0',
    );
    const b = PedidoPack(id: 2, name: 'WH/PACK/2', priority: '1');

    setUp(() {
      sync = MockSync();
      getLocal = MockGetLocal();
      asignar = MockAsignar();
      config = MockConfig();
      tiempo = MockTiempo();
      when(() => config(any())).thenAnswer(
        (_) async =>
            const Right(ConfigPackingUsuario(manualQuantityPack: true)),
      );
    });

    PackingPedidoListBloc build() =>
        PackingPedidoListBloc(sync, getLocal, asignar, config, tiempo);

    blocTest<PackingPedidoListBloc, PackingPedidoListState>(
      'sin pedidos locales sincroniza con Odoo',
      build: build,
      setUp: () {
        when(() => getLocal(any())).thenAnswer((_) async => const Right([]));
        when(() => sync(any())).thenAnswer(
          (_) async => const Right(SyncPedidosPackResult(pedidos: [a, b])),
        );
      },
      act: (bloc) => bloc.add(const ListaPackIniciada()),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        verify(() => sync(any())).called(1);
        expect(bloc.state.pedidos, [a, b]);
        expect(bloc.state.config.manualQuantityPack, isTrue);
        expect(bloc.state.status, ListaPackStatus.listo);
      },
    );

    blocTest<PackingPedidoListBloc, PackingPedidoListState>(
      'con pedidos locales no sincroniza',
      build: build,
      setUp: () =>
          when(() => getLocal(any())).thenAnswer((_) async => const Right([a])),
      act: (bloc) => bloc.add(const ListaPackIniciada()),
      wait: const Duration(milliseconds: 10),
      verify: (_) => verifyNever(() => sync(any())),
    );

    blocTest<PackingPedidoListBloc, PackingPedidoListState>(
      'falla la sincronización: conserva lo que había y avisa',
      build: build,
      seed: () => const PackingPedidoListState(
        status: ListaPackStatus.listo,
        pedidos: [a],
      ),
      setUp: () => when(
        () => sync(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure('sin red'))),
      act: (bloc) => bloc.add(const ListaPackSincronizada()),
      verify: (bloc) {
        expect(bloc.state.pedidos, [a]);
        expect(bloc.state.status, ListaPackStatus.listo);
        expect(bloc.state.operacion.esError, isTrue);
        expect(bloc.state.sincronizando, isFalse);
      },
    );

    blocTest<PackingPedidoListBloc, PackingPedidoListState>(
      'sincronizar abre un solo aviso de carga: la API va sin diálogo propio',
      build: build,
      setUp: () => when(() => sync(any())).thenAnswer(
        (_) async => const Right(SyncPedidosPackResult(pedidos: [])),
      ),
      act: (bloc) => bloc.add(const ListaPackSincronizada()),
      verify: (bloc) {
        final params =
            verify(() => sync(captureAny())).captured.single
                as SyncPedidosPackParams;
        expect(params.isLoadingDialog, isFalse);
      },
    );

    test('búsqueda sin tildes y orden por prioridad', () {
      const s = PackingPedidoListState(pedidos: [a, b]);
      expect(s.copyWith(query: 'nandu').visibles, [a]);
      expect(s.visibles.first, b); // prioridad alta primero
      expect(
        s.copyWith(orden: OrdenPedidosPack.nombre, ascendente: true).visibles,
        [a, b],
      );
    });

    blocTest<PackingPedidoListBloc, PackingPedidoListState>(
      'asignar responsable actualiza el pedido y lo deja para navegar',
      build: build,
      seed: () => const PackingPedidoListState(pedidos: [a, b]),
      setUp: () => when(() => asignar(any())).thenAnswer(
        (_) async => Right(a.copyWith(responsableId: 7, responsable: 'Op')),
      ),
      act: (bloc) => bloc.add(const ResponsablePackAsignado(1)),
      verify: (bloc) {
        expect(bloc.state.pedidoAbierto?.responsableId, 7);
        expect(bloc.state.operacion.accion, 'abrir');
        expect(bloc.state.pedidos.first.responsable, 'Op');
        expect(bloc.state.operacion.tipo, TipoOperacion.exito);
      },
    );

    blocTest<PackingPedidoListBloc, PackingPedidoListState>(
      'sesión expirada se marca para que la UI mande al login',
      build: build,
      setUp: () => when(
        () => asignar(any()),
      ).thenAnswer((_) async => const Left(SessionExpiredFailure('expirada'))),
      act: (bloc) => bloc.add(const ResponsablePackAsignado(1)),
      verify: (bloc) =>
          expect(bloc.state.operacion.tipo, TipoOperacion.sesionExpirada),
    );

    blocTest<PackingPedidoListBloc, PackingPedidoListState>(
      'iniciar pedido registra el tiempo y lo abre aunque el envío falle',
      build: build,
      seed: () => const PackingPedidoListState(pedidos: [a]),
      setUp: () {
        when(
          () => tiempo(any()),
        ).thenAnswer((_) async => const Left(NetworkFailure('sin red')));
        when(() => getLocal(any())).thenAnswer(
          (_) async =>
              Right([a.copyWith(startTimeTransfer: '2026-10-07 08:00:00')]),
        );
      },
      act: (bloc) => bloc.add(const InicioPedidoPackRegistrado(a)),
      verify: (bloc) {
        expect(bloc.state.pedidoAbierto?.iniciado, isTrue);
        expect(bloc.state.operacion.accion, 'abrir');
        expect(bloc.state.operacion.tipo, TipoOperacion.exito);
      },
    );
  });

  // ── Detalle ───────────────────────────────────────────────────────────────

  group('PackingPedidoDetailBloc', () {
    late MockDetalle getDetalle;
    late MockCrear crear;
    late MockDeshacer deshacer;
    late MockConfig config;

    final porHacer = productoTest(id: 1);
    final listo = productoTest(
      id: 2,
      estado: EstadoProductoPacking.listo,
      certificado: true,
      quantitySeparate: 10,
    );
    final detalle = PedidoPackDetalle(
      pedido: pedidoTest,
      porHacer: [porHacer],
      listos: [listo],
    );

    setUp(() {
      getDetalle = MockDetalle();
      crear = MockCrear();
      deshacer = MockDeshacer();
      config = MockConfig();
      when(() => config(any())).thenAnswer(
        (_) async => const Right(ConfigPackingUsuario(scanProduct: true)),
      );
      when(() => getDetalle(any())).thenAnswer((_) async => Right(detalle));
    });

    PackingPedidoDetailBloc build() =>
        PackingPedidoDetailBloc(getDetalle, crear, deshacer, config);

    blocTest<PackingPedidoDetailBloc, PackingPedidoDetailState>(
      'abrir un pedido carga el detalle y limpia lo del anterior',
      build: build,
      seed: () => const PackingPedidoDetailState(
        pedidoId: 99,
        seleccionados: {5},
        isSticker: true,
        query: 'x',
      ),
      act: (bloc) => bloc.add(const DetallePackIniciado(10)),
      verify: (bloc) {
        expect(bloc.state.detalle, detalle);
        expect(bloc.state.seleccionados, isEmpty);
        expect(bloc.state.isSticker, isFalse);
        expect(bloc.state.query, '');
      },
    );

    blocTest<PackingPedidoDetailBloc, PackingPedidoDetailState>(
      'crear caja certificada manda solo los listos seleccionados y recarga',
      build: build,
      seed: () => PackingPedidoDetailState(
        pedidoId: 10,
        status: DetallePackStatus.listo,
        detalle: detalle,
        seleccionados: const {1, 2},
        isSticker: true,
      ),
      setUp: () => when(
        () => crear(any()),
      ).thenAnswer((_) async => Right(paqueteTest())),
      act: (bloc) => bloc.add(const PaquetePackCreado(certificado: true)),
      verify: (bloc) {
        final params =
            verify(() => crear(captureAny())).captured.single
                as CrearPaqueteParams;
        expect(params.productos, [listo]);
        expect(params.isSticker, isTrue);
        expect(bloc.state.seleccionados, {1});
        expect(bloc.state.isSticker, isFalse);
        verify(() => getDetalle(any())).called(1);
      },
    );

    blocTest<PackingPedidoDetailBloc, PackingPedidoDetailState>(
      'si falla al crear la caja conserva la selección',
      build: build,
      seed: () => PackingPedidoDetailState(
        pedidoId: 10,
        detalle: detalle,
        seleccionados: const {2},
      ),
      setUp: () => when(() => crear(any())).thenAnswer(
        (_) async => const Left(PackingValidationFailure('Peso inválido')),
      ),
      act: (bloc) => bloc.add(const PaquetePackCreado(certificado: true)),
      verify: (bloc) {
        expect(bloc.state.seleccionados, {2});
        expect(bloc.state.operacion.mensaje, 'Peso inválido');
      },
    );

    test('la búsqueda filtra por hacer', () {
      final s = PackingPedidoDetailState(detalle: detalle, query: 'zzz');
      expect(s.porHacerVisibles, isEmpty);
      expect(s.copyWith(query: '7701').porHacerVisibles, [porHacer]);
    });
  });

  // ── Escaneo ───────────────────────────────────────────────────────────────

  group('PackingScanBloc', () {
    late MockBarcodes barcodes;
    late MockConfig config;
    late MockNovedades novedades;
    late MockUbicOk ubicOk;
    late MockProdOk prodOk;
    late MockCantidad cantidad;
    late MockSeparar separar;
    late MockDividir dividir;
    late MockLeerTemp leerTemp;
    late MockEnviarTemp enviarTemp;
    late MockNovedadImg novedadImg;

    ProductoPacking linea({
      double quantity = 2,
      bool locationOk = false,
      bool productOk = false,
      bool temperatura = false,
    }) => productoTest(
      quantity: quantity,
      manejaTemperatura: temperatura,
    ).copyWith(locationOk: locationOk, productOk: productOk);

    setUp(() {
      barcodes = MockBarcodes();
      config = MockConfig();
      novedades = MockNovedades();
      ubicOk = MockUbicOk();
      prodOk = MockProdOk();
      cantidad = MockCantidad();
      separar = MockSeparar();
      dividir = MockDividir();
      leerTemp = MockLeerTemp();
      enviarTemp = MockEnviarTemp();
      novedadImg = MockNovedadImg();

      when(() => config(any())).thenAnswer(
        (_) async =>
            const Right(ConfigPackingUsuario(manualQuantityPack: true)),
      );
      when(() => novedades(any())).thenAnswer((_) async => const Right([]));
      when(() => barcodes(any())).thenAnswer(
        (_) async => const Right([
          BarcodeProductoPacking(idMove: 100, idProduct: 500, barcode: 'ALT'),
          BarcodeProductoPacking(
            idMove: 100,
            idProduct: 500,
            barcode: 'CAJA12',
            cantidad: 12,
          ),
        ]),
      );
      when(() => ubicOk(any())).thenAnswer(
        (i) async => Right(
          (i.positionalArguments.first as MarcarUbicacionOkParams).producto
              .copyWith(locationOk: true),
        ),
      );
      when(() => prodOk(any())).thenAnswer(
        (i) async => Right(
          (i.positionalArguments.first as MarcarProductoOkParams).producto
              .copyWith(productOk: true),
        ),
      );
      when(() => cantidad(any())).thenAnswer((i) async {
        final p =
            i.positionalArguments.first as ActualizarCantidadSeparadaParams;
        return Right(p.producto.copyWith(quantitySeparate: p.cantidad));
      });
      when(() => separar(any())).thenAnswer((i) async {
        final p = i.positionalArguments.first as SepararProductoParams;
        return Right(p.producto.copyWith(estado: EstadoProductoPacking.listo));
      });
      when(() => dividir(any())).thenAnswer((_) async => const Right(unit));
    });

    PackingScanBloc build() => PackingScanBloc(
      barcodes,
      config,
      novedades,
      ubicOk,
      prodOk,
      cantidad,
      separar,
      dividir,
      leerTemp,
      enviarTemp,
      novedadImg,
    );

    blocTest<PackingScanBloc, PackingScanState>(
      'ubicación incorrecta da error y no avanza',
      build: build,
      act: (bloc) async {
        bloc.add(ScanPackIniciado(linea()));
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(const ScanPackLeido('loc-a1-mal'))
          ..add(const ScanPackLeido(''))
          ..add(const ScanPackLeido('7701234')); // aún en ubicación: error
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.paso, PasoScanPack.ubicacion);
        expect(bloc.state.operacion.esError, isTrue);
        verifyNever(() => ubicOk(any()));
      },
    );

    blocTest<PackingScanBloc, PackingScanState>(
      'ubicación → producto (barcode alterno) → 2 escaneos → separada',
      build: build,
      act: (bloc) async {
        bloc.add(ScanPackIniciado(linea()));
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(const ScanPackLeido('loc-a1'))
          ..add(const ScanPackLeido('ALT'))
          ..add(const ScanPackLeido('7701234'))
          ..add(const ScanPackLeido('7701234'));
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.resultado, ResultadoScanPack.separado);
        expect(bloc.state.paso, PasoScanPack.terminado);
        expect(bloc.state.finalizado, isTrue);
        final params =
            verify(() => separar(captureAny())).captured.single
                as SepararProductoParams;
        expect(params.cantidad, 2);
        expect(params.novedad, isNull);
      },
    );

    blocTest<PackingScanBloc, PackingScanState>(
      'barcode de caja que se pasa del total da error y no suma',
      build: build,
      act: (bloc) async {
        bloc.add(ScanPackIniciado(linea(locationOk: true, productOk: true)));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ScanPackLeido('CAJA12'));
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.cantidad, 0);
        expect(bloc.state.operacion.mensaje, contains('no puede ser mayor'));
        verifyNever(() => cantidad(any()));
      },
    );

    blocTest<PackingScanBloc, PackingScanState>(
      'cantidad manual menor pide decisión; dividir llama al use case',
      build: build,
      act: (bloc) async {
        bloc.add(
          ScanPackIniciado(
            linea(quantity: 10, locationOk: true, productOk: true),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CantidadPackAplicada(4));
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.cantidadEnDecision, 4);
        bloc.add(const DivisionPackSolicitada());
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        final params =
            verify(() => dividir(captureAny())).captured.single
                as DividirProductoParams;
        expect(params.cantidad, 4);
        expect(bloc.state.resultado, ResultadoScanPack.dividido);
        expect(bloc.state.cantidadEnDecision, isNull);
      },
    );

    blocTest<PackingScanBloc, PackingScanState>(
      'cantidad cero o mayor al total da error',
      build: build,
      act: (bloc) async {
        bloc.add(
          ScanPackIniciado(
            linea(quantity: 10, locationOk: true, productOk: true),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CantidadPackAplicada(0));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CantidadPackAplicada(11));
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.operacion.esError, isTrue);
        verifyNever(() => separar(any()));
      },
    );

    blocTest<PackingScanBloc, PackingScanState>(
      'producto con temperatura queda pendiente de registrarla',
      build: build,
      setUp: () => when(
        () => enviarTemp(any()),
      ).thenAnswer((_) async => Right(productoTest(manejaTemperatura: true))),
      act: (bloc) async {
        bloc.add(
          ScanPackIniciado(
            linea(
              quantity: 3,
              locationOk: true,
              productOk: true,
              temperatura: true,
            ),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CantidadPackAplicada(3));
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.requiereTemperatura, isTrue);
        expect(bloc.state.finalizado, isFalse);
        bloc.add(const TemperaturaPackEnviada(4.5));
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.requiereTemperatura, isFalse);
        expect(bloc.state.finalizado, isTrue);
      },
    );

    blocTest<PackingScanBloc, PackingScanState>(
      'escaneo errado marca el paso en rojo y al acertar se limpia',
      build: build,
      act: (bloc) async {
        bloc.add(ScanPackIniciado(linea()));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ScanPackLeido('MAL'));
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.errorEn, PasoScanPack.ubicacion);
        bloc.add(const ScanPackLeido('loc-a1'));
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.paso, PasoScanPack.producto);
        expect(bloc.state.errorEn, isNull);
      },
    );

    blocTest<PackingScanBloc, PackingScanState>(
      'aceptar parcial con foto: sube la foto y después separa',
      build: build,
      setUp: () => when(() => novedadImg(any())).thenAnswer(
        (i) async => Right(
          (i.positionalArguments.first as EnviarImagenNovedadPackParams)
              .producto,
        ),
      ),
      act: (bloc) async {
        bloc.add(
          ScanPackIniciado(
            linea(quantity: 10, locationOk: true, productOk: true),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CantidadPackAplicada(4));
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const SeparacionParcialPackAceptada('Faltante', imagePath: '/f.jpg'),
        );
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        verifyInOrder([() => novedadImg(any()), () => separar(any())]);
        expect(bloc.state.resultado, ResultadoScanPack.separado);
      },
    );

    blocTest<PackingScanBloc, PackingScanState>(
      'si la foto falla no separa y se puede volver a aplicar',
      build: build,
      setUp: () => when(
        () => novedadImg(any()),
      ).thenAnswer((_) async => const Left(ServerFailure('sin red'))),
      act: (bloc) async {
        bloc.add(
          ScanPackIniciado(
            linea(quantity: 10, locationOk: true, productOk: true),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CantidadPackAplicada(4));
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const SeparacionParcialPackAceptada('Faltante', imagePath: '/f.jpg'),
        );
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        verifyNever(() => separar(any()));
        expect(bloc.state.cantidadEnDecision, isNull);
        expect(bloc.state.operacion.esError, isTrue);
      },
    );

    blocTest<PackingScanBloc, PackingScanState>(
      'producto escaneado desde por hacer arranca en la cantidad',
      build: build,
      act: (bloc) =>
          bloc.add(ScanPackIniciado(linea(), productoEscaneado: true)),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.paso, PasoScanPack.cantidad);
        verify(() => ubicOk(any())).called(1);
        verify(() => prodOk(any())).called(1);
      },
    );

    blocTest<PackingScanBloc, PackingScanState>(
      'sin permiso no deja confirmar la ubicación a mano',
      build: build,
      act: (bloc) async {
        bloc.add(ScanPackIniciado(linea()));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const UbicacionPackConfirmadaManual());
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.paso, PasoScanPack.ubicacion);
        verifyNever(() => ubicOk(any()));
      },
    );
  });

  // ── Paquetes ──────────────────────────────────────────────────────────────

  group('PackingPackagesBloc', () {
    late MockDesempacar desempacar;
    late MockEliminar eliminar;
    late MockUbicaciones ubicaciones;
    late MockAsignarUbic asignar;

    final p1 = paqueteTest(id: 1, packingBarcode: 'PK1');
    final p2 = paqueteTest(id: 2, packingBarcode: 'PK2');

    setUp(() {
      desempacar = MockDesempacar();
      eliminar = MockEliminar();
      ubicaciones = MockUbicaciones();
      asignar = MockAsignarUbic();
    });

    PackingPackagesBloc build() =>
        PackingPackagesBloc(desempacar, eliminar, ubicaciones, asignar);

    blocTest<PackingPackagesBloc, PackingPackagesState>(
      'escanear una caja la selecciona; una desconocida da error',
      build: build,
      seed: () => PackingPackagesState(pedido: pedidoTest, paquetes: [p1, p2]),
      act: (bloc) => bloc
        ..add(const PaquetePackEscaneado('pk2'))
        ..add(const PaquetePackEscaneado('NOPE')),
      verify: (bloc) {
        expect(bloc.state.seleccionados, {2});
        expect(bloc.state.operacion.esError, isTrue);
      },
    );

    blocTest<PackingPackagesBloc, PackingPackagesState>(
      'desempacar exitoso sube cambios para recargar el detalle',
      build: build,
      seed: () => PackingPackagesState(pedido: pedidoTest, paquetes: [p1]),
      setUp: () => when(
        () => desempacar(any()),
      ).thenAnswer((_) async => const Right(DesempaqueResult(mensaje: 'ok'))),
      act: (bloc) => bloc.add(
        ProductoPackDesempacado(
          p1,
          productoTest(estado: EstadoProductoPacking.empacado, idPackage: 1),
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.cambios, 1);
        expect(bloc.state.operacion.tipo, TipoOperacion.exito);
      },
    );

    blocTest<PackingPackagesBloc, PackingPackagesState>(
      'desempaque desincronizado avisa refrescar',
      build: build,
      seed: () => PackingPackagesState(pedido: pedidoTest, paquetes: [p1]),
      setUp: () => when(() => desempacar(any())).thenAnswer(
        (_) async => const Right(
          DesempaqueResult(mensaje: 'actualice', desincronizado: true),
        ),
      ),
      act: (bloc) => bloc.add(ProductoPackDesempacado(p1, productoTest())),
      verify: (bloc) =>
          expect(bloc.state.operacion.tipo, TipoOperacion.desincronizado),
    );

    blocTest<PackingPackagesBloc, PackingPackagesState>(
      'asignar sin ubicación elegida da error sin llamar al servidor',
      build: build,
      seed: () => PackingPackagesState(
        pedido: pedidoTest,
        paquetes: [p1],
        seleccionados: const {1},
      ),
      act: (bloc) => bloc.add(const UbicacionPaquetesPackAsignada()),
      verify: (bloc) {
        expect(bloc.state.operacion.esError, isTrue);
        verifyNever(() => asignar(any()));
      },
    );

    blocTest<PackingPackagesBloc, PackingPackagesState>(
      'asignar con ubicación escaneada manda los seleccionados y limpia',
      build: build,
      seed: () => PackingPackagesState(
        pedido: pedidoTest,
        paquetes: [p1, p2],
        seleccionados: const {1, 2},
        ubicaciones: const [
          UbicacionMuelle(id: 9, name: 'MUELLE-9', barcode: 'M9'),
        ],
      ),
      setUp: () =>
          when(() => asignar(any())).thenAnswer((_) async => const Right('ok')),
      act: (bloc) => bloc
        ..add(const UbicacionMuellePackEscaneada('m9'))
        ..add(const UbicacionPaquetesPackAsignada()),
      verify: (bloc) {
        final params =
            verify(() => asignar(captureAny())).captured.single
                as AsignarUbicacionPaquetesParams;
        expect(params.paquetes, [p1, p2]);
        expect(params.ubicacion.id, 9);
        expect(bloc.state.seleccionados, isEmpty);
        expect(bloc.state.ubicacion, isNull);
        expect(bloc.state.cambios, 1);
      },
    );

    blocTest<PackingPackagesBloc, PackingPackagesState>(
      'al actualizar paquetes se descarta la selección de cajas que ya no existen',
      build: build,
      seed: () => PackingPackagesState(
        pedido: pedidoTest,
        paquetes: [p1, p2],
        seleccionados: const {1, 2},
        expandido: 2,
      ),
      act: (bloc) => bloc.add(PaquetesPackActualizados(pedidoTest, [p1])),
      verify: (bloc) {
        expect(bloc.state.seleccionados, {1});
        expect(bloc.state.expandido, isNull);
      },
    );
  });

  // ── Confirmación ──────────────────────────────────────────────────────────

  group('PackingConfirmBloc', () {
    late MockValidar validar;
    final detalleCerrable = PedidoPackDetalle(
      pedido: pedidoTest,
      paquetes: [paqueteTest()],
    );

    setUp(() => validar = MockValidar());

    blocTest<PackingConfirmBloc, PackingConfirmState>(
      'vencidos: queda esperando y al aceptar reintenta aceptándolos',
      build: () => PackingConfirmBloc(validar),
      setUp: () {
        var llamada = 0;
        when(() => validar(any())).thenAnswer((_) async {
          llamada++;
          return llamada == 1
              ? const Left(
                  PackingVencidosFailure('expiry.picking.confirmation'),
                )
              : const Right(
                  ValidacionPedidoResult(mensaje: 'ok', conBackorder: true),
                );
        });
      },
      act: (bloc) async {
        bloc.add(
          ValidacionPackSolicitada(detalleCerrable, crearBackorder: true),
        );
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.vencidosPendientes, isNotNull);
        expect(bloc.state.operacion.procesando, isFalse);
        bloc.add(const VencidosPackAceptados());
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        final calls = verify(
          () => validar(captureAny()),
        ).captured.cast<ValidarPedidoPackParams>();
        expect(calls.map((c) => c.aceptarVencidos), [false, true]);
        expect(calls.last.crearBackorder, isTrue);
        expect(bloc.state.validado, isTrue);
        expect(bloc.state.vencidosPendientes, isNull);
      },
    );

    blocTest<PackingConfirmBloc, PackingConfirmState>(
      'error normal no deja vencidos pendientes',
      build: () => PackingConfirmBloc(validar),
      setUp: () => when(
        () => validar(any()),
      ).thenAnswer((_) async => const Left(ServerFailure('no se pudo'))),
      act: (bloc) => bloc.add(
        ValidacionPackSolicitada(detalleCerrable, crearBackorder: false),
      ),
      verify: (bloc) {
        expect(bloc.state.validado, isFalse);
        expect(bloc.state.vencidosPendientes, isNull);
        expect(bloc.state.operacion.mensaje, 'no se pudo');
      },
    );

    blocTest<PackingConfirmBloc, PackingConfirmState>(
      'con listos sin empacar o sin cajas no llega a Odoo',
      build: () => PackingConfirmBloc(validar),
      act: (bloc) => bloc
        ..add(
          ValidacionPackSolicitada(
            PedidoPackDetalle(
              pedido: pedidoTest,
              paquetes: [paqueteTest()],
              listos: [productoTest(estado: EstadoProductoPacking.listo)],
            ),
            crearBackorder: false,
          ),
        )
        ..add(
          const ValidacionPackSolicitada(
            PedidoPackDetalle(pedido: pedidoTest),
            crearBackorder: false,
          ),
        ),
      verify: (bloc) {
        expect(bloc.state.operacion.mensaje, contains('sin paquetes'));
        verifyNever(() => validar(any()));
      },
    );
  });
}
