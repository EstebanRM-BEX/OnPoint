import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/services/interfaces/i_websocket_service.dart';

part 'websocket_event.dart';
part 'websocket_state.dart';

/// Gestiona el estado de la conexión WebSocket y los mensajes en tiempo real.
@injectable
class WebSocketBloc extends Bloc<WebSocketEvent, WebSocketState> {
  final IWebSocketService webSocketService;
  late StreamSubscription _messageSubscription;
  late StreamSubscription _statusSubscription;

  WebSocketBloc({required this.webSocketService}) : super(WebSocketInitial()) {
    _messageSubscription =
        webSocketService.messages.listen(_onWebSocketMessage);
    _statusSubscription =
        webSocketService.connectionStatus.listen(_onStatusChanged);

    on<WebSocketMessageReceived>(_handleIncomingWebSocketData);
    on<WebSocketStatusChanged>(_handleStatusChanged);
  }

  void _onWebSocketMessage(dynamic data) {
    add(WebSocketMessageReceived(data));
  }

  void _onStatusChanged(WebSocketConnectionStatus status) {
    add(WebSocketStatusChanged(status));
  }

  void _handleIncomingWebSocketData(
    WebSocketMessageReceived event,
    Emitter<WebSocketState> emit,
  ) {
    debugPrint(
        'WebSocketBloc: Mensaje recibido en tiempo real: ${event.payload}');
    emit(WebSocketDataReceived(event.payload));

    // TODO: Add specific logic based on message type
    // if (event.payload is Map && event.payload['type'] == 'NEW_ORDER') {
    //   emit(NewOrderReceived(event.payload));
    // }
  }

  void _handleStatusChanged(
    WebSocketStatusChanged event,
    Emitter<WebSocketState> emit,
  ) {
    switch (event.status) {
      case WebSocketConnectionStatus.connected:
        debugPrint('✅ WebSocketBloc: Conectado');
        emit(WebSocketConnected());
      case WebSocketConnectionStatus.reconnecting:
        final attempt =
            state is WebSocketReconnecting
                ? (state as WebSocketReconnecting).attempt + 1
                : 1;
        // debugPrint('🔄 WebSocketBloc: Reconectando (intento $attempt)');
        emit(WebSocketReconnecting(attempt: attempt));
      case WebSocketConnectionStatus.disconnected:
        // debugPrint('🔌 WebSocketBloc: Desconectado');
        emit(WebSocketDisconnected());
      case WebSocketConnectionStatus.error:
        debugPrint('❌ WebSocketBloc: Error al procesar mensaje');
        emit(WebSocketError('Error al procesar mensaje del servidor'));
    }
  }

  @override
  Future<void> close() {
    _messageSubscription.cancel();
    _statusSubscription.cancel();
    return super.close();
  }
}
