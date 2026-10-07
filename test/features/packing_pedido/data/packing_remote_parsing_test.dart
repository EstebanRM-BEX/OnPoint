import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/features/packing_pedido/data/datasources/packing_pedido_remote_data_source.dart';
import 'package:wms_app/features/packing_pedido/data/models/odoo_parse.dart';
import 'package:wms_app/features/packing_pedido/data/models/packing_api_models.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/src/api/api_request_service.dart';

http.Response res(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

void main() {
  group('decode / result', () {
    test('sesión expirada (error code 100)', () {
      expect(
        () => PackingPedidoRemoteDataSourceImpl.decode(
          res({
            'error': {'code': 100, 'message': 'Session expired'},
          }, 500),
        ),
        throwsA(isA<SessionExpiredException>()),
      );
    });

    test('error de red sintético de ApiRequestService', () {
      expect(
        () => PackingPedidoRemoteDataSourceImpl.decode(
          ApiRequestService.buildClientErrorResponse(404, 'Error de red'),
        ),
        throwsA(isA<NetworkException>()),
      );
    });

    test('result con code distinto de 200 lleva el msg del servidor', () {
      expect(
        () => PackingPedidoRemoteDataSourceImpl.result({
          'result': {'code': 400, 'msg': 'Paquete no existe'},
        }),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Paquete no existe',
          ),
        ),
      );
    });

    test('dispositivo no autorizado (403)', () {
      expect(
        () => PackingPedidoRemoteDataSourceImpl.result({
          'result': {'code': 403},
        }),
        throwsA(isA<ServerException>()),
      );
    });

    test('cuerpo no JSON', () {
      expect(
        () => PackingPedidoRemoteDataSourceImpl.decode(
          http.Response('<html>', 502),
        ),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('OdooParse', () {
    test('false y relacionales', () {
      expect(OdooParse.str(false), '');
      expect(OdooParse.str([3, 'Caja']), 'Caja');
      expect(OdooParse.integer([3, 'Caja']), 3);
      expect(OdooParse.integer(false), isNull);
      expect(OdooParse.dbl('2.5'), 2.5);
      expect(OdooParse.dbl(false), 0);
      expect(OdooParse.boolean(1), isTrue);
    });
  });

  group('PedidoPackApi.productoFromApi', () {
    test('línea por hacer con lote entero y nombre en lot_id', () {
      final p = PedidoPackApi.productoFromApi({
        'id_move': 1,
        'id_product': 5,
        'product_id': [5, 'Leche'],
        'lote_id': 77,
        'lot_id': [77, 'L-77'],
        'quantity': 3,
        'barcode': false,
      }, pedidoId: 10);
      expect(p.estado, EstadoProductoPacking.porHacer);
      expect(p.loteId, 77);
      expect(p.loteName, 'L-77');
      expect(p.barcode, '');
      expect(p.productName, 'Leche');
    });

    test('sin lote (false o 0) queda null', () {
      expect(PedidoPackApi.productoFromApi({'lote_id': false}).loteId, isNull);
      expect(PedidoPackApi.productoFromApi({'lote_id': 0}).loteId, isNull);
    });
  });

  group('MovesDevueltosApi.moveDe', () {
    final empacada = PedidoPackApi.productoFromApi({
      'id_move': 999,
      'id_product': 5,
      'lote_id': 7,
      'barcode_location': 'A1',
      'quantity': 2,
    });

    test('un solo move: ese es', () {
      final r = MovesDevueltosApi(
        mensaje: '',
        moves: [
          {'id_move': 1, 'id_product': 99},
        ],
      );
      expect(r.moveDe(empacada)?['id_move'], 1);
    });

    test('varios: por producto, lote y ubicación, no por id_move', () {
      final r = MovesDevueltosApi(
        mensaje: '',
        moves: [
          {
            'id_move': 1,
            'id_product': 5,
            'lote_id': 8,
            'barcode_location': 'A1',
          },
          {
            'id_move': 2,
            'id_product': 5,
            'lote_id': 7,
            'barcode_location': 'A1',
          },
          {'id_move': 3, 'id_product': 6},
        ],
      );
      expect(r.moveDe(empacada)?['id_move'], 2);
    });
  });
}
