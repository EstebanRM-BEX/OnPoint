import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_pedido.dart';
import 'package:wms_app/features/expedition/domain/repositories/expedition_repository.dart';

class AsignarResponsableParams {
  final int expeditionId;

  const AsignarResponsableParams({required this.expeditionId});
}

@lazySingleton
class AsignarResponsableUseCase
    implements UseCase<ExpedicionPedido, AsignarResponsableParams> {
  final ExpeditionRepository repository;

  AsignarResponsableUseCase(this.repository);

  @override
  Future<Either<Failure, ExpedicionPedido>> call(
      AsignarResponsableParams params) async {
    return await repository.asignarResponsable(params.expeditionId);
  }
}
