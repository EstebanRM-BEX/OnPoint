import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_claim.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/repositories/transferencia_multiusuario_repository.dart';

class FetchTransferenciaMyClaimsParams {
  final int sessionId;
  final bool isLoadinDialog;

  const FetchTransferenciaMyClaimsParams({
    required this.sessionId,
    this.isLoadinDialog = false,
  });
}

@lazySingleton
class FetchTransferenciaMyClaimsUseCase
    implements
        UseCase<List<TransferenciaClaim>, FetchTransferenciaMyClaimsParams> {
  final TransferenciaMultiusuarioRepository repository;

  FetchTransferenciaMyClaimsUseCase(this.repository);

  @override
  Future<Either<Failure, List<TransferenciaClaim>>> call(
    FetchTransferenciaMyClaimsParams params,
  ) async {
    return await repository.fetchMyClaims(
      sessionId: params.sessionId,
      isLoadinDialog: params.isLoadinDialog,
    );
  }
}
