// lib/features/inventario/domain/usecases/get_productos_count.dart

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/inventario/domain/repositories/inventario_repository.dart';

@lazySingleton
class GetProductosCount implements UseCase<int, NoParams> {
  final InventarioRepository repository;

  GetProductosCount(this.repository);

  @override
  Future<Either<Failure, int>> call(NoParams params) {
    return repository.getProductosCount();
  }
}
