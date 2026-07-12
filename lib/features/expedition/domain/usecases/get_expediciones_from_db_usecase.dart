import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_pedido.dart';
import 'package:wms_app/features/expedition/domain/repositories/expedition_repository.dart';

@lazySingleton
class GetExpedicionesFromDbUseCase
    implements UseCase<List<ExpedicionPedido>, NoParams> {
  final ExpeditionRepository repository;

  GetExpedicionesFromDbUseCase(this.repository);

  @override
  Future<Either<Failure, List<ExpedicionPedido>>> call(
      NoParams params) async {
    return await repository.getExpedicionesFromDb();
  }
}
