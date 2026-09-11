import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/repositories/transferencia_multiusuario_repository.dart';

class ReleaseTransferenciaClaimParams {
  final int claimId;

  const ReleaseTransferenciaClaimParams({required this.claimId});
}

@lazySingleton
class ReleaseTransferenciaClaimUseCase
    implements UseCase<Unit, ReleaseTransferenciaClaimParams> {
  final TransferenciaMultiusuarioRepository repository;

  ReleaseTransferenciaClaimUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(
    ReleaseTransferenciaClaimParams params,
  ) async {
    return await repository.releaseClaim(claimId: params.claimId);
  }
}
