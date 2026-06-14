// lib/features/inventario/domain/usecases/get_productos_local.dart

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/inventario/domain/entities/producto_inventario.dart';
import 'package:wms_app/features/inventario/domain/repositories/inventario_repository.dart';

@lazySingleton
class GetProductosLocal implements UseCase<List<ProductoInventario>, NoParams> {
  final InventarioRepository repository;

  GetProductosLocal(this.repository);

  @override
  Future<Either<Failure, List<ProductoInventario>>> call(NoParams params) {
    return repository.getProductosLocal();
  }
}
