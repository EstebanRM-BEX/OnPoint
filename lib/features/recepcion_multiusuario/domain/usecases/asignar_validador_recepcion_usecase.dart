import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/repositories/recepcion_multiusuario_repository.dart';

class AsignarValidadorRecepcionParams {
  final int sessionId;
  final int userId;

  const AsignarValidadorRecepcionParams({
    required this.sessionId,
    required this.userId,
  });
}

@lazySingleton
class AsignarValidadorRecepcionUseCase
    implements UseCase<RecepcionSession, AsignarValidadorRecepcionParams> {
  final RecepcionMultiusuarioRepository repository;

  AsignarValidadorRecepcionUseCase(this.repository);

  @override
  Future<Either<Failure, RecepcionSession>> call(
    AsignarValidadorRecepcionParams params,
  ) async {
    return await repository.asignarValidador(
      sessionId: params.sessionId,
      userId: params.userId,
    );
  }
}
