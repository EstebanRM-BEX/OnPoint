import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_pool_item.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/repositories/recepcion_multiusuario_repository.dart';

class GetRecepcionPoolFromDbParams {
  final int sessionId;

  const GetRecepcionPoolFromDbParams({required this.sessionId});
}

@lazySingleton
class GetRecepcionPoolFromDbUseCase
    implements UseCase<List<RecepcionPoolItem>, GetRecepcionPoolFromDbParams> {
  final RecepcionMultiusuarioRepository repository;

  GetRecepcionPoolFromDbUseCase(this.repository);

  @override
  Future<Either<Failure, List<RecepcionPoolItem>>> call(
    GetRecepcionPoolFromDbParams params,
  ) async {
    return await repository.getPoolFromDb(params.sessionId);
  }
}
