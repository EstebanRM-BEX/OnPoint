import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_session.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/repositories/transferencia_multiusuario_repository.dart';

class FetchTransferenciaSessionsParams {
  final bool isLoadinDialog;

  const FetchTransferenciaSessionsParams({this.isLoadinDialog = false});
}

@lazySingleton
class FetchTransferenciaSessionsUseCase
    implements
        UseCase<List<TransferenciaSession>, FetchTransferenciaSessionsParams> {
  final TransferenciaMultiusuarioRepository repository;

  FetchTransferenciaSessionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<TransferenciaSession>>> call(
    FetchTransferenciaSessionsParams params,
  ) async {
    return await repository.fetchSessions(
      isLoadinDialog: params.isLoadinDialog,
    );
  }
}
