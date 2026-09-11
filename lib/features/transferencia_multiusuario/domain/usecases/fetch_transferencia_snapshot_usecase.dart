import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_snapshot.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/repositories/transferencia_multiusuario_repository.dart';

class FetchTransferenciaSnapshotParams {
  final int sessionId;
  final bool isLoadinDialog;

  const FetchTransferenciaSnapshotParams({
    required this.sessionId,
    this.isLoadinDialog = false,
  });
}

@lazySingleton
class FetchTransferenciaSnapshotUseCase
    implements
        UseCase<TransferenciaSnapshot, FetchTransferenciaSnapshotParams> {
  final TransferenciaMultiusuarioRepository repository;

  FetchTransferenciaSnapshotUseCase(this.repository);

  @override
  Future<Either<Failure, TransferenciaSnapshot>> call(
    FetchTransferenciaSnapshotParams params,
  ) async {
    return await repository.fetchSnapshot(
      sessionId: params.sessionId,
      isLoadinDialog: params.isLoadinDialog,
    );
  }
}
