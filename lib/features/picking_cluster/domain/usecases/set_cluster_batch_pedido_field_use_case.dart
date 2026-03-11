import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import '../repositories/picking_cluster_repository.dart';

@lazySingleton
class SetClusterBatchPedidoFieldUseCase
    implements UseCase<void, SetClusterBatchPedidoFieldParams> {
  final IPickingClusterRepository repository;

  SetClusterBatchPedidoFieldUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(
      SetClusterBatchPedidoFieldParams params) async {
    return await repository.setFieldTableBatchPedidoValidate(
      params.batchId,
      params.namePedido,
      params.field,
      params.value,
    );
  }
}

class SetClusterBatchPedidoFieldParams {
  final int batchId;
  final String namePedido;
  final String field;
  final dynamic value;

  SetClusterBatchPedidoFieldParams({
    required this.batchId,
    required this.namePedido,
    required this.field,
    required this.value,
  });
}
