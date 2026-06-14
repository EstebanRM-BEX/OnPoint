// lib/features/inventario/domain/usecases/crear_lote_inventario.dart

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/inventario/domain/entities/resultado_crear_lote.dart';
import 'package:wms_app/features/inventario/domain/repositories/inventario_repository.dart';

@lazySingleton
class CrearLoteInventario
    implements UseCase<ResultadoCrearLote, CrearLoteInventarioParams> {
  final InventarioRepository repository;

  CrearLoteInventario(this.repository);

  @override
  Future<Either<Failure, ResultadoCrearLote>> call(
      CrearLoteInventarioParams params) {
    return repository.crearLoteInventario(
      productId: params.productId,
      nameLote: params.nameLote,
      fechaCaducidad: params.fechaCaducidad,
      priorityExpiration: params.priorityExpiration,
    );
  }
}

class CrearLoteInventarioParams {
  final int productId;
  final String nameLote;
  final String fechaCaducidad;
  final bool priorityExpiration;

  const CrearLoteInventarioParams({
    required this.productId,
    required this.nameLote,
    required this.fechaCaducidad,
    required this.priorityExpiration,
  });
}
