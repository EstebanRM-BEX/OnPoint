import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/lote_producto.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/repositories/recepcion_multiusuario_repository.dart';

class FetchLotesProductoParams {
  final int productId;
  final bool isLoadinDialog;

  const FetchLotesProductoParams({
    required this.productId,
    this.isLoadinDialog = false,
  });
}

@lazySingleton
class FetchLotesProductoUseCase
    implements UseCase<List<LoteProducto>, FetchLotesProductoParams> {
  final RecepcionMultiusuarioRepository repository;

  FetchLotesProductoUseCase(this.repository);

  @override
  Future<Either<Failure, List<LoteProducto>>> call(
    FetchLotesProductoParams params,
  ) async {
    return await repository.fetchLotesProduct(
      productId: params.productId,
      isLoadinDialog: params.isLoadinDialog,
    );
  }
}
