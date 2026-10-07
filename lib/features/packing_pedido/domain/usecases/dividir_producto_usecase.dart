import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/failures/packing_failures.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';
import 'package:wms_app/features/packing_pedido/domain/rules/packing_rules.dart';

class DividirProductoParams {
  final ProductoPacking producto;

  /// Cantidad que se separa ahora; el resto queda en "Por hacer".
  final double cantidad;

  const DividirProductoParams({required this.producto, required this.cantidad});
}

/// Divide una línea: [DividirProductoParams.cantidad] pasa a "Listos" y el
/// resto queda como una línea nueva en "Por hacer".
@lazySingleton
class DividirProductoUseCase implements UseCase<Unit, DividirProductoParams> {
  final PackingPedidoRepository repository;

  DividirProductoUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(DividirProductoParams params) async {
    final error = PackingRules.validarDivision(
      params.producto,
      params.cantidad,
    );
    if (error != null) return Left(PackingValidationFailure(error));

    return repository.dividirProducto(
      producto: params.producto,
      cantidad: params.cantidad,
    );
  }
}
