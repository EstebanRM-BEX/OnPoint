import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';

import '../entities/product_stock_info.dart';
import '../repositories/product_stock_repository.dart';

@lazySingleton
class GetProductStockInfo implements UseCase<ProductStockInfo, int> {
  final ProductStockRepository repository;

  GetProductStockInfo(this.repository);

  /// [productId]: id del producto en Odoo.
  @override
  Future<Either<Failure, ProductStockInfo>> call(int productId) {
    return repository.getProductStockInfo(productId);
  }
}
