import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/repositories/transferencia_multiusuario_repository.dart';

class UndoTransferenciaClaimParams {
  final int claimId;
  final String observacion;

  const UndoTransferenciaClaimParams({
    required this.claimId,
    required this.observacion,
  });
}

@lazySingleton
class UndoTransferenciaClaimUseCase
    implements UseCase<Unit, UndoTransferenciaClaimParams> {
  final TransferenciaMultiusuarioRepository repository;

  UndoTransferenciaClaimUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(
    UndoTransferenciaClaimParams params,
  ) async {
    return await repository.undoClaim(
      claimId: params.claimId,
      observacion: params.observacion,
    );
  }
}
