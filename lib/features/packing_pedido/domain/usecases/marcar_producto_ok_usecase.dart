import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';

class MarcarProductoOkParams {
  final ProductoPacking producto;

  const MarcarProductoOkParams({required this.producto});
}

/// Producto confirmado: arranca el tiempo de separación.
@lazySingleton
class MarcarProductoOkUseCase
    implements UseCase<ProductoPacking, MarcarProductoOkParams> {
  final PackingPedidoRepository repository;

  MarcarProductoOkUseCase(this.repository);

  @override
  Future<Either<Failure, ProductoPacking>> call(MarcarProductoOkParams params) {
    return repository.marcarProductoOk(params.producto);
  }
}
