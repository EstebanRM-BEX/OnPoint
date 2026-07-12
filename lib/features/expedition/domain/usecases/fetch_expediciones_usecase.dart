import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_fetch_result.dart';
import 'package:wms_app/features/expedition/domain/repositories/expedition_repository.dart';

class FetchExpedicionesParams {
  final bool isLoadinDialog;

  const FetchExpedicionesParams({this.isLoadinDialog = false});
}

@lazySingleton
class FetchExpedicionesUseCase
    implements UseCase<ExpedicionFetchResult, FetchExpedicionesParams> {
  final ExpeditionRepository repository;

  FetchExpedicionesUseCase(this.repository);

  @override
  Future<Either<Failure, ExpedicionFetchResult>> call(
      FetchExpedicionesParams params) async {
    return await repository.fetchExpediciones(
      isLoadinDialog: params.isLoadinDialog,
    );
  }
}
