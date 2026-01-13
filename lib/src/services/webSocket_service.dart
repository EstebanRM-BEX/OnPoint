import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:wms_app/src/core/utils/prefs/pref_utils.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;

  final StreamController<dynamic> _messageController = StreamController.broadcast();
  Stream<dynamic> get messages => _messageController.stream;

  // 1. DEFINICIÓN DE LA RUTA BASE (Sin el protocolo)
  final String _host = 'integracionsocket.360software.com.co';
  final String _path = '/ws/test';

  Future<void> connect() async {
    // 🛡️ VALIDACIÓN 1: Si no hay sesión, NO hacemos nada.
    final bool isLoggedIn = await PrefUtils.getIsLoggedIn();
    if (!isLoggedIn) return;

    // VALIDACIÓN 2: Si ya estamos conectados, no reconectamos.
    if (_isConnected) return;

    try {
      final String rawCookie = await PrefUtils.getCookie();
      if (rawCookie.isEmpty) {
        print("⛔ WebSocket: No hay credenciales (Cookie vacía).");
        return;
      }

      // Limpiamos el token para obtener solo la cadena larga (eyJ...)
      String cleanToken = _extractTokenValue(rawCookie);

      // ---------------------------------------------------------
      // 🛠️ CONSTRUCCIÓN MANUAL DE LA URL (EXACTA)
      // ---------------------------------------------------------
      // Al armar el string manualmente, forzamos el formato 'wss://'
      // y evitamos que Dart agregue puertos raros como :0
      final String fullUrl = 'wss://$_host$_path?token=$cleanToken';

      print("🔄 WebSocket: Conectando a $fullUrl");

      // Conectamos
      _channel = WebSocketChannel.connect(Uri.parse(fullUrl));
      _isConnected = true;

      _channel!.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onDone: () {
          _isConnected = false;
          print("⚠️ WebSocket: Desconectado por el servidor.");
        },
        onError: (error) {
          _isConnected = false;
          print("❌ WebSocket Error: $error");
        },
      );
      
      print("✅ WebSocket: Conexión iniciada.");

    } catch (e) {
      _isConnected = false;
      print("❌ WebSocket Excepción Crítica: $e");
    }
  }

  /// Extrae el token limpio de la cookie
  String _extractTokenValue(String rawCookie) {
    try {
      // 1. Separa por punto y coma (quita Expires, Path, etc.)
      String mainPart = rawCookie.split(';').first;
      
      // 2. Si viene como "variable=valor", toma solo el valor
      if (mainPart.contains('=')) {
        return mainPart.split('=').last;
      }
      
      // 3. Si ya es el token puro, lo devuelve
      print('token limpio: $mainPart');
      return mainPart;
    } catch (e) {
      return rawCookie;
    }
  }

  void _handleMessage(dynamic data) {
    if (!_messageController.isClosed) {
      _messageController.add(data);
    }
  }

  void sendMessage(dynamic data) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(data);
    } else {
      print("⚠️ No se pudo enviar: Socket desconectado.");
    }
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _isConnected = false;
      _channel = null;
      print("🔌 WebSocket: Desconectado manualmente.");
    }
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}