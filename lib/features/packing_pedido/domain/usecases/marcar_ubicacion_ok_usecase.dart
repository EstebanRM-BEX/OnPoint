import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';

class MarcarUbicacionOkParams {
  final ProductoPacking producto;

  const MarcarUbicacionOkParams({required this.producto});
}

/// Ubicación de origen confirmada para la línea.
@lazySingleton
class MarcarUbicacionOkUseCase
    implements UseCase<ProductoPacking, MarcarUbicacionOkParams> {
  final PackingPedidoRepository repository;

  MarcarUbicacionOkUseCase(this.repository);

  @override
  Future<Either<Failure, ProductoPacking>> call(
    MarcarUbicacionOkParams params,
  ) {
    return repository.marcarUbicacionOk(params.producto);
  }
}
