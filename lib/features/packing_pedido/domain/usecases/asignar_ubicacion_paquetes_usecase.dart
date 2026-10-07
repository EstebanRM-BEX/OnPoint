import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/paquete_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/failures/packing_failures.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';

class AsignarUbicacionPaquetesParams {
  final int pedidoId;
  final List<PaquetePacking> paquetes;
  final UbicacionMuelle ubicacion;

  const AsignarUbicacionPaquetesParams({
    required this.pedidoId,
    required this.paquetes,
    required this.ubicacion,
  });
}

/// Lleva una o varias cajas a una ubicación de muelle.
@lazySingleton
class AsignarUbicacionPaquetesUseCase
    implements UseCase<String, AsignarUbicacionPaquetesParams> {
  final PackingPedidoRepository repository;

  AsignarUbicacionPaquetesUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(
    AsignarUbicacionPaquetesParams params,
  ) async {
    if (params.paquetes.isEmpty) {
      return const Left(
        PackingValidationFailure('Seleccione al menos un paquete'),
      );
    }
    if (params.paquetes.any((p) => p.pedidoId != params.pedidoId)) {
      return const Left(
        PackingValidationFailure(
          'Hay paquetes que no pertenecen a este pedido',
        ),
      );
    }
    return repository.asignarUbicacionPaquetes(
      pedidoId: params.pedidoId,
      paquetes: params.paquetes,
      ubicacion: params.ubicacion,
    );
  }
}
