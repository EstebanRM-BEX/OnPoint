import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/repositories/recepcion_multiusuario_repository.dart';

class FetchRecepcionSessionDetailParams {
  final int pickingId;
  final bool isLoadinDialog;

  const FetchRecepcionSessionDetailParams({
    required this.pickingId,
    this.isLoadinDialog = false,
  });
}

@lazySingleton
class FetchRecepcionSessionDetailUseCase
    implements UseCase<RecepcionSession, FetchRecepcionSessionDetailParams> {
  final RecepcionMultiusuarioRepository repository;

  FetchRecepcionSessionDetailUseCase(this.repository);

  @override
  Future<Either<Failure, RecepcionSession>> call(
    FetchRecepcionSessionDetailParams params,
  ) async {
    return await repository.fetchSessionDetail(
      pickingId: params.pickingId,
      isLoadinDialog: params.isLoadinDialog,
    );
  }
}
