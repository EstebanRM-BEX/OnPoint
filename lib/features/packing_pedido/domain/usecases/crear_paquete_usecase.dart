import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packaging_types/domain/entities/packaging_type.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/paquete_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/pedido_pack.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/failures/packing_failures.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';
import 'package:wms_app/features/packing_pedido/domain/rules/packing_rules.dart';

class CrearPaqueteParams {
  final PedidoPack pedido;
  final List<ProductoPacking> productos;

  /// true = desde "Listos"; false = directo desde "Por hacer".
  final bool certificado;
  final bool isSticker;
  final double peso;
  final PackagingType? tipoEmpaque;

  const CrearPaqueteParams({
    required this.pedido,
    required this.productos,
    required this.certificado,
    required this.isSticker,
    this.peso = 0,
    this.tipoEmpaque,
  });
}

/// Crea una caja en Odoo con las líneas seleccionadas.
@lazySingleton
class CrearPaqueteUseCase
    implements UseCase<PaquetePacking, CrearPaqueteParams> {
  final PackingPedidoRepository repository;

  CrearPaqueteUseCase(this.repository);

  @override
  Future<Either<Failure, PaquetePacking>> call(
    CrearPaqueteParams params,
  ) async {
    if (params.pedido.isTerminate) {
      return const Left(
        PackingValidationFailure(
          'El pedido ya está terminado, no se pueden crear paquetes',
        ),
      );
    }
    if (params.productos.any((p) => p.pedidoId != params.pedido.id)) {
      return const Left(
        PackingValidationFailure(
          'Hay productos que no pertenecen a este pedido',
        ),
      );
    }
    final error = PackingRules.validarEmpaque(
      params.productos,
      certificado: params.certificado,
    );
    if (error != null) return Left(PackingValidationFailure(error));
    if (params.peso.isNaN || params.peso < 0) {
      return const Left(PackingValidationFailure('Peso inválido'));
    }

    return repository.crearPaquete(
      pedido: params.pedido,
      productos: params.productos,
      certificado: params.certificado,
      isSticker: params.isSticker,
      peso: params.peso,
      tipoEmpaque: params.tipoEmpaque,
    );
  }
}
