import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/chat/domain/entities/chat_contact.dart';
import 'package:wms_app/features/chat/domain/repositories/chat_repository.dart';

/// Lista los contactos con los que se puede iniciar una conversación.
@lazySingleton
class GetContacts implements UseCase<List<ChatContact>, NoParams> {
  final ChatRepository repository;

  GetContacts(this.repository);

  @override
  Future<Either<Failure, List<ChatContact>>> call(NoParams params) =>
      repository.getContacts();
}
