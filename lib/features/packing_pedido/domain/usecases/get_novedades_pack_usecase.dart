import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';
import 'package:wms_app/features/user/domain/entities/user_novelty.dart';

/// Novedades disponibles para separar con faltante.
@lazySingleton
class GetNovedadesPackUseCase implements UseCase<List<Novedad>, NoParams> {
  final PackingPedidoRepository repository;

  GetNovedadesPackUseCase(this.repository);

  @override
  Future<Either<Failure, List<Novedad>>> call(NoParams params) {
    return repository.getNovedades();
  }
}
