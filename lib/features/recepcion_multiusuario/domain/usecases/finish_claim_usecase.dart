import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_claim.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/repositories/recepcion_multiusuario_repository.dart';

class FinishClaimParams {
  final int claimId;
  final double qtyDone;
  final int lotId;
  final int ubicacionDestino;
  final int timeLine;
  final String observation;

  const FinishClaimParams({
    required this.claimId,
    required this.qtyDone,
    this.lotId = 0,
    this.ubicacionDestino = 0,
    this.timeLine = 0,
    this.observation = '',
  });
}

@lazySingleton
class FinishClaimUseCase implements UseCase<RecepcionClaim, FinishClaimParams> {
  final RecepcionMultiusuarioRepository repository;

  FinishClaimUseCase(this.repository);

  @override
  Future<Either<Failure, RecepcionClaim>> call(FinishClaimParams params) async {
    return await repository.finishClaim(
      claimId: params.claimId,
      qtyDone: params.qtyDone,
      lotId: params.lotId,
      ubicacionDestino: params.ubicacionDestino,
      timeLine: params.timeLine,
      observation: params.observation,
    );
  }
}
