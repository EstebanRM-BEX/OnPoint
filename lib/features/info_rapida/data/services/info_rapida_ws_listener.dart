import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/services/interfaces/i_websocket_service.dart';
import 'package:wms_app/core/services/productos_cache_service.dart';

/// Aplica en memoria las actualizaciones de productos que llegan por
/// WebSocket (`notification/update`) mientras Información Rápida está
/// abierta. Reemplaza la suscripción que tenía `InfoRapidaBloc` en el legacy.
///
/// Lo arranca la pantalla principal del módulo con [start] y lo detiene al
/// salir con [stop]. Mientras convivan los dos módulos, ambos aplican el
/// mismo upsert: es idempotente.
@lazySingleton
class InfoRapidaWsListener {
  final IWebSocketService _webSocket;
  final ProductosCacheService _productosCache;

  InfoRapidaWsListener(this._webSocket, this._productosCache);

  StreamSubscription<dynamic>? _subscription;
  int _usuarios = 0;
  final StreamController<int> _actualizados =
      StreamController<int>.broadcast();

  /// Ids de productos actualizados en el cache (para recargar listas).
  Stream<int> get productosActualizados => _actualizados.stream;

  void start() {
    _usuarios++;
    _subscription ??= _webSocket.messages.listen(_onMessage);
  }

  void stop() {
    if (_usuarios > 0) _usuarios--;
    if (_usuarios > 0) return;
    _subscription?.cancel();
    _subscription = null;
  }

  void _onMessage(dynamic data) {
    for (final update in parseProductUpdates(data)) {
      final productId = update['product_id'];
      if (productId is! int) continue;
      final touched = _productosCache.applyWsProductUpsert(productId, update);
      if (!touched) continue;
      debugPrint('🔄 InfoRapida v2: producto id=$productId actualizado vía WS.');
      _actualizados.add(productId);
    }
  }

  /// Extrae los `payload.data` de los mensajes `notification` con
  /// `action == 'update'`. Ignora cualquier otro formato.
  @visibleForTesting
  static List<Map<String, dynamic>> parseProductUpdates(dynamic raw) {
    final result = <Map<String, dynamic>>[];
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! List) return result;
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        final msg = item['message'];
        if (msg is! Map<String, dynamic>) continue;
        if (msg['type'] != 'notification') continue;
        final payload = msg['payload'];
        if (payload is! Map<String, dynamic>) continue;
        if (payload['action'] != 'update') continue;
        final data = payload['data'];
        if (data is Map<String, dynamic>) result.add(data);
      }
    } catch (_) {}
    return result;
  }
}
