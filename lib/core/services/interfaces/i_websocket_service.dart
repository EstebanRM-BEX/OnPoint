abstract class IWebSocketService {
  Stream<dynamic> get messages;
  Future<void> connect();
  void sendMessage(dynamic data);
  void disconnect();
  void dispose();
}
