import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';

class EnviarImagenNovedadPackParams {
  final ProductoPacking producto;
  final String imagePath;

  const EnviarImagenNovedadPackParams({
    required this.producto,
    required this.imagePath,
  });
}

/// Adjunta la foto de evidencia de una novedad.
@lazySingleton
class EnviarImagenNovedadPackUseCase
    implements UseCase<ProductoPacking, EnviarImagenNovedadPackParams> {
  final PackingPedidoRepository repository;

  EnviarImagenNovedadPackUseCase(this.repository);

  @override
  Future<Either<Failure, ProductoPacking>> call(
    EnviarImagenNovedadPackParams params,
  ) {
    return repository.enviarImagenNovedad(
      producto: params.producto,
      imagePath: params.imagePath,
    );
  }
}
