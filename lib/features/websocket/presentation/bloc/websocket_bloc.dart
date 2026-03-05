import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/services/interfaces/i_websocket_service.dart';

part 'websocket_event.dart';
part 'websocket_state.dart';

/// WebSocket BLoC separated from HomeBloc for better separation of concerns.
///
/// Manages WebSocket connections and real-time message handling.
@injectable
class WebSocketBloc extends Bloc<WebSocketEvent, WebSocketState> {
  final IWebSocketService webSocketService;
  late StreamSubscription _webSocketSubscription;

  WebSocketBloc({required this.webSocketService}) : super(WebSocketInitial()) {
    // Subscribe to WebSocket messages
    _webSocketSubscription =
        webSocketService.messages.listen(_onWebSocketMessage);

    on<WebSocketMessageReceived>(_handleIncomingWebSocketData);
  }

  void _onWebSocketMessage(dynamic data) {
    add(WebSocketMessageReceived(data));
  }

  void _handleIncomingWebSocketData(
    WebSocketMessageReceived event,
    Emitter<WebSocketState> emit,
  ) {
    debugPrint(
        'WebSocketBloc: Mensaje recibido en tiempo real: ${event.payload}');

    // Emit state with received data
    emit(WebSocketDataReceived(event.payload));

    // TODO: Add specific logic based on message type
    // Example:
    // if (event.payload is Map && event.payload['type'] == 'NEW_ORDER') {
    //   emit(NewOrderReceived(event.payload));
    // }
  }

  @override
  Future<void> close() {
    // Cancel subscription to prevent memory leaks
    _webSocketSubscription.cancel();
    return super.close();
  }
}
