import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/failures/packing_failures.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';

class EnviarTemperaturaPackParams {
  final ProductoPacking producto;
  final double temperatura;

  /// Foto del termómetro; null = temperatura digitada a mano.
  final String? imagePath;

  const EnviarTemperaturaPackParams({
    required this.producto,
    required this.temperatura,
    this.imagePath,
  });
}

/// Registra la temperatura de un producto que la maneja.
@lazySingleton
class EnviarTemperaturaPackUseCase
    implements UseCase<ProductoPacking, EnviarTemperaturaPackParams> {
  final PackingPedidoRepository repository;

  EnviarTemperaturaPackUseCase(this.repository);

  @override
  Future<Either<Failure, ProductoPacking>> call(
    EnviarTemperaturaPackParams params,
  ) async {
    if (!params.producto.manejaTemperatura) {
      return const Left(
        PackingValidationFailure('El producto no maneja temperatura'),
      );
    }
    if (!params.temperatura.isFinite) {
      return const Left(PackingValidationFailure('Temperatura inválida'));
    }
    final path = params.imagePath?.trim();
    return repository.enviarTemperatura(
      producto: params.producto,
      temperatura: params.temperatura,
      imagePath: (path == null || path.isEmpty) ? null : path,
    );
  }
}
