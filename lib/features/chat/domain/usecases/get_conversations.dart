import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/chat/domain/entities/chat_conversation.dart';
import 'package:wms_app/features/chat/domain/repositories/chat_repository.dart';

/// Lista las conversaciones del usuario.
@lazySingleton
class GetConversations implements UseCase<List<ChatConversation>, NoParams> {
  final ChatRepository repository;

  GetConversations(this.repository);

  @override
  Future<Either<Failure, List<ChatConversation>>> call(NoParams params) =>
      repository.getConversations();
}
