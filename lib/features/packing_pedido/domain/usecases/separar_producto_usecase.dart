import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/failures/packing_failures.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';
import 'package:wms_app/features/packing_pedido/domain/rules/packing_rules.dart';

class SepararProductoParams {
  final ProductoPacking producto;
  final double cantidad;

  /// Obligatoria si [cantidad] es menor a la de la línea (faltante).
  final String? novedad;

  const SepararProductoParams({
    required this.producto,
    required this.cantidad,
    this.novedad,
  });
}

/// Pasa la línea a "Listos". Con cantidad parcial exige novedad: el
/// faltante queda para backorder.
@lazySingleton
class SepararProductoUseCase
    implements UseCase<ProductoPacking, SepararProductoParams> {
  final PackingPedidoRepository repository;

  SepararProductoUseCase(this.repository);

  @override
  Future<Either<Failure, ProductoPacking>> call(
    SepararProductoParams params,
  ) async {
    final error = PackingRules.validarSeparacion(
      params.producto,
      params.cantidad,
    );
    if (error != null) return Left(PackingValidationFailure(error));

    final parcial =
        PackingRules.evaluarCantidad(params.producto, params.cantidad) ==
        ValidacionCantidad.parcial;
    final novedad = params.novedad?.trim() ?? '';
    if (parcial && novedad.isEmpty) {
      return const Left(
        PackingValidationFailure(
          'Seleccione una novedad para separar una cantidad menor',
        ),
      );
    }

    return repository.separarProducto(
      producto: params.producto,
      cantidad: params.cantidad,
      novedad: novedad.isEmpty ? null : novedad,
    );
  }
}
