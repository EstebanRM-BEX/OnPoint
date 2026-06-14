// lib/features/inventario/domain/usecases/sync_productos_inventario.dart

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/inventario/domain/repositories/inventario_repository.dart';

@lazySingleton
class SyncProductosInventario implements UseCase<void, SyncProductosParams> {
  final InventarioRepository repository;

  SyncProductosInventario(this.repository);

  @override
  Future<Either<Failure, void>> call(SyncProductosParams params) {
    return repository.syncProductosInventario(params.isLoadingDialog);
  }
}

class SyncProductosParams {
  final bool isLoadingDialog;

  const SyncProductosParams({required this.isLoadingDialog});
}
