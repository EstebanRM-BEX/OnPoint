import 'package:wms_app/features/chat/domain/entities/chat_contact.dart';

/// Model de contacto: extiende la entidad y añade (de)serialización para
/// cuando existan endpoints. Hoy los datos vienen del datasource local.
class ChatContactModel extends ChatContact {
  const ChatContactModel({
    required super.id,
    required super.name,
    super.avatarUrl,
    super.role,
    super.isOnline,
  });

  factory ChatContactModel.fromJson(Map<String, dynamic> json) =>
      ChatContactModel(
        id: json['id'].toString(),
        name: json['name']?.toString() ?? '',
        avatarUrl: json['avatar_url']?.toString(),
        role: json['role']?.toString() ?? '',
        isOnline: json['is_online'] == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar_url': avatarUrl,
        'role': role,
        'is_online': isOnline,
      };
}
