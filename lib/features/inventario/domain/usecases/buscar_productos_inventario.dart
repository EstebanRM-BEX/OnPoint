// lib/features/inventario/domain/usecases/buscar_productos_inventario.dart

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/inventario/domain/entities/producto_inventario.dart';
import 'package:wms_app/features/inventario/domain/repositories/inventario_repository.dart';

class BuscarProductosParams {
  final String query;

  /// Ubicación actual: sus productos salen primero.
  final int? ubicacionId;
  final int limit;
  final int offset;

  const BuscarProductosParams({
    required this.query,
    this.ubicacionId,
    required this.limit,
    this.offset = 0,
  });
}

/// Página de productos del catálogo local (consulta SQLite, sin cargarlo
/// completo en memoria).
@lazySingleton
class BuscarProductosInventario
    implements UseCase<List<ProductoInventario>, BuscarProductosParams> {
  final InventarioRepository repository;

  BuscarProductosInventario(this.repository);

  @override
  Future<Either<Failure, List<ProductoInventario>>> call(
    BuscarProductosParams params,
  ) {
    return repository.buscarProductos(
      query: params.query,
      ubicacionId: params.ubicacionId,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
