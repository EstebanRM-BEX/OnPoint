import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_resultados.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';

class SyncPedidosPackParams {
  final bool isLoadingDialog;

  const SyncPedidosPackParams({required this.isLoadingDialog});
}

/// Sincroniza los pedidos de packing desde Odoo hacia la base local.
@lazySingleton
class SyncPedidosPackUseCase
    implements UseCase<SyncPedidosPackResult, SyncPedidosPackParams> {
  final PackingPedidoRepository repository;

  SyncPedidosPackUseCase(this.repository);

  @override
  Future<Either<Failure, SyncPedidosPackResult>> call(
    SyncPedidosPackParams params,
  ) {
    return repository.syncPedidos(isLoadingDialog: params.isLoadingDialog);
  }
}
