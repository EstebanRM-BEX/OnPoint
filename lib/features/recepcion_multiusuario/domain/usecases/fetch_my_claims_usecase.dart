import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_claim.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/repositories/recepcion_multiusuario_repository.dart';

class FetchMyClaimsParams {
  final int sessionId;
  final bool isLoadinDialog;

  const FetchMyClaimsParams({
    required this.sessionId,
    this.isLoadinDialog = false,
  });
}

@lazySingleton
class FetchMyClaimsUseCase
    implements UseCase<List<RecepcionClaim>, FetchMyClaimsParams> {
  final RecepcionMultiusuarioRepository repository;

  FetchMyClaimsUseCase(this.repository);

  @override
  Future<Either<Failure, List<RecepcionClaim>>> call(
    FetchMyClaimsParams params,
  ) async {
    return await repository.fetchMyClaims(
      sessionId: params.sessionId,
      isLoadinDialog: params.isLoadinDialog,
    );
  }
}
