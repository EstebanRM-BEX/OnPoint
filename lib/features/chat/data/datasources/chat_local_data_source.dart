import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/features/chat/data/models/chat_contact_model.dart';
import 'package:wms_app/features/chat/data/models/chat_conversation_model.dart';
import 'package:wms_app/features/chat/data/models/chat_message_model.dart';
import 'package:wms_app/features/chat/domain/entities/chat_message.dart';

/// Fuente de datos del chat. Hoy es 100% local/mock; el resto de la app no
/// sabe que es mock, así que sustituir esto por remoto/websocket no rompe nada.
abstract class ChatLocalDataSource {
  Future<ChatContactModel> getCurrentUser();
  Future<List<ChatConversationModel>> getConversations();
  Future<List<ChatContactModel>> getContacts();
  Future<List<ChatMessageModel>> getMessages(String conversationId);
  Future<ChatMessageModel> sendMessage({
    required String conversationId,
    required String authorId,
    String text,
    ChatMessageType type,
    String? mediaSource,
    Duration? audioDuration,
  });
  Future<ChatConversationModel> ensureConversationWith(ChatContactModel contact);
}

/// Implementación con datos crudos en memoria. El estado (mensajes enviados,
/// conversaciones creadas) se mantiene mientras viva la app (singleton DI).
@LazySingleton(as: ChatLocalDataSource)
class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  /// Latencia simulada para que la UI muestre estados de carga reales.
  static const _latency = Duration(milliseconds: 350);

  // ---------------------------------------------------------------------------
  // Semilla de datos crudos
  // ---------------------------------------------------------------------------

  final ChatContactModel _me = const ChatContactModel(
    id: 'me',
    name: 'Yo',
    role: 'Operario',
    isOnline: true,
  );

  late final List<ChatContactModel> _contacts = [
    const ChatContactModel(
        id: 'u1', name: 'Juan Pérez', role: 'Picking', isOnline: true),
    const ChatContactModel(
        id: 'u2', name: 'Ana Gómez', role: 'Recepción', isOnline: true),
    const ChatContactModel(
        id: 'u3', name: 'Soporte WMS', role: 'Sistemas', isOnline: false),
    const ChatContactModel(
        id: 'u4', name: 'Carlos Ruiz', role: 'Expedición', isOnline: false),
    const ChatContactModel(
        id: 'u5', name: 'María López', role: 'Supervisora', isOnline: true),
    const ChatContactModel(
        id: 'u6', name: 'Pedro Díaz', role: 'Packing', isOnline: false),
  ];

  /// conversationId -> mensajes (más antiguos primero).
  late final Map<String, List<ChatMessageModel>> _messages = {
    'c1': [
      _seed('c1', 'u1', 'Hola, ¿avanzamos con el batch 1042?', -55),
      _seed('c1', 'me', 'Sí, voy por la ubicación A-12.', -54),
      _seed('c1', 'u1', 'Perfecto, me avisas cuando cierres.', -53),
    ],
    'c2': [
      _seed('c2', 'u2', 'Llegó la mercancía del proveedor 7.', -220),
      _seed('c2', 'me', 'Ok, la empiezo a recepcionar.', -218),
    ],
    'c3': [
      _seed('c3', 'u3', 'Recuerda reiniciar la Zebra si se traba.', -1440),
    ],
  };

  /// Conversaciones (se derivan/actualizan con el último mensaje).
  late final List<ChatConversationModel> _conversations = [
    ChatConversationModel(
      id: 'c1',
      contact: _contacts[0],
      lastMessage: _messages['c1']!.last.text,
      lastMessageAt: _messages['c1']!.last.createdAt,
      unreadCount: 2,
    ),
    ChatConversationModel(
      id: 'c2',
      contact: _contacts[1],
      lastMessage: _messages['c2']!.last.text,
      lastMessageAt: _messages['c2']!.last.createdAt,
      unreadCount: 0,
    ),
    ChatConversationModel(
      id: 'c3',
      contact: _contacts[2],
      lastMessage: _messages['c3']!.last.text,
      lastMessageAt: _messages['c3']!.last.createdAt,
      unreadCount: 1,
    ),
  ];

  int _seq = 0;

  ChatMessageModel _seed(
    String conversationId,
    String authorId,
    String text,
    int minutesAgo,
  ) =>
      ChatMessageModel(
        id: 'seed_${conversationId}_${_seq++}',
        conversationId: conversationId,
        authorId: authorId,
        text: text,
        createdAt: DateTime.now().add(Duration(minutes: minutesAgo)),
        status: ChatMessageStatus.seen,
      );

  // ---------------------------------------------------------------------------
  // API
  // ---------------------------------------------------------------------------

  @override
  Future<ChatContactModel> getCurrentUser() async {
    await Future.delayed(_latency);
    return _me;
  }

  @override
  Future<List<ChatConversationModel>> getConversations() async {
    await Future.delayed(_latency);
    final list = [..._conversations]
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return list;
  }

  @override
  Future<List<ChatContactModel>> getContacts() async {
    await Future.delayed(_latency);
    return [..._contacts];
  }

  @override
  Future<List<ChatMessageModel>> getMessages(String conversationId) async {
    await Future.delayed(_latency);
    // Al abrir, marcamos como leída la conversación (mock).
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1 && _conversations[idx].unreadCount != 0) {
      _conversations[idx] = ChatConversationModel(
        id: _conversations[idx].id,
        contact: _conversations[idx].contact as ChatContactModel,
        lastMessage: _conversations[idx].lastMessage,
        lastMessageAt: _conversations[idx].lastMessageAt,
        unreadCount: 0,
      );
    }
    return [...?_messages[conversationId]];
  }

  @override
  Future<ChatMessageModel> sendMessage({
    required String conversationId,
    required String authorId,
    String text = '',
    ChatMessageType type = ChatMessageType.text,
    String? mediaSource,
    Duration? audioDuration,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final msg = ChatMessageModel(
      id: 'm_${DateTime.now().microsecondsSinceEpoch}',
      conversationId: conversationId,
      authorId: authorId,
      text: text,
      type: type,
      mediaSource: mediaSource,
      audioDuration: audioDuration,
      createdAt: DateTime.now(),
      status: ChatMessageStatus.sent,
    );
    (_messages[conversationId] ??= []).add(msg);

    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      _conversations[idx] = ChatConversationModel(
        id: _conversations[idx].id,
        contact: _conversations[idx].contact as ChatContactModel,
        lastMessage: msg.preview,
        lastMessageAt: msg.createdAt,
        unreadCount: 0,
      );
    }
    return msg;
  }

  @override
  Future<ChatConversationModel> ensureConversationWith(
    ChatContactModel contact,
  ) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final existing = _conversations.where((c) => c.contact.id == contact.id);
    if (existing.isNotEmpty) return existing.first;

    final convo = ChatConversationModel(
      id: 'c_${contact.id}',
      contact: contact,
      lastMessage: '',
      lastMessageAt: DateTime.now(),
      unreadCount: 0,
    );
    _conversations.add(convo);
    _messages[convo.id] = [];
    return convo;
  }
}

/// Excepción específica del feature (mapeada a Failure en el repo).
class ChatException extends CacheException {
  ChatException(super.message);
}
