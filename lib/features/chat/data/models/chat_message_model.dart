import 'package:wms_app/features/chat/domain/entities/chat_message.dart';

/// Model de mensaje con (de)serialización.
class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.conversationId,
    required super.authorId,
    required super.text,
    required super.createdAt,
    super.type,
    super.mediaSource,
    super.audioDuration,
    super.status,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        id: json['id'].toString(),
        conversationId: json['conversation_id'].toString(),
        authorId: json['author_id'].toString(),
        text: json['text']?.toString() ?? '',
        type: ChatMessageType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => ChatMessageType.text,
        ),
        mediaSource: json['media_source']?.toString(),
        audioDuration: json['audio_ms'] == null
            ? null
            : Duration(milliseconds: (json['audio_ms'] as num).toInt()),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
        status: ChatMessageStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => ChatMessageStatus.sent,
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'author_id': authorId,
        'text': text,
        'type': type.name,
        'media_source': mediaSource,
        'audio_ms': audioDuration?.inMilliseconds,
        'created_at': createdAt.toIso8601String(),
        'status': status.name,
      };
}
