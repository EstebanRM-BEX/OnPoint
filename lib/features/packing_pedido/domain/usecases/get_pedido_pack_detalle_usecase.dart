import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_resultados.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';

class GetPedidoPackDetalleParams {
  final int pedidoId;

  const GetPedidoPackDetalleParams({required this.pedidoId});
}

/// Pedido con sus líneas repartidas por estado y sus paquetes.
@lazySingleton
class GetPedidoPackDetalleUseCase
    implements UseCase<PedidoPackDetalle, GetPedidoPackDetalleParams> {
  final PackingPedidoRepository repository;

  GetPedidoPackDetalleUseCase(this.repository);

  @override
  Future<Either<Failure, PedidoPackDetalle>> call(
    GetPedidoPackDetalleParams params,
  ) {
    return repository.getPedidoDetalle(params.pedidoId);
  }
}
