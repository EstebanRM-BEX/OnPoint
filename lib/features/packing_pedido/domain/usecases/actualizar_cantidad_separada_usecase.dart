import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/failures/packing_failures.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';
import 'package:wms_app/features/packing_pedido/domain/rules/packing_rules.dart';

class ActualizarCantidadSeparadaParams {
  final ProductoPacking producto;

  /// Cantidad total separada (no el incremento).
  final double cantidad;

  const ActualizarCantidadSeparadaParams({
    required this.producto,
    required this.cantidad,
  });
}

/// Guarda lo que va separado de una línea mientras se escanea. No deja
/// pasar de la cantidad de la línea.
@lazySingleton
class ActualizarCantidadSeparadaUseCase
    implements UseCase<ProductoPacking, ActualizarCantidadSeparadaParams> {
  final PackingPedidoRepository repository;

  ActualizarCantidadSeparadaUseCase(this.repository);

  @override
  Future<Either<Failure, ProductoPacking>> call(
    ActualizarCantidadSeparadaParams params,
  ) async {
    final producto = params.producto;
    if (!producto.isPorHacer) {
      return const Left(
        PackingValidationFailure('El producto ya fue separado'),
      );
    }
    if (params.cantidad.isNaN || params.cantidad < 0) {
      return const Left(PackingValidationFailure('Cantidad inválida'));
    }
    if (params.cantidad > producto.quantity + PackingRules.epsilon) {
      return Left(
        PackingValidationFailure(
          'La cantidad no puede ser mayor a ${producto.quantity}',
        ),
      );
    }
    return repository.actualizarCantidadSeparada(producto, params.cantidad);
  }
}
