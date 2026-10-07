import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_resultados.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/paquete_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/pedido_pack.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/failures/packing_failures.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';

class DesempacarProductoParams {
  final PedidoPack pedido;
  final PaquetePacking paquete;
  final ProductoPacking producto;

  const DesempacarProductoParams({
    required this.pedido,
    required this.paquete,
    required this.producto,
  });
}

/// Saca una línea de su caja; la cantidad vuelve a "Por hacer".
@lazySingleton
class DesempacarProductoUseCase
    implements UseCase<DesempaqueResult, DesempacarProductoParams> {
  final PackingPedidoRepository repository;

  DesempacarProductoUseCase(this.repository);

  @override
  Future<Either<Failure, DesempaqueResult>> call(
    DesempacarProductoParams params,
  ) async {
    if (params.pedido.isTerminate) {
      return const Left(
        PackingValidationFailure(
          'El pedido ya está terminado, no se puede desempacar',
        ),
      );
    }
    final producto = params.producto;
    if (!producto.isEmpacado || producto.idPackage != params.paquete.id) {
      return const Left(
        PackingValidationFailure('El producto no está en este paquete'),
      );
    }
    return repository.desempacarProducto(
      paquete: params.paquete,
      producto: producto,
    );
  }
}
