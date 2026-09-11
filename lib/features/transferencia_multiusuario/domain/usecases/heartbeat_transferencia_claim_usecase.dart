import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/repositories/transferencia_multiusuario_repository.dart';

class HeartbeatTransferenciaClaimParams {
  final int claimId;

  const HeartbeatTransferenciaClaimParams({required this.claimId});
}

@lazySingleton
class HeartbeatTransferenciaClaimUseCase
    implements UseCase<Unit, HeartbeatTransferenciaClaimParams> {
  final TransferenciaMultiusuarioRepository repository;

  HeartbeatTransferenciaClaimUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(
    HeartbeatTransferenciaClaimParams params,
  ) async {
    return await repository.heartbeat(claimId: params.claimId);
  }
}
