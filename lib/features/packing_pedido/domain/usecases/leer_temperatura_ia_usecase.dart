import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';

class LeerTemperaturaIaParams {
  final String imagePath;

  const LeerTemperaturaIaParams({required this.imagePath});
}

/// Lee la temperatura de la foto de un termómetro.
@lazySingleton
class LeerTemperaturaIaUseCase
    implements UseCase<TemperaturaIa, LeerTemperaturaIaParams> {
  final PackingPedidoRepository repository;

  LeerTemperaturaIaUseCase(this.repository);

  @override
  Future<Either<Failure, TemperaturaIa>> call(LeerTemperaturaIaParams params) {
    return repository.leerTemperaturaIa(params.imagePath);
  }
}
