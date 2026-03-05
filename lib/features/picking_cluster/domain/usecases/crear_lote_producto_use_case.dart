import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import '../entities/lote_producto.dart';
import '../repositories/picking_cluster_repository.dart';

@lazySingleton
class CrearLoteProductoUseCase
    implements UseCase<LoteProducto, CrearLoteProductoParams> {
  final IPickingClusterRepository repository;

  CrearLoteProductoUseCase(this.repository);

  @override
  Future<Either<Failure, LoteProducto>> call(
      CrearLoteProductoParams params) async {
    return await repository.crearLoteProducto(
      params.productId,
      params.name,
      params.expirationDate,
    );
  }
}

class CrearLoteProductoParams {
  final int productId;
  final String name;
  final String? expirationDate;

  CrearLoteProductoParams({
    required this.productId,
    required this.name,
    this.expirationDate,
  });
}
