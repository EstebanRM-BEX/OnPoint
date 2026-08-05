import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/chat/domain/entities/chat_message.dart';
import 'package:wms_app/features/chat/domain/repositories/chat_repository.dart';

/// Parámetros para enviar un mensaje (texto/imagen/audio).
class SendMessageParams {
  final String conversationId;
  final String authorId;
  final String text;
  final ChatMessageType type;
  final String? mediaSource;
  final Duration? audioDuration;

  const SendMessageParams({
    required this.conversationId,
    required this.authorId,
    this.text = '',
    this.type = ChatMessageType.text,
    this.mediaSource,
    this.audioDuration,
  });
}

/// Envía un mensaje a una conversación.
@lazySingleton
class SendMessage implements UseCase<ChatMessage, SendMessageParams> {
  final ChatRepository repository;

  SendMessage(this.repository);

  @override
  Future<Either<Failure, ChatMessage>> call(SendMessageParams params) =>
      repository.sendMessage(
        conversationId: params.conversationId,
        authorId: params.authorId,
        text: params.text,
        type: params.type,
        mediaSource: params.mediaSource,
        audioDuration: params.audioDuration,
      );
}
