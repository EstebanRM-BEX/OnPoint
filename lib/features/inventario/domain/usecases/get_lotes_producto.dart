// lib/features/inventario/domain/usecases/get_lotes_producto.dart

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/inventario/domain/entities/lote_producto_inventario.dart';
import 'package:wms_app/features/inventario/domain/repositories/inventario_repository.dart';

@lazySingleton
class GetLotesProducto
    implements UseCase<List<LoteProductoInventario>, GetLotesProductoParams> {
  final InventarioRepository repository;

  GetLotesProducto(this.repository);

  @override
  Future<Either<Failure, List<LoteProductoInventario>>> call(
      GetLotesProductoParams params) {
    return repository.getLotesProducto(params.productId);
  }
}

class GetLotesProductoParams {
  final int productId;

  const GetLotesProductoParams({required this.productId});
}
