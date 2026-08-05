/// Estado de entrega de un mensaje (mock por ahora, listo para backend).
enum ChatMessageStatus { sending, sent, delivered, seen, failed }

/// Tipo de contenido del mensaje.
enum ChatMessageType { text, image, audio }

/// Un mensaje dentro de una conversación.
///
/// Entidad inmutable del dominio, independiente del paquete de UI. Soporta
/// texto, imagen y audio; [mediaSource] es la ruta local (mock) o URL del
/// adjunto para imagen/audio.
class ChatMessage {
  final String id;
  final String conversationId;

  /// Id del autor; coincide con [ChatContact.id] o con el usuario actual.
  final String authorId;
  final ChatMessageType type;

  /// Texto del mensaje o pie de foto (vacío en audio).
  final String text;

  /// Ruta local o URL del adjunto (imagen/audio). `null` en texto.
  final String? mediaSource;

  /// Duración del audio (solo [ChatMessageType.audio]).
  final Duration? audioDuration;
  final DateTime createdAt;
  final ChatMessageStatus status;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.authorId,
    required this.text,
    required this.createdAt,
    this.type = ChatMessageType.text,
    this.mediaSource,
    this.audioDuration,
    this.status = ChatMessageStatus.sent,
  });

  /// Texto de vista previa para el listado de conversaciones.
  String get preview => switch (type) {
        ChatMessageType.image => '📷 Foto',
        ChatMessageType.audio => '🎤 Nota de voz',
        ChatMessageType.text => text,
      };

  ChatMessage copyWith({ChatMessageStatus? status, String? text}) => ChatMessage(
        id: id,
        conversationId: conversationId,
        authorId: authorId,
        type: type,
        text: text ?? this.text,
        mediaSource: mediaSource,
        audioDuration: audioDuration,
        createdAt: createdAt,
        status: status ?? this.status,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ChatMessage && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
