import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import '../entities/lote_producto.dart';
import '../repositories/picking_cluster_repository.dart';

@lazySingleton
class GetLotesProductoUseCase
    implements UseCase<List<LoteProducto>, GetLotesProductoParams> {
  final IPickingClusterRepository repository;

  GetLotesProductoUseCase(this.repository);

  @override
  Future<Either<Failure, List<LoteProducto>>> call(
      GetLotesProductoParams params) async {
    return await repository.getLotesProducto(params.productId);
  }
}

class GetLotesProductoParams {
  final int productId;

  GetLotesProductoParams({required this.productId});
}
