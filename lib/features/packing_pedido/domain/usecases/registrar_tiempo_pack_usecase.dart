import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';

class RegistrarTiempoPackParams {
  final int pedidoId;
  final MarcaTiempoPack marca;

  const RegistrarTiempoPackParams({
    required this.pedidoId,
    required this.marca,
  });
}

/// Envía la hora de inicio o fin del pedido.
@lazySingleton
class RegistrarTiempoPackUseCase
    implements UseCase<Unit, RegistrarTiempoPackParams> {
  final PackingPedidoRepository repository;

  RegistrarTiempoPackUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(RegistrarTiempoPackParams params) {
    return repository.registrarTiempo(
      pedidoId: params.pedidoId,
      marca: params.marca,
    );
  }
}
