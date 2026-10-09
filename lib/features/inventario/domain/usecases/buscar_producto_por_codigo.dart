// lib/features/inventario/domain/usecases/buscar_producto_por_codigo.dart

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/inventario/domain/entities/producto_inventario.dart';
import 'package:wms_app/features/inventario/domain/repositories/inventario_repository.dart';

/// Producto escaneado: por barcode, código o barcode alterno/de empaque.
/// Devuelve null si no existe en el catálogo local.
@lazySingleton
class BuscarProductoPorCodigo implements UseCase<ProductoInventario?, String> {
  final InventarioRepository repository;

  BuscarProductoPorCodigo(this.repository);

  @override
  Future<Either<Failure, ProductoInventario?>> call(String codigo) {
    return repository.buscarProductoPorCodigo(codigo);
  }
}
