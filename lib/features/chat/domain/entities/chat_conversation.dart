import 'package:wms_app/features/chat/domain/entities/chat_contact.dart';

/// Resumen de una conversación 1:1 para el listado.
///
/// No contiene la lista de mensajes (esa se carga bajo demanda al abrir
/// el hilo), lo que mantiene el listado liviano y con buen rendimiento.
class ChatConversation {
  final String id;

  /// El otro participante de la conversación (mock 1:1).
  final ChatContact contact;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  const ChatConversation({
    required this.id,
    required this.contact,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
  });

  ChatConversation copyWith({
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) =>
      ChatConversation(
        id: id,
        contact: contact,
        lastMessage: lastMessage ?? this.lastMessage,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        unreadCount: unreadCount ?? this.unreadCount,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ChatConversation && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
