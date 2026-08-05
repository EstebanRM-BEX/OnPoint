import 'package:wms_app/features/chat/data/models/chat_contact_model.dart';
import 'package:wms_app/features/chat/domain/entities/chat_conversation.dart';

/// Model de conversación con (de)serialización.
class ChatConversationModel extends ChatConversation {
  const ChatConversationModel({
    required super.id,
    required ChatContactModel super.contact,
    required super.lastMessage,
    required super.lastMessageAt,
    super.unreadCount,
  });

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) =>
      ChatConversationModel(
        id: json['id'].toString(),
        contact: ChatContactModel.fromJson(
            json['contact'] as Map<String, dynamic>),
        lastMessage: json['last_message']?.toString() ?? '',
        lastMessageAt:
            DateTime.tryParse(json['last_message_at']?.toString() ?? '') ??
                DateTime.now(),
        unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'contact': (contact as ChatContactModel).toJson(),
        'last_message': lastMessage,
        'last_message_at': lastMessageAt.toIso8601String(),
        'unread_count': unreadCount,
      };
}
