import 'package:fpdart/fpdart.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/chat/domain/entities/chat_contact.dart';
import 'package:wms_app/features/chat/domain/entities/chat_conversation.dart';
import 'package:wms_app/features/chat/domain/entities/chat_message.dart';

/// Contrato del feature de chat. La implementación (data layer) hoy usa un
/// datasource local con datos mock; mañana puede apuntar a un backend/websocket
/// sin tocar dominio ni presentación.
abstract class ChatRepository {
  /// Usuario actualmente logueado (el "yo" de las conversaciones).
  Future<Either<Failure, ChatContact>> getCurrentUser();

  /// Listado de conversaciones ordenadas por actividad reciente.
  Future<Either<Failure, List<ChatConversation>>> getConversations();

  /// Contactos disponibles para iniciar una conversación.
  Future<Either<Failure, List<ChatContact>>> getContacts();

  /// Mensajes de una conversación (más antiguos primero).
  Future<Either<Failure, List<ChatMessage>>> getMessages(String conversationId);

  /// Envía un mensaje (texto/imagen/audio) y devuelve el mensaje persistido.
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String conversationId,
    required String authorId,
    String text = '',
    ChatMessageType type = ChatMessageType.text,
    String? mediaSource,
    Duration? audioDuration,
  });

  /// Garantiza que exista una conversación con [contact] y la devuelve
  /// (crea una nueva si aún no había ninguna).
  Future<Either<Failure, ChatConversation>> ensureConversationWith(
    ChatContact contact,
  );
}
