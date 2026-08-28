import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/repositories/recepcion_multiusuario_repository.dart';

@lazySingleton
class GetRecepcionSessionsFromDbUseCase
    implements UseCase<List<RecepcionSession>, NoParams> {
  final RecepcionMultiusuarioRepository repository;

  GetRecepcionSessionsFromDbUseCase(this.repository);

  @override
  Future<Either<Failure, List<RecepcionSession>>> call(NoParams params) async {
    return await repository.getSessionsFromDb();
  }
}
