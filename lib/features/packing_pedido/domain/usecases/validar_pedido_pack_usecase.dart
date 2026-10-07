import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_resultados.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/pedido_pack.dart';
import 'package:wms_app/features/packing_pedido/domain/failures/packing_failures.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';

class ValidarPedidoPackParams {
  final PedidoPack pedido;
  final bool crearBackorder;

  /// Reintento tras [PackingVencidosFailure], aceptando productos vencidos.
  final bool aceptarVencidos;

  const ValidarPedidoPackParams({
    required this.pedido,
    required this.crearBackorder,
    this.aceptarVencidos = false,
  });
}

/// Valida (cierra) el pedido en Odoo, con o sin backorder.
@lazySingleton
class ValidarPedidoPackUseCase
    implements UseCase<ValidacionPedidoResult, ValidarPedidoPackParams> {
  final PackingPedidoRepository repository;

  ValidarPedidoPackUseCase(this.repository);

  @override
  Future<Either<Failure, ValidacionPedidoResult>> call(
    ValidarPedidoPackParams params,
  ) async {
    if (params.pedido.isTerminate) {
      return const Left(
        PackingValidationFailure('El pedido ya está terminado'),
      );
    }
    return repository.validarPedido(
      pedidoId: params.pedido.id,
      crearBackorder: params.crearBackorder,
      aceptarVencidos: params.aceptarVencidos,
    );
  }
}
