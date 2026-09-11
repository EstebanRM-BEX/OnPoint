import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_session.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/repositories/transferencia_multiusuario_repository.dart';

@lazySingleton
class GetTransferenciaSessionsFromDbUseCase
    implements UseCase<List<TransferenciaSession>, NoParams> {
  final TransferenciaMultiusuarioRepository repository;

  GetTransferenciaSessionsFromDbUseCase(this.repository);

  @override
  Future<Either<Failure, List<TransferenciaSession>>> call(
    NoParams params,
  ) async {
    return await repository.getSessionsFromDb();
  }
}
