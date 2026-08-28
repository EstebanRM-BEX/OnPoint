import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/repositories/recepcion_multiusuario_repository.dart';

class ReleaseClaimParams {
  final int claimId;

  const ReleaseClaimParams({required this.claimId});
}

@lazySingleton
class ReleaseClaimUseCase implements UseCase<Unit, ReleaseClaimParams> {
  final RecepcionMultiusuarioRepository repository;

  ReleaseClaimUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(ReleaseClaimParams params) async {
    return await repository.releaseClaim(claimId: params.claimId);
  }
}
