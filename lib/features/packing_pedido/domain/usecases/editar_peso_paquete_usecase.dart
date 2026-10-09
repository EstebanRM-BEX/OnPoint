import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/paquete_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/pedido_pack.dart';
import 'package:wms_app/features/packing_pedido/domain/failures/packing_failures.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';

class EditarPesoPaqueteParams {
  final PedidoPack pedido;
  final PaquetePacking paquete;
  final double peso;

  const EditarPesoPaqueteParams({
    required this.pedido,
    required this.paquete,
    required this.peso,
  });
}

/// Cambia el peso de la caja. Devuelve el mensaje de Odoo.
@lazySingleton
class EditarPesoPaqueteUseCase
    implements UseCase<String, EditarPesoPaqueteParams> {
  final PackingPedidoRepository repository;

  EditarPesoPaqueteUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(EditarPesoPaqueteParams params) async {
    if (params.pedido.isTerminate) {
      return const Left(
        PackingValidationFailure(
          'El pedido ya está terminado, no se puede editar el paquete',
        ),
      );
    }
    if (params.paquete.pedidoId != params.pedido.id) {
      return const Left(
        PackingValidationFailure('El paquete no pertenece a este pedido'),
      );
    }
    if (params.peso <= 0) {
      return const Left(
        PackingValidationFailure('El peso debe ser mayor a cero'),
      );
    }
    return repository.editarPesoPaquete(
      paquete: params.paquete,
      peso: params.peso,
    );
  }
}
