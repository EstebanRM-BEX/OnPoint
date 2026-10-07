import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_resultados.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';

class RefrescarDetallePackParams extends Equatable {
  final int pedidoId;

  const RefrescarDetallePackParams({required this.pedidoId});

  @override
  List<Object?> get props => [pedidoId];
}

/// Consulta el detalle del pedido en el servidor, reconcilia la base local
/// y devuelve el [PedidoPackDetalle] actualizado.
@lazySingleton
class RefrescarDetallePackUseCase
    implements UseCase<PedidoPackDetalle, RefrescarDetallePackParams> {
  final PackingPedidoRepository repository;

  RefrescarDetallePackUseCase(this.repository);

  @override
  Future<Either<Failure, PedidoPackDetalle>> call(
    RefrescarDetallePackParams params,
  ) {
    return repository.refrescarDetalleRemoto(params.pedidoId);
  }
}
