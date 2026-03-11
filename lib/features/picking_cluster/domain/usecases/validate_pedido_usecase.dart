import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import '../repositories/picking_cluster_repository.dart';

@lazySingleton
class ValidatePedidoUseCase implements UseCase<bool, ValidatePedidoParams> {
  final IPickingClusterRepository repository;

  ValidatePedidoUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(ValidatePedidoParams params) async {
    return await repository.validatePedido(params.idPedido, params.idLocation);
  }
}

class ValidatePedidoParams {
  final int idPedido;
  final int idLocation;

  ValidatePedidoParams({required this.idPedido, required this.idLocation});
}
