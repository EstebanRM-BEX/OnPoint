import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';

/// Permisos del usuario para packing.
@lazySingleton
class GetConfigPackingUseCase
    implements UseCase<ConfigPackingUsuario, NoParams> {
  final PackingPedidoRepository repository;

  GetConfigPackingUseCase(this.repository);

  @override
  Future<Either<Failure, ConfigPackingUsuario>> call(NoParams params) {
    return repository.getConfiguracion();
  }
}
