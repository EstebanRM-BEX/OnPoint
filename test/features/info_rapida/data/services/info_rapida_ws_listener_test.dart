import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wms_app/core/services/interfaces/i_websocket_service.dart';
import 'package:wms_app/core/services/productos_cache_service.dart';
import 'package:wms_app/features/info_rapida/data/services/info_rapida_ws_listener.dart';

class _MockWebSocket extends Mock implements IWebSocketService {}

class _MockProductosCache extends Mock implements ProductosCacheService {}

String _mensaje(String type, String action, Map<String, dynamic> data) =>
    jsonEncode([
      {
        'message': {
          'type': type,
          'payload': {'action': action, 'data': data},
        },
      },
    ]);

void main() {
  group('parseProductUpdates', () {
    test('extrae solo notification/update', () {
      final raw = jsonEncode([
        {
          'message': {
            'type': 'notification',
            'payload': {
              'action': 'update',
              'data': {'product_id': 1},
            },
          },
        },
        {
          'message': {
            'type': 'notification',
            'payload': {
              'action': 'delete',
              'data': {'product_id': 2},
            },
          },
        },
        {
          'message': {
            'type': 'chat',
            'payload': {
              'action': 'update',
              'data': {'product_id': 3},
            },
          },
        },
      ]);

      final updates = InfoRapidaWsListener.parseProductUpdates(raw);

      expect(updates.map((u) => u['product_id']), [1]);
    });

    test('ignora mensajes que no son JSON o no son lista', () {
      expect(InfoRapidaWsListener.parseProductUpdates('no-json'), isEmpty);
      expect(InfoRapidaWsListener.parseProductUpdates('{"a":1}'), isEmpty);
    });
  });

  group('InfoRapidaWsListener', () {
    late StreamController<dynamic> socket;
    late _MockWebSocket webSocket;
    late _MockProductosCache cache;
    late InfoRapidaWsListener listener;

    setUp(() {
      socket = StreamController<dynamic>.broadcast();
      webSocket = _MockWebSocket();
      cache = _MockProductosCache();
      when(() => webSocket.messages).thenAnswer((_) => socket.stream);
      when(() => cache.applyWsProductUpsert(any(), any())).thenReturn(true);
      listener = InfoRapidaWsListener(webSocket, cache);
    });

    tearDown(() => socket.close());

    test('aplica el upsert y avisa el id mientras está activo', () async {
      final ids = <int>[];
      final sub = listener.productosActualizados.listen(ids.add);
      listener.start();

      socket.add(_mensaje('notification', 'update', {'product_id': 7}));
      await Future<void>.delayed(Duration.zero);

      verify(() => cache.applyWsProductUpsert(7, any())).called(1);
      expect(ids, [7]);
      await sub.cancel();
    });

    test('no avisa si el cache no tenía el producto', () async {
      when(() => cache.applyWsProductUpsert(any(), any())).thenReturn(false);
      final ids = <int>[];
      final sub = listener.productosActualizados.listen(ids.add);
      listener.start();

      socket.add(_mensaje('notification', 'update', {'product_id': 7}));
      await Future<void>.delayed(Duration.zero);

      expect(ids, isEmpty);
      await sub.cancel();
    });

    test('deja de escuchar al detenerse', () async {
      listener.start();
      listener.stop();

      socket.add(_mensaje('notification', 'update', {'product_id': 7}));
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => cache.applyWsProductUpsert(any(), any()));
    });

    test('sigue escuchando mientras quede alguien que lo arrancó', () async {
      listener.start();
      listener.start();
      listener.stop();

      socket.add(_mensaje('notification', 'update', {'product_id': 7}));
      await Future<void>.delayed(Duration.zero);

      verify(() => cache.applyWsProductUpsert(7, any())).called(1);
    });
  });
}
