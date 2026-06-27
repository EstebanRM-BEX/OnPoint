part of 'websocket_bloc.dart';

abstract class WebSocketEvent {}

class WebSocketMessageReceived extends WebSocketEvent {
  final dynamic payload;
  WebSocketMessageReceived(this.payload);
}

class WebSocketStatusChanged extends WebSocketEvent {
  final WebSocketConnectionStatus status;
  WebSocketStatusChanged(this.status);
}
