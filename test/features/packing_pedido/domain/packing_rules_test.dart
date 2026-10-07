import 'package:flutter_test/flutter_test.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_resultados.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/pedido_pack.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/rules/packing_rules.dart';

import 'packing_test_data.dart';

void main() {
  group('evaluarCantidad', () {
    final p = productoTest(quantity: 10);

    test('cero, negativa o NaN es inválida', () {
      expect(PackingRules.evaluarCantidad(p, 0), ValidacionCantidad.invalida);
      expect(PackingRules.evaluarCantidad(p, -1), ValidacionCantidad.invalida);
      expect(
        PackingRules.evaluarCantidad(p, double.nan),
        ValidacionCantidad.invalida,
      );
    });

    test('igual es completa (tolera error de punto flotante)', () {
      expect(PackingRules.evaluarCantidad(p, 10), ValidacionCantidad.completa);
      final dec = productoTest(quantity: 0.3);
      expect(
        PackingRules.evaluarCantidad(dec, 0.1 + 0.2),
        ValidacionCantidad.completa,
      );
    });

    test('menor es parcial y mayor excede', () {
      expect(PackingRules.evaluarCantidad(p, 4), ValidacionCantidad.parcial);
      expect(PackingRules.evaluarCantidad(p, 11), ValidacionCantidad.excede);
    });
  });

  group('puedeSumarEscaneo', () {
    final p = productoTest(quantity: 12);

    test('suma mientras no pase de la cantidad', () {
      expect(
        PackingRules.puedeSumarEscaneo(p, actual: 11, incremento: 1),
        isTrue,
      );
      expect(
        PackingRules.puedeSumarEscaneo(p, actual: 0, incremento: 12),
        isTrue,
      );
    });

    test('no deja pasar de la cantidad (barcode de empaque)', () {
      expect(
        PackingRules.puedeSumarEscaneo(p, actual: 12, incremento: 1),
        isFalse,
      );
      expect(
        PackingRules.puedeSumarEscaneo(p, actual: 6, incremento: 12),
        isFalse,
      );
    });

    test('incremento cero o negativo no suma', () {
      expect(
        PackingRules.puedeSumarEscaneo(p, actual: 0, incremento: 0),
        isFalse,
      );
    });
  });

  group('validarDivision', () {
    test('permite dividir una parte menor de un producto por hacer', () {
      expect(PackingRules.validarDivision(productoTest(), 4), isNull);
      expect(PackingRules.validarDivision(productoTest(), 0.5), isNull);
    });

    test('rechaza cero, la cantidad completa o más', () {
      expect(PackingRules.validarDivision(productoTest(), 0), isNotNull);
      expect(PackingRules.validarDivision(productoTest(), 10), isNotNull);
      expect(PackingRules.validarDivision(productoTest(), 11), isNotNull);
    });

    test('rechaza productos que no están por hacer', () {
      final listo = productoTest(estado: EstadoProductoPacking.listo);
      expect(PackingRules.validarDivision(listo, 4), isNotNull);
    });
  });

  group('validarSeparacion', () {
    test('acepta completa y parcial', () {
      expect(PackingRules.validarSeparacion(productoTest(), 10), isNull);
      expect(PackingRules.validarSeparacion(productoTest(), 3), isNull);
    });

    test('rechaza cero, excedente y ya separado', () {
      expect(PackingRules.validarSeparacion(productoTest(), 0), isNotNull);
      expect(PackingRules.validarSeparacion(productoTest(), 15), isNotNull);
      final listo = productoTest(estado: EstadoProductoPacking.listo);
      expect(PackingRules.validarSeparacion(listo, 10), isNotNull);
    });
  });

  group('validarEmpaque', () {
    final listo = productoTest(
      estado: EstadoProductoPacking.listo,
      certificado: true,
      quantitySeparate: 10,
    );

    test('acepta listos certificados', () {
      expect(PackingRules.validarEmpaque([listo], certificado: true), isNull);
    });

    test('acepta por hacer sin certificar', () {
      expect(
        PackingRules.validarEmpaque([productoTest()], certificado: false),
        isNull,
      );
    });

    test('rechaza lista vacía', () {
      expect(PackingRules.validarEmpaque([], certificado: true), isNotNull);
    });

    test('rechaza mezcla de pedidos', () {
      final otro = productoTest(
        id: 2,
        pedidoId: 99,
        estado: EstadoProductoPacking.listo,
        certificado: true,
        quantitySeparate: 1,
      );
      expect(
        PackingRules.validarEmpaque([listo, otro], certificado: true),
        isNotNull,
      );
    });

    test('rechaza productos ya empacados o en otro estado', () {
      final empacado = productoTest(
        estado: EstadoProductoPacking.empacado,
        idPackage: 3,
      );
      expect(
        PackingRules.validarEmpaque([empacado], certificado: true),
        isNotNull,
      );
      expect(
        PackingRules.validarEmpaque([productoTest()], certificado: true),
        isNotNull,
      );
    });

    test('rechaza certificados con cantidad separada en cero', () {
      final sinCantidad = productoTest(
        estado: EstadoProductoPacking.listo,
        certificado: true,
      );
      expect(
        PackingRules.validarEmpaque([sinCantidad], certificado: true),
        contains('no tiene cantidad'),
      );
    });
  });

  group('recalcularConsecutivos', () {
    test('corre las cajas posteriores conservando sus datos', () {
      final c1 = paqueteTest(id: 1, consecutivo: 'Caja1');
      final c2 = paqueteTest(id: 2, consecutivo: 'Caja2');
      final c3 = paqueteTest(
        id: 3,
        consecutivo: 'Caja3',
        packingBarcode: 'PACK0003',
        locationDestId: 7,
      );

      final cambios = PackingRules.recalcularConsecutivos([
        c1,
        c2,
        c3,
      ], eliminado: c2);

      expect(cambios, hasLength(1));
      expect(cambios.single.id, 3);
      expect(cambios.single.consecutivo, 'Caja2');
      // Bug del legacy: al recalcular se perdían barcode y ubicación destino.
      expect(cambios.single.packingBarcode, 'PACK0003');
      expect(cambios.single.locationDestId, 7);
      expect(cambios.single.locationDestName, 'MUELLE-1');
    });

    test('sin número en el eliminado no cambia nada', () {
      final cambios = PackingRules.recalcularConsecutivos([
        paqueteTest(id: 2, consecutivo: 'Caja2'),
      ], eliminado: paqueteTest(id: 1, consecutivo: 'Especial'));
      expect(cambios, isEmpty);
    });
  });

  group('ProductoPacking', () {
    test(
      'cantidadAEnviar: certificado usa lo separado sin pasar del total',
      () {
        expect(
          productoTest(certificado: true, quantitySeparate: 4).cantidadAEnviar,
          4,
        );
        expect(
          productoTest(certificado: true, quantitySeparate: 15).cantidadAEnviar,
          10,
        );
        expect(productoTest().cantidadAEnviar, 10);
      },
    );

    test('coincideCon busca por barcode, código y nombre', () {
      final p = productoTest(productName: 'Leche Entera');
      expect(p.coincideCon('7701'), isTrue);
      expect(p.coincideCon('pa-01'), isTrue);
      expect(p.coincideCon('leche'), isTrue);
      expect(p.coincideCon('arroz'), isFalse);
      expect(p.coincideCon('  '), isTrue);
    });
  });

  group('PedidoPackDetalle.progreso', () {
    test('porcentaje de lo separado sobre el total', () {
      final detalle = PedidoPackDetalle(
        pedido: pedidoTest,
        porHacer: [productoTest(id: 1, quantity: 6)],
        listos: [
          productoTest(
            id: 2,
            quantity: 4,
            quantitySeparate: 4,
            certificado: true,
            estado: EstadoProductoPacking.listo,
          ),
        ],
      );
      expect(detalle.progreso, 40);
    });

    test('pedido vacío es 0', () {
      expect(const PedidoPackDetalle(pedido: pedidoTest).progreso, 0);
    });
  });

  group('PaquetePacking', () {
    test('coincideCon por nombre o barcode', () {
      final p = paqueteTest(id: 5);
      expect(p.coincideCon('pack-5'), isTrue);
      expect(p.coincideCon('PACK0001'), isTrue);
      expect(p.coincideCon(''), isFalse);
    });
  });

  group('validarCierre', () {
    test('pide cajas y que no queden listos', () {
      expect(
        PackingRules.validarCierre(const PedidoPackDetalle(pedido: pedidoTest)),
        contains('sin paquetes'),
      );
      expect(
        PackingRules.validarCierre(
          PedidoPackDetalle(
            pedido: pedidoTest,
            paquetes: [paqueteTest()],
            listos: [productoTest(estado: EstadoProductoPacking.listo)],
          ),
        ),
        contains('listos'),
      );
      expect(
        PackingRules.validarCierre(
          PedidoPackDetalle(pedido: pedidoTest, paquetes: [paqueteTest()]),
        ),
        isNull,
      );
    });
  });

  group('PedidoPackDetalle', () {
    test('porHacerConCodigo: barcode, código o alterno del producto', () {
      final p = productoTest();
      final d = PedidoPackDetalle(
        pedido: pedidoTest,
        porHacer: [p],
        barcodes: const [
          BarcodeProductoPacking(idMove: 1, idProduct: 500, barcode: 'CAJA12'),
        ],
      );
      expect(d.porHacerConCodigo('7701234'), p);
      expect(d.porHacerConCodigo('pa-01'), p);
      expect(d.porHacerConCodigo('caja12'), p);
      expect(d.porHacerConCodigo('nada'), isNull);
    });

    test('progresoEmpacado sobre las unidades del pedido', () {
      final d = PedidoPackDetalle(
        pedido: const PedidoPack(id: 10, numeroItems: 20),
        empacados: [
          productoTest(
            estado: EstadoProductoPacking.empacado,
            quantity: 5,
            quantitySeparate: 5,
            certificado: true,
          ),
        ],
      );
      expect(d.progresoEmpacado, 25);
    });

    test('cantidadPreparados y cantidadPreparada calculan sobre listos', () {
      final d = PedidoPackDetalle(
        pedido: const PedidoPack(id: 10, numeroItems: 20),
        listos: [
          productoTest(
            id: 1,
            estado: EstadoProductoPacking.listo,
            certificado: true,
            quantity: 10,
            quantitySeparate: 4,
          ),
          productoTest(
            id: 2,
            estado: EstadoProductoPacking.listo,
            certificado: true,
            quantity: 6,
            quantitySeparate: 6,
          ),
        ],
      );
      expect(d.cantidadPreparados, 2);
      expect(d.cantidadPreparada, 10.0);
    });
  });

  group('PedidoPack', () {
    test('coincideConEscaneo y ubicación visible de cluster', () {
      const p = PedidoPack(
        id: 1,
        name: 'WH/PACK/1',
        zonaEntrega: 'ZONA-NORTE',
        configPacking: 'cluster',
        locationName: 'A',
        locationNameCluster: 'CL-1',
      );
      expect(p.coincideConEscaneo('zona-norte'), isTrue);
      expect(p.coincideConEscaneo(''), isFalse);
      expect(p.ubicacionVisible, 'CL-1');
    });
  });
}
