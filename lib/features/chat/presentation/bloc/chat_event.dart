part of 'chat_bloc.dart';

/// Eventos del feature de chat.
sealed class ChatEvent {
  const ChatEvent();
}

/// Carga inicial: usuario actual, conversaciones y contactos.
class ChatStarted extends ChatEvent {
  const ChatStarted();
}

/// Reintenta la carga tras un error.
class ChatRetried extends ChatEvent {
  const ChatRetried();
}

/// Abre el hilo de una conversación existente.
class ChatConversationOpened extends ChatEvent {
  final ChatConversation conversation;
  const ChatConversationOpened(this.conversation);
}

/// Abre (o crea) el hilo con un contacto.
class ChatContactSelected extends ChatEvent {
  final ChatContact contact;
  const ChatContactSelected(this.contact);
}

/// Vuelve del hilo al listado.
class ChatBackToList extends ChatEvent {
  const ChatBackToList();
}

/// Cambia el texto de búsqueda del listado.
class ChatSearchChanged extends ChatEvent {
  final String query;
  const ChatSearchChanged(this.query);
}

/// Envía un mensaje de texto en la conversación activa.
class ChatMessageSent extends ChatEvent {
  final String text;
  const ChatMessageSent(this.text);
}

/// Envía un adjunto (imagen/audio) en la conversación activa.
class ChatMediaSent extends ChatEvent {
  final ChatMessageType type;
  final String source;
  final Duration? audioDuration;
  const ChatMediaSent({
    required this.type,
    required this.source,
    this.audioDuration,
  });
}
