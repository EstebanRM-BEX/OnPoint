import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:wms_app/core/services/interfaces/i_websocket_service.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_barcode/barcodes_inventario_repository.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/product_inventario_repository.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/product_inventario_table.dart';
import 'package:wms_app/src/presentation/providers/db/models/response_products_model.dart';

@LazySingleton(as: IWebSocketService)
class WebSocketService implements IWebSocketService {
  WebSocketService();

  // --- VARIABLES DE ESTADO ---
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isSubscribed = false; // 🚩 Bandera para controlar la suscripción

  // Stream para exponer los mensajes a la UI
  final StreamController<dynamic> _messageController =
      StreamController.broadcast();

  @override
  Stream<dynamic> get messages => _messageController.stream;

  /// Inicia la conexión al WebSocket
  @override
  Future<void> connect() async {
    // 1. Validaciones previas
    final bool isLoggedIn = await PrefUtils.getIsLoggedIn();
    if (!isLoggedIn) return;

    // Si ya estamos conectados, no hacemos nada
    if (_isConnected) return;

    try {
      // 2. Obtener credenciales y URL base
      final String enterpriseUrl = await PrefUtils.getEnterprise();
      final String rawCookie = await PrefUtils.getCookie();

      if (enterpriseUrl.isEmpty || rawCookie.isEmpty) {
        debugPrint("⛔ WebSocket: Faltan datos (URL o Cookie).");
        return;
      }

      // 3. Extraer solo session_id de la cookie
      // La cookie viene con formato: session_id=valor; Path=/; HttpOnly
      // Solo necesitamos: session_id=valor
      String sessionId = '';
      List<String> cookies = rawCookie.split(',');
      for (var c in cookies) {
        if (c.contains('session_id=')) {
          sessionId = c.split(';')[0].trim();
          break;
        }
      }

      if (sessionId.isEmpty) {
        debugPrint("⛔ WebSocket: No se pudo extraer session_id de la cookie.");
        return;
      }

      // 4. Transformación de URL (https -> wss y agregar /websocket)
      // Quitamos la barra final '/' si existe para evitar doble slash
      String cleanBaseUrl = enterpriseUrl.endsWith('/')
          ? enterpriseUrl.substring(0, enterpriseUrl.length - 1)
          : enterpriseUrl;

      // Reemplazamos protocolo y agregamos endpoint
      String socketUrl = cleanBaseUrl.replaceFirst('https://', 'wss://');
      socketUrl += '/websocket';

      debugPrint("🔄 WebSocket: Intentando conectar a $socketUrl");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("📋 HEADERS DE CONEXIÓN:");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      // 5. Preparar HEADERS (Crucial para que el servidor acepte la conexión)
      final Map<String, dynamic> headers = {
        'Cookie': sessionId, // Solo session_id=valor
        'Origin':
            cleanBaseUrl, // El servidor verifica de dónde viene la petición
      };

      // 5. Conectar usando IOWebSocketChannel
      _channel = IOWebSocketChannel.connect(
        Uri.parse(socketUrl),
        headers: headers,
        pingInterval:
            const Duration(seconds: 10), // Ping para mantener viva la conexión
      );

      _isConnected = true;

      // 6. Escuchar eventos
      _channel!.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onDone: () {
          _resetConnectionState();
          print('🔴 ══════════════ WEBSOCKET CERRADO ══════════════');
          print('⚠️  El servidor cerró la conexión (onDone)');
          print('═════════════════════════════════════════════════');
        },
        onError: (error) {
          _resetConnectionState();
          print('🔴 ══════════════ WEBSOCKET ERROR ════════════════');
          print('❌ Error: $error');
          print('═════════════════════════════════════════════════');
        },
      );

      print('🟢 ══════════════ WEBSOCKET CONECTADO ══════════════');
      print('🔗 URL: $socketUrl');
      print('🍪 Session: $sessionId');
      print('════════════════════════════════════════════════════');
      debugPrint("✅ WebSocket: Conexión física establecida.");

      // 7. Intentar suscripción automática
      _subscribeToChannel();
    } catch (e) {
      _resetConnectionState();
      debugPrint("❌ WebSocket Excepción Crítica: $e");
    }
  }

  /// Envía el JSON para suscribirse al canal específico
  void _subscribeToChannel() {
    // 🛡️ VALIDACIÓN: Si ya estamos suscritos, evitamos enviar basura al servidor
    if (_isSubscribed) {
      debugPrint("✋ WebSocket: Ya estás suscrito, omitiendo solicitud.");
      return;
    }

    final subscriptionPayload = {
      "event_name": "subscribe",
      "data": {
        "channels": ["pda_product_catalog"],
        "last": 0
      }
    };

    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    debugPrint("📤 ENVIANDO SUSCRIPCIÓN AL SERVIDOR:");
    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    debugPrint("📦 Payload: ${jsonEncode(subscriptionPayload)}");
    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    sendMessage(jsonEncode(subscriptionPayload));
  }

  /// Procesa cada mensaje que llega del servidor
  void _handleMessage(dynamic data) {
    print('');
    print('🟢 ══════════════ WEBSOCKET MESSAGE ══════════════');
    print('📥 RAW: $data');
    print('════════════════════════════════════════════════════');
    print('');

    try {
      final dynamic decoded = jsonDecode(data);

      if (decoded is List) {
        // Mensajes de notificación del servidor (ej. actualizaciones de producto)
        for (final item in decoded) {
          if (item is! Map<String, dynamic>) continue;
          final msg = item['message'];
          if (msg is! Map<String, dynamic>) continue;
          if (msg['type'] != 'notification') continue;
          final payload = msg['payload'];
          if (payload is! Map<String, dynamic>) continue;
          if (payload['action'] == 'update') {
            final wsData = payload['data'];
            if (wsData is Map<String, dynamic>) {
              _handleProductUpdate(wsData);
            }
          }
        }
      } else if (decoded is Map<String, dynamic>) {
        debugPrint("📦 Contenido JSON:");
        debugPrint(const JsonEncoder.withIndent('  ').convert(decoded));

        if (decoded['event_name'] == 'subscription_succeeded' ||
            decoded['event_name'] == 'subscribe_success') {
          _isSubscribed = true;
        }
      }
    } catch (e) {
      debugPrint("📦 Contenido RAW (no es JSON válido): ${data.toString()}");
    }

    if (!_messageController.isClosed) {
      _messageController.add(data);
    }
  }

  /// Compara el producto recibido por WS con SQLite y actualiza los campos que cambiaron
  Future<void> _handleProductUpdate(Map<String, dynamic> wsData) async {
    final int? productId = wsData['product_id'] as int?;
    if (productId == null) return;

    final productRepo = ProductInventarioRepository();
    final Product? current = await productRepo.getProductById(productId);

    if (current == null) {
      debugPrint(
          "⚠️ WS Update: producto_id=$productId no existe en BD local, ignorando.");
      return;
    }

    final String label = '"${current.name}" (id: $productId)';
    final Map<String, dynamic> updatedFields = {};

    // Compara un campo simple (como string) y registra si cambió
    void check(
        String fieldName, String column, dynamic storedVal, dynamic wsVal) {
      final String stored = storedVal?.toString() ?? '';
      final String incoming = wsVal?.toString() ?? '';
      if (stored != incoming) {
        updatedFields[column] = wsVal;
        print('🔄 Producto $label — "$fieldName": "$stored" → "$incoming"');
      }
    }

    check('name', ProductInventarioTable.columnProductName, current.name,
        wsData['name']);
    check('code', ProductInventarioTable.columnProductCode, current.code,
        wsData['code']);
    check('barcode', ProductInventarioTable.columnBarcode, current.barcode,
        wsData['barcode']);
    check('tracking', ProductInventarioTable.columnProductracking,
        current.tracking, wsData['tracking']);
    check('uom', ProductInventarioTable.columnUom, current.uom, wsData['uom']);
    check('weight', ProductInventarioTable.columnWeight, current.weight,
        wsData['weight']);
    check('weight_uom_name', ProductInventarioTable.columnWeightUomName,
        current.weightUomName, wsData['weight_uom_name']);
    check('volume', ProductInventarioTable.columnVolume, current.volume,
        wsData['volume']);
    check('volume_uom_name', ProductInventarioTable.columnVolumeUomName,
        current.volumeUomName, wsData['volume_uom_name']);
    check('category', ProductInventarioTable.columnCategory, current.category,
        wsData['category']);
    check('location_id', ProductInventarioTable.columnLocationId,
        current.locationId, wsData['location_id']);
    check('location_name', ProductInventarioTable.columnLocationName,
        current.locationName, wsData['location_name']);
    check('lot_id', ProductInventarioTable.columnLotId, current.lotId,
        wsData['lot_id']);
    check('lot_name', ProductInventarioTable.columnLotName, current.lotName,
        wsData['lot_name']);
    check('quantity', ProductInventarioTable.columnQuantity, current.quantity,
        wsData['quantity']);
    check('expiration_time', ProductInventarioTable.columnExpirationDate,
        current.expirationTime, wsData['expiration_time']);

    // use_expiration_date: SQLite guarda 0/1, WS envía bool — normalizar antes de comparar
    final int storedUseExp =
        (current.useExpirationDate == true || current.useExpirationDate == 1)
            ? 1
            : 0;
    final int wsUseExp = wsData['use_expiration_date'] == true ? 1 : 0;
    if (storedUseExp != wsUseExp) {
      updatedFields[ProductInventarioTable.columnUseExpirationDate] = wsUseExp;
      print(
          '🔄 Producto $label — "use_expiration_date": "$storedUseExp" → "$wsUseExp"');
    }

    if (updatedFields.isNotEmpty) {
      await productRepo.updateProductFields(productId, updatedFields);
      print(
          '✅ Producto $label — ${updatedFields.length} campo(s) actualizado(s) en BD.');
    } else {
      print('✅ Producto $label — sin cambios de campos.');
    }

    // ── Barcodes ──────────────────────────────────────────────────────────────
    final barcodesRepo = BarcodesInventarioRepository();
    final List<BarcodeInventario> storedBarcodes =
        await barcodesRepo.getBarcodesProduct(productId);
    final List<dynamic> wsBarcodes =
        wsData['other_barcodes'] as List<dynamic>? ?? [];

    // Índice de barcodes actuales: barcode → cantidad
    final Map<String, dynamic> storedMap = {
      for (final b in storedBarcodes) b.barcode.toString(): b.cantidad,
    };

    final List<BarcodeInventario> toInsert = [];

    for (final wb in wsBarcodes) {
      if (wb is! Map<String, dynamic>) continue;
      final String wsBarcode = wb['barcode']?.toString() ?? '';
      if (wsBarcode.isEmpty) continue;
      final dynamic wsCantidad = wb['cantidad'];

      if (!storedMap.containsKey(wsBarcode)) {
        toInsert.add(BarcodeInventario(
            barcode: wsBarcode, idProduct: productId, cantidad: wsCantidad));
        print(
            '🔄 Producto $label — nuevo barcode: "$wsBarcode" (cantidad: $wsCantidad)');
      } else if (storedMap[wsBarcode].toString() != wsCantidad.toString()) {
        await barcodesRepo.updateBarcodeCantidad(productId, wsBarcode, wsCantidad);
        print(
            '🔄 Producto $label — barcode "$wsBarcode" cantidad: "${storedMap[wsBarcode]}" → "$wsCantidad"');
      }
    }

    if (toInsert.isNotEmpty) {
      await barcodesRepo.insertOrUpdateBarcodes(toInsert);
    }
  }

  /// Envía datos al servidor
  @override
  void sendMessage(dynamic data) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(data);
    } else {
      debugPrint("⚠️ WebSocket: No se pudo enviar mensaje (Desconectado).");
    }
  }

  /// Resetea las banderas de estado (Útil para reconexiones)
  void _resetConnectionState() {
    _isConnected = false;
    _isSubscribed =
        false; // Importante: volver a false para permitir re-suscribirse luego
  }

  /// Cierra la conexión manualmente
  @override
  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    _resetConnectionState();
    debugPrint("🔌 WebSocket: Desconectado manualmente.");
  }

  /// Limpieza total al destruir el servicio
  @override
  void dispose() {
    disconnect();
    _messageController.close();
  }
}
