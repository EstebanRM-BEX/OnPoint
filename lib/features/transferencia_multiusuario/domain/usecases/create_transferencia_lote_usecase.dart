import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_lote_producto.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/repositories/transferencia_multiusuario_repository.dart';

class CreateTransferenciaLoteParams {
  final int productId;
  final String nombreLote;
  final String fechaVencimiento;
  final bool priorityExpiration;

  const CreateTransferenciaLoteParams({
    required this.productId,
    required this.nombreLote,
    required this.fechaVencimiento,
    this.priorityExpiration = false,
  });
}

@lazySingleton
class CreateTransferenciaLoteUseCase
    implements
        UseCase<TransferenciaLoteProducto, CreateTransferenciaLoteParams> {
  final TransferenciaMultiusuarioRepository repository;

  CreateTransferenciaLoteUseCase(this.repository);

  @override
  Future<Either<Failure, TransferenciaLoteProducto>> call(
    CreateTransferenciaLoteParams params,
  ) async {
    return await repository.createLote(
      productId: params.productId,
      nombreLote: params.nombreLote,
      fechaVencimiento: params.fechaVencimiento,
      priorityExpiration: params.priorityExpiration,
      isLoadinDialog: false,
    );
  }
}
