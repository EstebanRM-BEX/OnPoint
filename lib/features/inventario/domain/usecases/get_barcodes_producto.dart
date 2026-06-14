// lib/features/inventario/domain/usecases/get_barcodes_producto.dart

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/inventario/domain/entities/barcode_producto.dart';
import 'package:wms_app/features/inventario/domain/repositories/inventario_repository.dart';

@lazySingleton
class GetBarcodesProducto
    implements UseCase<List<BarcodeProducto>, GetBarcodesProductoParams> {
  final InventarioRepository repository;

  GetBarcodesProducto(this.repository);

  @override
  Future<Either<Failure, List<BarcodeProducto>>> call(
      GetBarcodesProductoParams params) {
    return repository.getBarcodesProducto(params.productId);
  }
}

class GetBarcodesProductoParams {
  final int productId;

  const GetBarcodesProductoParams({required this.productId});
}
