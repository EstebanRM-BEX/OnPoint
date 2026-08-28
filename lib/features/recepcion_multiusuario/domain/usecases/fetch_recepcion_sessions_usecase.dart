import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/repositories/recepcion_multiusuario_repository.dart';

class FetchRecepcionSessionsParams {
  final bool isLoadinDialog;

  const FetchRecepcionSessionsParams({this.isLoadinDialog = false});
}

@lazySingleton
class FetchRecepcionSessionsUseCase
    implements UseCase<List<RecepcionSession>, FetchRecepcionSessionsParams> {
  final RecepcionMultiusuarioRepository repository;

  FetchRecepcionSessionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<RecepcionSession>>> call(
    FetchRecepcionSessionsParams params,
  ) async {
    return await repository.fetchSessions(
      isLoadinDialog: params.isLoadinDialog,
    );
  }
}
