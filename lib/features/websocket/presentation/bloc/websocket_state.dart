part of 'websocket_bloc.dart';

abstract class WebSocketState {}

class WebSocketInitial extends WebSocketState {}

class WebSocketDataReceived extends WebSocketState {
  final dynamic data;
  WebSocketDataReceived(this.data);
}
