import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_detail.dart';
import 'package:wms_app/features/expedition/domain/repositories/expedition_repository.dart';

class GetExpedicionDetailParams {
  final int expeditionId;

  const GetExpedicionDetailParams({required this.expeditionId});
}

@lazySingleton
class GetExpedicionDetailUseCase
    implements UseCase<ExpedicionDetail, GetExpedicionDetailParams> {
  final ExpeditionRepository repository;

  GetExpedicionDetailUseCase(this.repository);

  @override
  Future<Either<Failure, ExpedicionDetail>> call(
      GetExpedicionDetailParams params) async {
    return await repository.getExpedicionDetail(params.expeditionId);
  }
}
