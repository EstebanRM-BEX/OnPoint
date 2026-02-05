import 'dart:async';
import 'dart:convert'; // Para jsonEncode y jsonDecode
import 'dart:io'; // Para SocketException

import 'package:web_socket_channel/io.dart'; // Para IOWebSocketChannel (Soporte de Headers)
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:wms_app/src/core/utils/prefs/pref_utils.dart';

class WebSocketService {
  // --- PATRÓN SINGLETON ---
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  // --- VARIABLES DE ESTADO ---
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isSubscribed = false; // 🚩 Bandera para controlar la suscripción

  // Stream para exponer los mensajes a la UI
  final StreamController<dynamic> _messageController = StreamController.broadcast();
  Stream<dynamic> get messages => _messageController.stream;

  /// Inicia la conexión al WebSocket
  Future<void> connect() async {
    // 1. Validaciones previas
    final bool isLoggedIn = await PrefUtils.getIsLoggedIn();
    if (!isLoggedIn) return;
    
    // Si ya estamos conectados, no hacemos nada
    if (_isConnected) return;

    try {
      // 2. Obtener credenciales y URL base
      final String enterpriseUrl = await PrefUtils.getEnterprise(); // Ej: https://midominio.com/
      final String rawCookie = await PrefUtils.getCookie(); // Ej: session_id=xyz...

      if (enterpriseUrl.isEmpty || rawCookie.isEmpty) {
        print("⛔ WebSocket: Faltan datos (URL o Cookie).");
        return;
      }

      // 3. Transformación de URL (https -> wss y agregar /websocket)
      // Quitamos la barra final '/' si existe para evitar doble slash
      String cleanBaseUrl = enterpriseUrl.endsWith('/') 
          ? enterpriseUrl.substring(0, enterpriseUrl.length - 1) 
          : enterpriseUrl;
      
      // Reemplazamos protocolo y agregamos endpoint
      String socketUrl = cleanBaseUrl.replaceFirst('https://', 'wss://');
      socketUrl += '/websocket';

      print("🔄 WebSocket: Intentando conectar a $socketUrl");

      // 4. Preparar HEADERS (Crucial para que el servidor acepte la conexión)
      final Map<String, dynamic> headers = {
        'Cookie': rawCookie,
        'Origin': cleanBaseUrl, // El servidor verifica de dónde viene la petición
      };

      // 5. Conectar usando IOWebSocketChannel
      _channel = IOWebSocketChannel.connect(
        Uri.parse(socketUrl),
        headers: headers, 
        pingInterval: const Duration(seconds: 10), // Ping para mantener viva la conexión
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
        "channels": ["test_websocket"],
        "last": 0
      }
    };

    print("📤 WebSocket: Enviando solicitud de suscripción...");
    sendMessage(jsonEncode(subscriptionPayload));
  }

  /// Procesa cada mensaje que llega del servidor
  void _handleMessage(dynamic data) {
    try {
      // Intentamos decodificar para ver si es la confirmación de suscripción
      final Map<String, dynamic> decodedData = jsonDecode(data);
      
      // LOG TEMPORAL: Descomenta esta línea para ver EXACTAMENTE qué responde tu servidor al conectar
      // print("📥 RAW SERVER DATA: $decodedData"); 

      // --- VALIDACIÓN DE SUSCRIPCIÓN ---
      // Aquí buscamos el evento que confirma que el servidor aceptó la suscripción.
      // Ajusta 'subscription_succeeded' si tu servidor usa otro nombre (ej: 'subscribe_success')
      if (decodedData['event_name'] == 'subscription_succeeded' || 
          decodedData['event_name'] == 'subscribe_success') { // Agregué posibles variaciones
        
        _isSubscribed = true;
        print("✅ WebSocket: ¡Suscripción CONFIRMADA por el servidor!");
      }

    } catch (e) {
      // Si falla el jsonDecode es porque llegó un dato plano o corrupto, lo ignoramos aquí
      // pero igual lo pasamos al stream principal abajo.
    }

    // Pasamos el mensaje a la UI (Bloc/Cubit)
    if (!_messageController.isClosed) {
      _messageController.add(data);
    }
  }

  /// Envía datos al servidor
  void sendMessage(dynamic data) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(data);
    } else {
      print("⚠️ WebSocket: No se pudo enviar mensaje (Desconectado).");
    }
  }

  /// Resetea las banderas de estado (Útil para reconexiones)
  void _resetConnectionState() {
    _isConnected = false;
    _isSubscribed = false; // Importante: volver a false para permitir re-suscribirse luego
  }

  /// Cierra la conexión manualmente
  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    _resetConnectionState();
    print("🔌 WebSocket: Desconectado manualmente.");
  }

  /// Limpieza total al destruir el servicio
  void dispose() {
    disconnect();
    _messageController.close();
  }
}