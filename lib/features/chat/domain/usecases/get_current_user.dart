import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/chat/domain/entities/chat_contact.dart';
import 'package:wms_app/features/chat/domain/repositories/chat_repository.dart';

/// Obtiene el usuario actual (el "yo" de las conversaciones).
@lazySingleton
class GetCurrentUser implements UseCase<ChatContact, NoParams> {
  final ChatRepository repository;

  GetCurrentUser(this.repository);

  @override
  Future<Either<Failure, ChatContact>> call(NoParams params) =>
      repository.getCurrentUser();
}
