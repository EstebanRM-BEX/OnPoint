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
    return repository.syncProductosInventario(
      params.isLoadingDialog,
      onProgress: params.onProgress,
      completa: params.completa,
    );
  }
}

class SyncProductosParams {
  final bool isLoadingDialog;
  final void Function(String phase, int processed, int total)? onProgress;

  /// Ignora la marca de la última sync y descarga todo (botón manual del
  /// perfil: el incremental no arregla datos locales desincronizados).
  final bool completa;

  const SyncProductosParams({
    required this.isLoadingDialog,
    this.onProgress,
    this.completa = false,
  });
}
