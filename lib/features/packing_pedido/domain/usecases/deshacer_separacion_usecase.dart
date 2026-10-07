import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/failures/packing_failures.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';

class DeshacerSeparacionParams {
  final int pedidoId;
  final List<ProductoPacking> productos;

  DeshacerSeparacionParams({
    int? pedidoId,
    List<ProductoPacking>? productos,
    ProductoPacking? producto,
  })  : pedidoId = pedidoId ?? producto?.pedidoId ?? 0,
        productos =
            productos ?? (producto != null ? [producto] : const <ProductoPacking>[]);

  ProductoPacking? get producto => productos.isNotEmpty ? productos.first : null;
}

/// Devuelve líneas de "Listos" a "Por hacer" (antes de empacarlas) vía Odoo.
@lazySingleton
class DeshacerSeparacionUseCase
    implements UseCase<String, DeshacerSeparacionParams> {
  final PackingPedidoRepository repository;

  DeshacerSeparacionUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(DeshacerSeparacionParams params) async {
    if (params.productos.isEmpty) {
      return const Left(
        PackingValidationFailure('No hay productos para devolver'),
      );
    }
    if (params.productos.any((p) => !p.isListo)) {
      return const Left(
        PackingValidationFailure(
          'Solo se puede devolver un producto listo sin empacar',
        ),
      );
    }
    return repository.cancelarPreparados(
      pedidoId: params.pedidoId,
      productos: params.productos,
    );
  }
}
