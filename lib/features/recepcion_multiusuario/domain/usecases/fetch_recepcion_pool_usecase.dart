import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_pool_item.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/repositories/recepcion_multiusuario_repository.dart';

class FetchRecepcionPoolParams {
  final int sessionId;
  final bool isLoadinDialog;

  const FetchRecepcionPoolParams({
    required this.sessionId,
    this.isLoadinDialog = false,
  });
}

@lazySingleton
class FetchRecepcionPoolUseCase
    implements UseCase<List<RecepcionPoolItem>, FetchRecepcionPoolParams> {
  final RecepcionMultiusuarioRepository repository;

  FetchRecepcionPoolUseCase(this.repository);

  @override
  Future<Either<Failure, List<RecepcionPoolItem>>> call(
    FetchRecepcionPoolParams params,
  ) async {
    return await repository.fetchPool(
      sessionId: params.sessionId,
      isLoadinDialog: params.isLoadinDialog,
    );
  }
}
