import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_lote_producto.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/repositories/transferencia_multiusuario_repository.dart';

class FetchTransferenciaLotesProductoParams {
  final int productId;
  final bool isLoadinDialog;

  const FetchTransferenciaLotesProductoParams({
    required this.productId,
    this.isLoadinDialog = false,
  });
}

@lazySingleton
class FetchTransferenciaLotesProductoUseCase
    implements
        UseCase<
          List<TransferenciaLoteProducto>,
          FetchTransferenciaLotesProductoParams
        > {
  final TransferenciaMultiusuarioRepository repository;

  FetchTransferenciaLotesProductoUseCase(this.repository);

  @override
  Future<Either<Failure, List<TransferenciaLoteProducto>>> call(
    FetchTransferenciaLotesProductoParams params,
  ) async {
    return await repository.fetchLotesProduct(
      productId: params.productId,
      isLoadinDialog: params.isLoadinDialog,
    );
  }
}
