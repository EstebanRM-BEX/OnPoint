import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_resultados.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/failures/packing_failures.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/actualizar_cantidad_separada_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/asignar_ubicacion_paquetes_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/crear_paquete_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/desempacar_producto_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/deshacer_separacion_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/dividir_producto_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/eliminar_paquete_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/enviar_temperatura_pack_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/refrescar_detalle_pack_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/separar_producto_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/validar_pedido_pack_usecase.dart';

import 'packing_test_data.dart';

class MockRepo extends Mock implements PackingPedidoRepository {}

void main() {
  late MockRepo repo;

  setUpAll(() {
    registerFallbackValue(productoTest());
    registerFallbackValue(paqueteTest());
    registerFallbackValue(pedidoTest);
    registerFallbackValue(const UbicacionMuelle(id: 0));
  });

  setUp(() => repo = MockRepo());

  void expectValidation(Either result) {
    expect(result.isLeft(), isTrue);
    result.match(
      (f) => expect(f, isA<PackingValidationFailure>()),
      (_) => fail('se esperaba Left'),
    );
  }

  group('DividirProductoUseCase', () {
    late DividirProductoUseCase useCase;
    setUp(() => useCase = DividirProductoUseCase(repo));

    test('delega al repositorio con una cantidad válida', () async {
      when(
        () => repo.dividirProducto(
          producto: any(named: 'producto'),
          cantidad: any(named: 'cantidad'),
        ),
      ).thenAnswer((_) async => const Right(unit));

      final r = await useCase(
        DividirProductoParams(producto: productoTest(), cantidad: 4),
      );

      expect(r, const Right(unit));
      verify(
        () => repo.dividirProducto(producto: productoTest(), cantidad: 4),
      ).called(1);
    });

    test('no llega al repositorio con cantidad completa', () async {
      final r = await useCase(
        DividirProductoParams(producto: productoTest(), cantidad: 10),
      );
      expectValidation(r);
      verifyZeroInteractions(repo);
    });
  });

  group('SepararProductoUseCase', () {
    late SepararProductoUseCase useCase;
    setUp(() => useCase = SepararProductoUseCase(repo));

    void stubSeparar() {
      when(
        () => repo.separarProducto(
          producto: any(named: 'producto'),
          cantidad: any(named: 'cantidad'),
          novedad: any(named: 'novedad'),
        ),
      ).thenAnswer((_) async => Right(productoTest()));
    }

    test('completa no exige novedad', () async {
      stubSeparar();
      final r = await useCase(
        SepararProductoParams(producto: productoTest(), cantidad: 10),
      );
      expect(r.isRight(), isTrue);
    });

    test('parcial sin novedad se rechaza', () async {
      final r = await useCase(
        SepararProductoParams(producto: productoTest(), cantidad: 3),
      );
      expectValidation(r);
      verifyZeroInteractions(repo);
    });

    test('parcial con novedad se envía recortada', () async {
      stubSeparar();
      await useCase(
        SepararProductoParams(
          producto: productoTest(),
          cantidad: 3,
          novedad: '  Faltante  ',
        ),
      );
      verify(
        () => repo.separarProducto(
          producto: productoTest(),
          cantidad: 3,
          novedad: 'Faltante',
        ),
      ).called(1);
    });

    test('cantidad cero se rechaza (el legacy la dejaba pasar)', () async {
      final r = await useCase(
        SepararProductoParams(
          producto: productoTest(),
          cantidad: 0,
          novedad: 'Faltante',
        ),
      );
      expectValidation(r);
    });
  });

  group('ActualizarCantidadSeparadaUseCase', () {
    late ActualizarCantidadSeparadaUseCase useCase;
    setUp(() => useCase = ActualizarCantidadSeparadaUseCase(repo));

    test('no deja pasar de la cantidad de la línea', () async {
      final r = await useCase(
        ActualizarCantidadSeparadaParams(
          producto: productoTest(),
          cantidad: 11,
        ),
      );
      expectValidation(r);
      verifyZeroInteractions(repo);
    });

    test('acepta cero y hasta el total', () async {
      when(
        () => repo.actualizarCantidadSeparada(any(), any()),
      ).thenAnswer((_) async => Right(productoTest()));
      expect(
        (await useCase(
          ActualizarCantidadSeparadaParams(
            producto: productoTest(),
            cantidad: 0,
          ),
        )).isRight(),
        isTrue,
      );
      expect(
        (await useCase(
          ActualizarCantidadSeparadaParams(
            producto: productoTest(),
            cantidad: 10,
          ),
        )).isRight(),
        isTrue,
      );
    });
  });

  group('DeshacerSeparacionUseCase', () {
    test('solo acepta productos listos', () async {
      final useCase = DeshacerSeparacionUseCase(repo);
      expectValidation(
        await useCase(DeshacerSeparacionParams(producto: productoTest())),
      );

      when(
        () => repo.cancelarPreparados(
          pedidoId: any(named: 'pedidoId'),
          productos: any(named: 'productos'),
        ),
      ).thenAnswer((_) async => const Right('Productos devueltos a por hacer'));
      final listo = productoTest(estado: EstadoProductoPacking.listo);
      expect(
        await useCase(DeshacerSeparacionParams(producto: listo)),
        const Right('Productos devueltos a por hacer'),
      );
    });
  });

  group('CrearPaqueteUseCase', () {
    late CrearPaqueteUseCase useCase;
    setUp(() => useCase = CrearPaqueteUseCase(repo));

    final listo = productoTest(
      estado: EstadoProductoPacking.listo,
      certificado: true,
      quantitySeparate: 10,
    );

    test('pedido terminado se rechaza', () async {
      final r = await useCase(
        CrearPaqueteParams(
          pedido: pedidoTest.copyWith(isTerminate: true),
          productos: [listo],
          certificado: true,
          isSticker: false,
        ),
      );
      expectValidation(r);
    });

    test('productos de otro pedido se rechazan', () async {
      final r = await useCase(
        CrearPaqueteParams(
          pedido: pedidoTest,
          productos: [
            productoTest(
              pedidoId: 99,
              estado: EstadoProductoPacking.listo,
              certificado: true,
              quantitySeparate: 1,
            ),
          ],
          certificado: true,
          isSticker: false,
        ),
      );
      expectValidation(r);
    });

    test('peso negativo se rechaza', () async {
      final r = await useCase(
        CrearPaqueteParams(
          pedido: pedidoTest,
          productos: [listo],
          certificado: true,
          isSticker: false,
          peso: -1,
        ),
      );
      expectValidation(r);
    });

    test('válido delega al repositorio', () async {
      when(
        () => repo.crearPaquete(
          pedido: any(named: 'pedido'),
          productos: any(named: 'productos'),
          certificado: any(named: 'certificado'),
          isSticker: any(named: 'isSticker'),
          peso: any(named: 'peso'),
          tipoEmpaque: any(named: 'tipoEmpaque'),
        ),
      ).thenAnswer((_) async => Right(paqueteTest()));

      final r = await useCase(
        CrearPaqueteParams(
          pedido: pedidoTest,
          productos: [listo],
          certificado: true,
          isSticker: true,
          peso: 2.5,
        ),
      );
      expect(r, Right(paqueteTest()));
    });
  });

  group('DesempacarProductoUseCase', () {
    late DesempacarProductoUseCase useCase;
    setUp(() => useCase = DesempacarProductoUseCase(repo));

    final empacado = productoTest(
      estado: EstadoProductoPacking.empacado,
      idPackage: 1,
    );

    test('pedido terminado se rechaza', () async {
      expectValidation(
        await useCase(
          DesempacarProductoParams(
            pedido: pedidoTest.copyWith(isTerminate: true),
            paquete: paqueteTest(id: 1),
            producto: empacado,
          ),
        ),
      );
    });

    test('producto de otro paquete se rechaza', () async {
      expectValidation(
        await useCase(
          DesempacarProductoParams(
            pedido: pedidoTest,
            paquete: paqueteTest(id: 2),
            producto: empacado,
          ),
        ),
      );
      verifyZeroInteractions(repo);
    });

    test('válido delega al repositorio', () async {
      when(
        () => repo.desempacarProducto(
          paquete: any(named: 'paquete'),
          producto: any(named: 'producto'),
        ),
      ).thenAnswer((_) async => const Right(DesempaqueResult(mensaje: 'ok')));
      final r = await useCase(
        DesempacarProductoParams(
          pedido: pedidoTest,
          paquete: paqueteTest(id: 1),
          producto: empacado,
        ),
      );
      expect(r.isRight(), isTrue);
    });
  });

  group('EliminarPaqueteUseCase', () {
    test('rechaza pedido terminado y paquete de otro pedido', () async {
      final useCase = EliminarPaqueteUseCase(repo);
      expectValidation(
        await useCase(
          EliminarPaqueteParams(
            pedido: pedidoTest.copyWith(isTerminate: true),
            paquete: paqueteTest(),
          ),
        ),
      );
      expectValidation(
        await useCase(
          EliminarPaqueteParams(
            pedido: pedidoTest,
            paquete: paqueteTest(pedidoId: 99),
          ),
        ),
      );
      verifyZeroInteractions(repo);
    });
  });

  group('AsignarUbicacionPaquetesUseCase', () {
    test('lista vacía se rechaza', () async {
      final useCase = AsignarUbicacionPaquetesUseCase(repo);
      expectValidation(
        await useCase(
          const AsignarUbicacionPaquetesParams(
            pedidoId: 10,
            paquetes: [],
            ubicacion: UbicacionMuelle(id: 1),
          ),
        ),
      );
    });
  });

  group('ValidarPedidoPackUseCase', () {
    test('propaga crearBackorder y aceptarVencidos', () async {
      when(
        () => repo.validarPedido(
          pedidoId: any(named: 'pedidoId'),
          crearBackorder: any(named: 'crearBackorder'),
          aceptarVencidos: any(named: 'aceptarVencidos'),
        ),
      ).thenAnswer(
        (_) async => const Right(
          ValidacionPedidoResult(mensaje: 'ok', conBackorder: true),
        ),
      );

      await ValidarPedidoPackUseCase(repo)(
        const ValidarPedidoPackParams(
          pedido: pedidoTest,
          crearBackorder: true,
          aceptarVencidos: true,
        ),
      );

      verify(
        () => repo.validarPedido(
          pedidoId: 10,
          crearBackorder: true,
          aceptarVencidos: true,
        ),
      ).called(1);
    });
  });

  group('EnviarTemperaturaPackUseCase', () {
    late EnviarTemperaturaPackUseCase useCase;
    setUp(() => useCase = EnviarTemperaturaPackUseCase(repo));

    test('producto sin temperatura se rechaza', () async {
      expectValidation(
        await useCase(
          EnviarTemperaturaPackParams(producto: productoTest(), temperatura: 4),
        ),
      );
    });

    test('ruta de imagen vacía se trata como manual', () async {
      when(
        () => repo.enviarTemperatura(
          producto: any(named: 'producto'),
          temperatura: any(named: 'temperatura'),
          imagePath: any(named: 'imagePath'),
        ),
      ).thenAnswer((_) async => Right(productoTest()));

      final p = productoTest(manejaTemperatura: true);
      await useCase(
        EnviarTemperaturaPackParams(
          producto: p,
          temperatura: 4,
          imagePath: ' ',
        ),
      );
      verify(
        () => repo.enviarTemperatura(producto: p, temperatura: 4),
      ).called(1);
    });
  });

  group('RefrescarDetallePackUseCase', () {
    late RefrescarDetallePackUseCase useCase;
    setUp(() => useCase = RefrescarDetallePackUseCase(repo));

    test('delega al repositorio con el id del pedido', () async {
      final detalle = PedidoPackDetalle(
        pedido: pedidoTest,
        porHacer: const [],
        listos: const [],
      );
      when(
        () => repo.refrescarDetalleRemoto(123),
      ).thenAnswer((_) async => Right(detalle));

      final r = await useCase(const RefrescarDetallePackParams(pedidoId: 123));

      expect(r, Right(detalle));
      verify(() => repo.refrescarDetalleRemoto(123)).called(1);
    });
  });
}
