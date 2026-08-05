import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/chat/domain/entities/chat_message.dart';
import 'package:wms_app/features/chat/domain/repositories/chat_repository.dart';

/// Carga los mensajes de una conversación (params = conversationId).
@lazySingleton
class GetMessages implements UseCase<List<ChatMessage>, String> {
  final ChatRepository repository;

  GetMessages(this.repository);

  @override
  Future<Either<Failure, List<ChatMessage>>> call(String conversationId) =>
      repository.getMessages(conversationId);
}
