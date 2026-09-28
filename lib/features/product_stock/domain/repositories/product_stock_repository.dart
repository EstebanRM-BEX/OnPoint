import 'package:fpdart/fpdart.dart';
import 'package:wms_app/core/error/failures.dart';

import '../entities/product_stock_info.dart';

abstract class ProductStockRepository {
  Future<Either<Failure, ProductStockInfo>> getProductStockInfo(int productId);
}
