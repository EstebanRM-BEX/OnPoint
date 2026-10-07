import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';

/// Ubicaciones de muelle para los paquetes.
@lazySingleton
class GetUbicacionesMuelleUseCase
    implements UseCase<List<UbicacionMuelle>, NoParams> {
  final PackingPedidoRepository repository;

  GetUbicacionesMuelleUseCase(this.repository);

  @override
  Future<Either<Failure, List<UbicacionMuelle>>> call(NoParams params) {
    return repository.getUbicacionesMuelle();
  }
}
