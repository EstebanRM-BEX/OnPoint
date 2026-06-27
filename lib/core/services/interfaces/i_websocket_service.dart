enum WebSocketConnectionStatus { connected, disconnected, reconnecting, error }

abstract class IWebSocketService {
  Stream<dynamic> get messages;
  Stream<WebSocketConnectionStatus> get connectionStatus;
  Future<void> connect();
  void sendMessage(dynamic data);
  void disconnect();
  void dispose();
}
