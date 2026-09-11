import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_pool_item.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/repositories/transferencia_multiusuario_repository.dart';

class FetchTransferenciaPoolParams {
  final int sessionId;
  final bool isLoadinDialog;
  final bool verification;

  const FetchTransferenciaPoolParams({
    required this.sessionId,
    this.isLoadinDialog = false,
    this.verification = false,
  });
}

@lazySingleton
class FetchTransferenciaPoolUseCase
    implements
        UseCase<List<TransferenciaPoolItem>, FetchTransferenciaPoolParams> {
  final TransferenciaMultiusuarioRepository repository;

  FetchTransferenciaPoolUseCase(this.repository);

  @override
  Future<Either<Failure, List<TransferenciaPoolItem>>> call(
    FetchTransferenciaPoolParams params,
  ) async {
    return await repository.fetchPool(
      sessionId: params.sessionId,
      isLoadinDialog: params.isLoadinDialog,
      verification: params.verification,
    );
  }
}
