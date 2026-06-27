part of 'websocket_bloc.dart';

abstract class WebSocketState {}

class WebSocketInitial extends WebSocketState {}

class WebSocketConnected extends WebSocketState {}

class WebSocketReconnecting extends WebSocketState {
  final int attempt;
  WebSocketReconnecting({required this.attempt});
}

class WebSocketDisconnected extends WebSocketState {}

class WebSocketError extends WebSocketState {
  final String message;
  WebSocketError(this.message);
}

class WebSocketDataReceived extends WebSocketState {
  final dynamic data;
  WebSocketDataReceived(this.data);
}
