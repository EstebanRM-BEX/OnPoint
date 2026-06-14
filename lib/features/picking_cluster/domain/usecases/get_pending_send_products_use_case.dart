import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import '../entities/batch_product.dart';
import '../repositories/picking_cluster_repository.dart';

/// Productos guardados sin conexión (is_send_odoo = 0) pendientes de
/// reenviar a Odoo, de todos los batches type='cluster'.
@lazySingleton
class GetPendingSendProductsUseCase
    implements UseCase<List<BatchProduct>, NoParams> {
  final IPickingClusterRepository repository;

  GetPendingSendProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<BatchProduct>>> call(NoParams params) {
    return repository.getPendingSendProducts();
  }
}
