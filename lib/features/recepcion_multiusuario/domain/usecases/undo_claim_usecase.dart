import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/repositories/recepcion_multiusuario_repository.dart';

class UndoClaimParams {
  final int claimId;
  final String observacion;

  const UndoClaimParams({required this.claimId, required this.observacion});
}

@lazySingleton
class UndoClaimUseCase implements UseCase<Unit, UndoClaimParams> {
  final RecepcionMultiusuarioRepository repository;

  UndoClaimUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(UndoClaimParams params) async {
    return await repository.undoClaim(
      claimId: params.claimId,
      observacion: params.observacion,
    );
  }
}
