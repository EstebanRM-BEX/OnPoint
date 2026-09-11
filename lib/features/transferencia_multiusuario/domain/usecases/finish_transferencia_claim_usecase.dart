import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_claim.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/repositories/transferencia_multiusuario_repository.dart';

class FinishTransferenciaClaimParams {
  final int claimId;
  final double qtyDone;
  final int lotId;
  final int locationDestId;
  final int timeLine;
  final String observation;
  final double quantitySegundaUnidad;

  const FinishTransferenciaClaimParams({
    required this.claimId,
    required this.qtyDone,
    this.lotId = 0,
    this.locationDestId = 0,
    this.timeLine = 0,
    this.observation = '',
    this.quantitySegundaUnidad = 0.0,
  });
}

@lazySingleton
class FinishTransferenciaClaimUseCase
    implements UseCase<TransferenciaClaim, FinishTransferenciaClaimParams> {
  final TransferenciaMultiusuarioRepository repository;

  FinishTransferenciaClaimUseCase(this.repository);

  @override
  Future<Either<Failure, TransferenciaClaim>> call(
    FinishTransferenciaClaimParams params,
  ) async {
    return await repository.finishClaim(
      claimId: params.claimId,
      qtyDone: params.qtyDone,
      lotId: params.lotId,
      locationDestId: params.locationDestId,
      timeLine: params.timeLine,
      observation: params.observation,
      quantitySegundaUnidad: params.quantitySegundaUnidad,
    );
  }
}
