import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/lote_producto.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/repositories/recepcion_multiusuario_repository.dart';

class CreateLoteParams {
  final int productId;
  final String nombreLote;
  final String fechaVencimiento;
  final bool priorityExpiration;

  const CreateLoteParams({
    required this.productId,
    required this.nombreLote,
    required this.fechaVencimiento,
    this.priorityExpiration = false,
  });
}

@lazySingleton
class CreateLoteUseCase implements UseCase<LoteProducto, CreateLoteParams> {
  final RecepcionMultiusuarioRepository repository;

  CreateLoteUseCase(this.repository);

  @override
  Future<Either<Failure, LoteProducto>> call(CreateLoteParams params) async {
    return await repository.createLote(
      productId: params.productId,
      nombreLote: params.nombreLote,
      fechaVencimiento: params.fechaVencimiento,
      priorityExpiration: params.priorityExpiration,
      isLoadinDialog: false,
    );
  }
}
