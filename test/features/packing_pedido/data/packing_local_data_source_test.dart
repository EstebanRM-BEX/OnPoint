import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/features/packing_pedido/data/datasources/local/packing_pedido_database.dart';
import 'package:wms_app/features/packing_pedido/data/datasources/packing_pedido_local_data_source.dart';
import 'package:wms_app/features/packing_pedido/data/models/packing_api_models.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_resultados.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';

/// JSON de un pedido como lo manda `transferencias/pack`.
Map<String, dynamic> pedidoJson({
  int id = 10,
  List<Map<String, dynamic>> productos = const [],
  List<Map<String, dynamic>>? paquetes = const [],
}) => {
  'id': id,
  'batch_id': false,
  'name': 'WH/PACK/$id',
  'config_packing': false,
  'priority': '0',
  'location_dest_id': 30,
  'location_dest_name': 'WH/Salida',
  'lista_productos': productos,
  if (paquetes != null) 'lista_paquetes': paquetes,
};

Map<String, dynamic> moveJson({
  int idMove = 100,
  int idProduct = 500,
  double quantity = 10,
  dynamic loteId = false,
  String barcodeLocation = 'LOC-A1',
}) => {
  'id_move': idMove,
  'id_product': idProduct,
  'product_id': [idProduct, 'Producto $idProduct'],
  'product_code': 'P$idProduct',
  'barcode': '770$idProduct',
  'location_id': [20, 'WH/Stock/A1'],
  'location_dest_id': [30, 'WH/Salida'],
  'barcode_location': barcodeLocation,
  'lote_id': loteId,
  'lot_id': false,
  'quantity': quantity,
  'tracking': 'none',
  'weight': false,
  'product_packing': [
    {'barcode': 'CAJA12-$idProduct', 'id_product': idProduct, 'cantidad': 12},
  ],
  'other_barcode': [
    {'barcode': 'ALT-$idProduct', 'id_product': idProduct, 'cantidad': 1},
  ],
};

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;
  late PackingPedidoLocalDataSourceImpl local;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await PackingPedidoDatabase.createSchema(db);
    local = PackingPedidoLocalDataSourceImpl(
      PackingPedidoDatabase.withDatabase(db),
    );
  });

  tearDown(() => db.close());

  Future<void> sync(List<Map<String, dynamic>> pedidos) =>
      local.guardarSync(pedidos.map(PedidoPackApi.fromMap).toList());

  Future<PedidoPackDetalle> detalle([int id = 10]) => local.getDetalle(id);

  double total(List<ProductoPacking> l) => l.fold(0, (s, p) => s + p.quantity);

  group('sincronización', () {
    test('guarda pedido, líneas por hacer y barcodes', () async {
      await sync([
        pedidoJson(
          productos: [moveJson(), moveJson(idMove: 101, idProduct: 501)],
        ),
      ]);

      final d = await detalle();
      expect(d.pedido.name, 'WH/PACK/10');
      expect(d.porHacer, hasLength(2));
      expect(d.porHacer.first.productName, 'Producto 500');
      expect(d.porHacer.first.locationName, 'WH/Stock/A1');

      final barcodes = await local.getBarcodes(10, 500);
      expect(
        barcodes.map((b) => b.barcode),
        containsAll(['CAJA12-500', 'ALT-500']),
      );
      expect(
        barcodes.firstWhere((b) => b.barcode == 'CAJA12-500').cantidad,
        12,
      );
    });

    test('borra pedidos que ya no vienen, con todo lo suyo', () async {
      await sync([
        pedidoJson(productos: [moveJson()]),
        pedidoJson(id: 11, productos: [moveJson(idMove: 200)]),
      ]);
      await sync([
        pedidoJson(productos: [moveJson()]),
      ]);

      final pedidos = await local.getPedidos();
      expect(pedidos.map((p) => p.id), [10]);
      expect(
        await db.query(
          PackingPedidoDatabase.tProductos,
          where: 'pedido_id = 11',
        ),
        isEmpty,
      );
    });

    test(
      'conserva lo separado sin empacar y deja el resto por hacer',
      () async {
        await sync([
          pedidoJson(productos: [moveJson()]),
        ]);
        final linea = (await detalle()).porHacer.single;
        await local.dividir(linea, 4, DateTime.now());

        // Odoo todavía ve el move completo (10): nada se empacó.
        await sync([
          pedidoJson(productos: [moveJson()]),
        ]);

        final d = await detalle();
        expect(d.listos.single.quantity, 4);
        expect(d.porHacer.single.quantity, 6);
      },
    );

    test(
      'Odoo bajó la cantidad por debajo de lo separado: se descarta lo local',
      () async {
        await sync([
          pedidoJson(productos: [moveJson()]),
        ]);
        await local.dividir(
          (await detalle()).porHacer.single,
          8,
          DateTime.now(),
        );

        await sync([
          pedidoJson(productos: [moveJson(quantity: 5)]),
        ]);

        final d = await detalle();
        expect(d.listos, isEmpty);
        expect(d.porHacer.single.quantity, 5);
      },
    );

    test(
      'lista_paquetes reemplaza las cajas; sin el campo no se tocan',
      () async {
        final caja = {
          'id': 900,
          'name': 'PACK-900',
          'packing_barcode': 'PK900',
          'consecutivo': 'Caja1',
          'lista_productos_in_packing': [
            {
              ...moveJson(idMove: 150, quantity: 3),
              'lote_id': [77, 'L-77'],
            },
          ],
        };
        await sync([
          pedidoJson(productos: [moveJson()], paquetes: [caja]),
        ]);
        var d = await detalle();
        expect(d.paquetes.single.productos.single.loteId, 77);
        expect(d.paquetes.single.productos.single.loteName, 'L-77');

        await sync([
          pedidoJson(productos: [moveJson()], paquetes: null),
        ]);
        d = await detalle();
        expect(d.paquetes, hasLength(1));

        await sync([
          pedidoJson(productos: [moveJson()], paquetes: []),
        ]);
        d = await detalle();
        expect(d.paquetes, isEmpty);
        expect(d.empacados, isEmpty);
      },
    );

    test('ensureOwner borra todo si cambia el usuario o la empresa', () async {
      final database = PackingPedidoDatabase.withDatabase(db);
      await database.ensureOwner('empresa|1');
      await sync([
        pedidoJson(productos: [moveJson()]),
      ]);

      await database.ensureOwner('empresa|1');
      expect(await local.getPedidos(), hasLength(1));

      await database.ensureOwner('empresa|2');
      expect(await local.getPedidos(), isEmpty);
    });
  });

  group('dividir y deshacer', () {
    setUp(
      () => sync([
        pedidoJson(productos: [moveJson()]),
      ]),
    );

    test(
      'dividir deja la parte en listos y el resto como fila nueva',
      () async {
        await local.dividir(
          (await detalle()).porHacer.single,
          4,
          DateTime.now(),
        );

        final d = await detalle();
        expect(d.listos.single.quantity, 4);
        expect(d.listos.single.cantidadAEnviar, 4);
        expect(d.listos.single.isProductSplit, isTrue);
        expect(d.porHacer.single.quantity, 6);
        expect(d.porHacer.single.productOk, isFalse);
        expect(total(d.todos), 10);
      },
    );

    test('dividir la cantidad completa falla sin tocar nada', () async {
      final linea = (await detalle()).porHacer.single;
      await expectLater(
        local.dividir(linea, 10, DateTime.now()),
        throwsA(isA<CacheException>()),
      );
      expect((await detalle()).porHacer.single.quantity, 10);
    });

    test('deshacer suma la cantidad a la fila restante', () async {
      await local.dividir((await detalle()).porHacer.single, 4, DateTime.now());
      await local.deshacerSeparacion((await detalle()).listos.single);

      final d = await detalle();
      expect(d.listos, isEmpty);
      expect(d.porHacer.single.quantity, 10);
    });

    test(
      'deshacer con la restante ya empezada funciona (bug legacy)',
      () async {
        await local.dividir(
          (await detalle()).porHacer.single,
          4,
          DateTime.now(),
        );
        final resto = (await detalle()).porHacer.single;
        await local.actualizarProducto(resto.id, {
          'location_ok': 1,
          'product_ok': 1,
          'quantity_separate': 2,
        });

        await local.deshacerSeparacion((await detalle()).listos.single);

        final d = await detalle();
        expect(d.porHacer.single.quantity, 10);
        expect(d.porHacer.single.quantitySeparate, 2);
      },
    );

    test(
      'deshacer cuando la restante ya se separó no duplica (bug legacy)',
      () async {
        await local.dividir(
          (await detalle()).porHacer.single,
          4,
          DateTime.now(),
        );
        // La restante (6) se separa completa.
        final resto = (await detalle()).porHacer.single;
        await local.actualizarProducto(resto.id, {
          'estado': EstadoProductoPacking.listo.name,
          'certificado': 1,
          'quantity_separate': 6,
        });

        final parteDe4 = (await detalle()).listos.firstWhere(
          (p) => p.quantity == 4,
        );
        await local.deshacerSeparacion(parteDe4);

        final d = await detalle();
        expect(d.porHacer.single.quantity, 4);
        expect(d.listos.single.quantity, 6);
        expect(total(d.todos), 10);
      },
    );

    test(
      'dividir varias veces y deshacer en otro orden suma siempre 10',
      () async {
        await local.dividir(
          (await detalle()).porHacer.single,
          4,
          DateTime.now(),
        );
        await local.dividir(
          (await detalle()).porHacer.single,
          3,
          DateTime.now(),
        );

        var d = await detalle();
        expect(d.listos.map((p) => p.quantity), unorderedEquals([4, 3]));
        expect(d.porHacer.single.quantity, 3);

        await local.deshacerSeparacion(
          d.listos.firstWhere((p) => p.quantity == 4),
        );
        d = await detalle();
        expect(d.porHacer.single.quantity, 7);
        expect(total(d.todos), 10);

        await local.deshacerSeparacion(d.listos.single);
        d = await detalle();
        expect(d.porHacer.single.quantity, 10);
        expect(d.listos, isEmpty);
      },
    );
  });

  group('paquetes', () {
    Map<String, dynamic> caja(
      int id,
      String consecutivo,
      List<Map<String, dynamic>> prods,
    ) => {
      'id': id,
      'name': 'PACK-$id',
      'packing_barcode': 'PK$id',
      'consecutivo': consecutivo,
      'location_dest_id': 55,
      'location_dest_name': 'MUELLE-1',
      'lista_productos_in_packing': prods,
    };

    test(
      'guardar paquete creado reemplaza las filas enviadas por las de Odoo',
      () async {
        await sync([
          pedidoJson(productos: [moveJson()]),
        ]);
        await local.dividir(
          (await detalle()).porHacer.single,
          4,
          DateTime.now(),
        );
        final listo = (await detalle()).listos.single;

        final pedido = (await detalle()).pedido;
        final paquete = PedidoPackApi.paqueteFromApi(
          caja(900, 'Caja1', []),
          pedidoId: 10,
        );
        await local.guardarPaqueteCreado(
          enviados: [listo],
          creado: PaqueteCreadoApi(
            paquete: paquete,
            filasEmpacadas: [
              PedidoPackApi.productoFromApi(
                moveJson(idMove: 999, quantity: 4),
                pedidoId: pedido.id,
                paquete: paquete,
              ),
            ],
          ),
          certificado: true,
        );

        final d = await detalle();
        expect(d.listos, isEmpty);
        expect(d.porHacer.single.quantity, 6);
        expect(d.paquetes.single.productos.single.idMove, 999);
        expect(d.paquetes.single.productos.single.quantity, 4);
        expect(d.pedido.numeroPaquetes, 1);
      },
    );

    test(
      'desempacar devuelve la cantidad que dice Odoo a la fila pendiente',
      () async {
        await sync([
          pedidoJson(
            productos: [moveJson(quantity: 6)],
            paquetes: [
              caja(900, 'Caja1', [
                moveJson(idMove: 999, quantity: 4),
                moveJson(idMove: 998, idProduct: 501, quantity: 2),
              ]),
            ],
          ),
        ]);
        var d = await detalle();
        final paquete = d.paquetes.single;
        final empacada = paquete.productos.firstWhere(
          (p) => p.idProduct == 500,
        );

        final eliminado = await local.aplicarDesempaque(
          paquete: paquete,
          empacada: empacada,
          respuesta: MovesDevueltosApi(
            mensaje: 'ok',
            moves: [moveJson(idMove: 100, quantity: 10)],
          ),
        );

        d = await detalle();
        expect(eliminado, isFalse);
        expect(d.porHacer.single.quantity, 10);
        expect(d.porHacer.single.idMove, 100);
        expect(d.paquetes.single.productos, hasLength(1));
      },
    );

    test('desempacar descuenta lo que el operario tiene en listos', () async {
      await sync([
        pedidoJson(
          productos: [moveJson(quantity: 6)],
          paquetes: [
            caja(900, 'Caja1', [moveJson(idMove: 999, quantity: 4)]),
          ],
        ),
      ]);
      await local.dividir((await detalle()).porHacer.single, 2, DateTime.now());
      final d0 = await detalle();

      final eliminado = await local.aplicarDesempaque(
        paquete: d0.paquetes.single,
        empacada: d0.paquetes.single.productos.single,
        respuesta: MovesDevueltosApi(
          mensaje: 'ok',
          moves: [moveJson(idMove: 100, quantity: 10)],
        ),
      );

      final d = await detalle();
      expect(eliminado, isTrue);
      expect(d.paquetes, isEmpty);
      expect(d.listos.single.quantity, 2);
      expect(d.porHacer.single.quantity, 8);
    });

    test(
      'eliminar caja corre consecutivos sin perder barcode ni ubicación (bug legacy)',
      () async {
        await sync([
          pedidoJson(
            productos: [],
            paquetes: [
              caja(901, 'Caja1', [moveJson(idMove: 1, quantity: 1)]),
              caja(902, 'Caja2', [
                moveJson(idMove: 2, idProduct: 502, quantity: 2),
              ]),
              caja(903, 'Caja3', [
                moveJson(idMove: 3, idProduct: 503, quantity: 3),
              ]),
            ],
          ),
        ]);
        final caja2 = (await detalle()).paquetes.firstWhere((p) => p.id == 902);

        await local.aplicarEliminarPaquete(
          paquete: caja2,
          respuesta: MovesDevueltosApi(
            mensaje: 'ok',
            moves: [moveJson(idMove: 20, idProduct: 502, quantity: 2)],
            paqueteEliminado: true,
          ),
        );

        final d = await detalle();
        expect(d.paquetes.map((p) => p.id), [901, 903]);
        final caja3 = d.paquetes.firstWhere((p) => p.id == 903);
        expect(caja3.consecutivo, 'Caja2');
        expect(caja3.packingBarcode, 'PK903');
        expect(caja3.locationDestName, 'MUELLE-1');
        expect(d.porHacer.single.idProduct, 502);
        expect(d.porHacer.single.quantity, 2);
      },
    );

    test('asignar ubicación actualiza las cajas', () async {
      await sync([
        pedidoJson(paquetes: [caja(901, 'Caja1', [])]),
      ]);
      await local.asignarUbicacion([
        901,
      ], const UbicacionMuelle(id: 77, name: 'MUELLE-7', barcode: 'M7'));
      final p = (await detalle()).paquetes.single;
      expect(p.locationDestId, 77);
      expect(p.locationDestBarcode, 'M7');
    });
  });
}
