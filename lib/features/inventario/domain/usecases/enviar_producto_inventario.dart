// lib/features/inventario/domain/usecases/enviar_producto_inventario.dart

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/inventario/domain/entities/resultado_envio_inventario.dart';
import 'package:wms_app/features/inventario/domain/repositories/inventario_repository.dart';

@lazySingleton
class EnviarProductoInventario
    implements
        UseCase<ResultadoEnvioInventario, EnviarProductoInventarioParams> {
  final InventarioRepository repository;

  EnviarProductoInventario(this.repository);

  @override
  Future<Either<Failure, ResultadoEnvioInventario>> call(
      EnviarProductoInventarioParams params) {
    return repository.enviarProductoInventario(
      locationId: params.locationId,
      productId: params.productId,
      lotId: params.lotId,
      quantity: params.quantity,
    );
  }
}

class EnviarProductoInventarioParams {
  final dynamic locationId;
  final dynamic productId;
  final dynamic lotId;
  final dynamic quantity;

  const EnviarProductoInventarioParams({
    required this.locationId,
    required this.productId,
    required this.lotId,
    required this.quantity,
  });
}
