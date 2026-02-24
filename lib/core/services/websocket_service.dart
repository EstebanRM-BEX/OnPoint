import 'dart:async';
import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:wms_app/core/services/interfaces/i_websocket_service.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';

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
        print("⛔ WebSocket: Faltan datos (URL o Cookie).");
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
        print("⛔ WebSocket: No se pudo extraer session_id de la cookie.");
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

      print("🔄 WebSocket: Intentando conectar a $socketUrl");
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      print("📋 HEADERS DE CONEXIÓN:");
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      // 5. Preparar HEADERS (Crucial para que el servidor acepte la conexión)
      final Map<String, dynamic> headers = {
        'Cookie': sessionId, // Solo session_id=valor
        'Origin':
            cleanBaseUrl, // El servidor verifica de dónde viene la petición
      };

      // Mostrar headers para verificación
      print("🍪 Cookie: $sessionId");
      print("🌐 Origin: $cleanBaseUrl");
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

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
          print("⚠️ WebSocket: Desconectado por el servidor (onDone).");
        },
        onError: (error) {
          _resetConnectionState();
          print("❌ WebSocket Error: $error");
        },
      );

      print("✅ WebSocket: Conexión física establecida.");

      // 7. Intentar suscripción automática
      _subscribeToChannel();
    } catch (e) {
      _resetConnectionState();
      print("❌ WebSocket Excepción Crítica: $e");
    }
  }

  /// Envía el JSON para suscribirse al canal específico
  void _subscribeToChannel() {
    // 🛡️ VALIDACIÓN: Si ya estamos suscritos, evitamos enviar basura al servidor
    if (_isSubscribed) {
      print("✋ WebSocket: Ya estás suscrito, omitiendo solicitud.");
      return;
    }

    final subscriptionPayload = {
      "event_name": "subscribe",
      "data": {
        "channels": ["pda_product_catalog"],
        "last": 0
      }
    };

    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    print("📤 ENVIANDO SUSCRIPCIÓN AL SERVIDOR:");
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    print("📦 Payload: ${jsonEncode(subscriptionPayload)}");
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    sendMessage(jsonEncode(subscriptionPayload));
  }

  /// Procesa cada mensaje que llega del servidor
  void _handleMessage(dynamic data) {
    // print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    // print("📥 MENSAJE RECIBIDO DEL SERVIDOR:");
    // print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    // print("⏰ Timestamp: ${DateTime.now().toIso8601String()}");

    try {
      // Intentamos decodificar para ver si es la confirmación de suscripción
      final Map<String, dynamic> decodedData = jsonDecode(data);

      // Mostrar el mensaje formateado
      print("📦 Contenido JSON:");
      print(const JsonEncoder.withIndent('  ').convert(decodedData));

      // --- VALIDACIÓN DE SUSCRIPCIÓN ---
      // Aquí buscamos el evento que confirma que el servidor aceptó la suscripción.
      if (decodedData['event_name'] == 'subscription_succeeded' ||
          decodedData['event_name'] == 'subscribe_success') {
        _isSubscribed = true;
        // print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        // print("✅ ¡SUSCRIPCIÓN CONFIRMADA POR EL SERVIDOR!");
        // print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
    } catch (e) {
      // Si falla el jsonDecode es porque llegó un dato plano o corrupto
      print("📦 Contenido RAW (no es JSON válido):");
      print(data.toString());
    }

    // print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

    // Pasamos el mensaje a la UI (Bloc/Cubit)
    if (!_messageController.isClosed) {
      _messageController.add(data);
    }
  }

  /// Envía datos al servidor
  @override
  void sendMessage(dynamic data) {
    if (_isConnected && _channel != null) {
      // print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      // print("📤 ENVIANDO MENSAJE AL SERVIDOR:");
      // print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      // print("⏰ Timestamp: ${DateTime.now().toIso8601String()}");

      // Intentar mostrar como JSON formateado si es posible
      try {
        final decoded = jsonDecode(data);
        // print("📦 Contenido JSON:");
        // print(const JsonEncoder.withIndent('  ').convert(decoded));
      } catch (e) {
        // print("📦 Contenido RAW:");
        print(data.toString());
      }

      // print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      _channel!.sink.add(data);
    } else {
      print("⚠️ WebSocket: No se pudo enviar mensaje (Desconectado).");
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
    print("🔌 WebSocket: Desconectado manualmente.");
  }

  /// Limpieza total al destruir el servicio
  @override
  void dispose() {
    disconnect();
    _messageController.close();
  }
}
