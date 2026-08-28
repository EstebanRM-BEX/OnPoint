import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_claim.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/repositories/recepcion_multiusuario_repository.dart';

class ClaimRecepcionProductParams {
  final int sessionId;
  final int productId;

  const ClaimRecepcionProductParams({
    required this.sessionId,
    required this.productId,
  });
}

@lazySingleton
class ClaimRecepcionProductUseCase
    implements UseCase<RecepcionClaim, ClaimRecepcionProductParams> {
  final RecepcionMultiusuarioRepository repository;

  ClaimRecepcionProductUseCase(this.repository);

  @override
  Future<Either<Failure, RecepcionClaim>> call(
    ClaimRecepcionProductParams params,
  ) async {
    return await repository.claimProduct(
      sessionId: params.sessionId,
      productId: params.productId,
    );
  }
}
