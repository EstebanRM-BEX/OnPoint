import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/chat/domain/entities/chat_contact.dart';
import 'package:wms_app/features/chat/domain/entities/chat_conversation.dart';
import 'package:wms_app/features/chat/domain/repositories/chat_repository.dart';

/// Abre (o crea si no existe) la conversación con un contacto.
@lazySingleton
class EnsureConversation implements UseCase<ChatConversation, ChatContact> {
  final ChatRepository repository;

  EnsureConversation(this.repository);

  @override
  Future<Either<Failure, ChatConversation>> call(ChatContact contact) =>
      repository.ensureConversationWith(contact);
}
