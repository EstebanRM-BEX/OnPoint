import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_session.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/repositories/transferencia_multiusuario_repository.dart';

class FetchTransferenciaSessionDetailParams {
  final int sessionId;
  final bool isLoadinDialog;

  const FetchTransferenciaSessionDetailParams({
    required this.sessionId,
    this.isLoadinDialog = false,
  });
}

@lazySingleton
class FetchTransferenciaSessionDetailUseCase
    implements
        UseCase<TransferenciaSession, FetchTransferenciaSessionDetailParams> {
  final TransferenciaMultiusuarioRepository repository;

  FetchTransferenciaSessionDetailUseCase(this.repository);

  @override
  Future<Either<Failure, TransferenciaSession>> call(
    FetchTransferenciaSessionDetailParams params,
  ) async {
    return await repository.fetchSessionDetail(
      sessionId: params.sessionId,
      isLoadinDialog: params.isLoadinDialog,
    );
  }
}
