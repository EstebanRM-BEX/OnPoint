import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/failures/packing_failures.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';

class DeshacerSeparacionParams {
  final ProductoPacking producto;

  const DeshacerSeparacionParams({required this.producto});
}

/// Devuelve una línea de "Listos" a "Por hacer" (antes de empacarla).
@lazySingleton
class DeshacerSeparacionUseCase
    implements UseCase<Unit, DeshacerSeparacionParams> {
  final PackingPedidoRepository repository;

  DeshacerSeparacionUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(DeshacerSeparacionParams params) async {
    if (!params.producto.isListo) {
      return const Left(
        PackingValidationFailure(
          'Solo se puede deshacer un producto listo sin empacar',
        ),
      );
    }
    return repository.deshacerSeparacion(params.producto);
  }
}
