import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/pedido_pack.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';

/// Pedidos de packing guardados en el dispositivo.
@lazySingleton
class GetPedidosPackLocalUseCase
    implements UseCase<List<PedidoPack>, NoParams> {
  final PackingPedidoRepository repository;

  GetPedidosPackLocalUseCase(this.repository);

  @override
  Future<Either<Failure, List<PedidoPack>>> call(NoParams params) {
    return repository.getPedidosLocal();
  }
}
