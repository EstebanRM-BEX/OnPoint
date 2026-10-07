import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/pedido_pack.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';

class AsignarResponsablePackParams {
  final int pedidoId;

  const AsignarResponsablePackParams({required this.pedidoId});
}

/// Asigna el usuario actual al pedido e inicia su tiempo.
@lazySingleton
class AsignarResponsablePackUseCase
    implements UseCase<PedidoPack, AsignarResponsablePackParams> {
  final PackingPedidoRepository repository;

  AsignarResponsablePackUseCase(this.repository);

  @override
  Future<Either<Failure, PedidoPack>> call(
    AsignarResponsablePackParams params,
  ) {
    return repository.asignarResponsable(params.pedidoId);
  }
}
