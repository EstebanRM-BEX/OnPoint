import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/chat/data/datasources/chat_local_data_source.dart';
import 'package:wms_app/features/chat/data/models/chat_contact_model.dart';
import 'package:wms_app/features/chat/domain/entities/chat_contact.dart';
import 'package:wms_app/features/chat/domain/entities/chat_conversation.dart';
import 'package:wms_app/features/chat/domain/entities/chat_message.dart';
import 'package:wms_app/features/chat/domain/repositories/chat_repository.dart';

/// Implementación del repositorio de chat. Coordina el datasource (hoy local)
/// y traduce excepciones a [Failure] para que la presentación no vea nunca
/// detalles de la capa de datos.
@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  final ChatLocalDataSource localDataSource;

  ChatRepositoryImpl(this.localDataSource);

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado en el chat: $e'));
    }
  }

  @override
  Future<Either<Failure, ChatContact>> getCurrentUser() =>
      _guard(() => localDataSource.getCurrentUser());

  @override
  Future<Either<Failure, List<ChatConversation>>> getConversations() =>
      _guard(() => localDataSource.getConversations());

  @override
  Future<Either<Failure, List<ChatContact>>> getContacts() =>
      _guard(() => localDataSource.getContacts());

  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages(
          String conversationId) =>
      _guard(() => localDataSource.getMessages(conversationId));

  @override
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String conversationId,
    required String authorId,
    String text = '',
    ChatMessageType type = ChatMessageType.text,
    String? mediaSource,
    Duration? audioDuration,
  }) =>
      _guard(() => localDataSource.sendMessage(
            conversationId: conversationId,
            authorId: authorId,
            text: text,
            type: type,
            mediaSource: mediaSource,
            audioDuration: audioDuration,
          ));

  @override
  Future<Either<Failure, ChatConversation>> ensureConversationWith(
          ChatContact contact) =>
      _guard(() => localDataSource.ensureConversationWith(
            ChatContactModel(
              id: contact.id,
              name: contact.name,
              avatarUrl: contact.avatarUrl,
              role: contact.role,
              isOnline: contact.isOnline,
            ),
          ));
}
