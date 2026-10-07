import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/paquete_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/pedido_pack.dart';
import 'package:wms_app/features/packing_pedido/domain/failures/packing_failures.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';

class EliminarPaqueteParams {
  final PedidoPack pedido;
  final PaquetePacking paquete;

  const EliminarPaqueteParams({required this.pedido, required this.paquete});
}

/// Elimina la caja completa. Devuelve el mensaje de Odoo.
@lazySingleton
class EliminarPaqueteUseCase implements UseCase<String, EliminarPaqueteParams> {
  final PackingPedidoRepository repository;

  EliminarPaqueteUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(EliminarPaqueteParams params) async {
    if (params.pedido.isTerminate) {
      return const Left(
        PackingValidationFailure(
          'El pedido ya está terminado, no se puede eliminar el paquete',
        ),
      );
    }
    if (params.paquete.pedidoId != params.pedido.id) {
      return const Left(
        PackingValidationFailure('El paquete no pertenece a este pedido'),
      );
    }
    return repository.eliminarPaquete(params.paquete);
  }
}
