import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_claim.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/repositories/transferencia_multiusuario_repository.dart';

class ClaimTransferenciaProductParams {
  final int sessionId;
  final int productId;

  const ClaimTransferenciaProductParams({
    required this.sessionId,
    required this.productId,
  });
}

@lazySingleton
class ClaimTransferenciaProductUseCase
    implements UseCase<TransferenciaClaim, ClaimTransferenciaProductParams> {
  final TransferenciaMultiusuarioRepository repository;

  ClaimTransferenciaProductUseCase(this.repository);

  @override
  Future<Either<Failure, TransferenciaClaim>> call(
    ClaimTransferenciaProductParams params,
  ) async {
    return await repository.claimProduct(
      sessionId: params.sessionId,
      productId: params.productId,
    );
  }
}
