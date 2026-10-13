// lib/features/inventario/domain/usecases/buscar_ubicaciones_inventario.dart

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/inventario/domain/entities/ubicacion_inventario.dart';
import 'package:wms_app/features/inventario/domain/repositories/inventario_repository.dart';

class BuscarUbicacionesParams {
  /// Texto en nombre o barcode (vacío = todas).
  final String query;

  /// Solo ubicaciones cuyo almacén contiene este texto (menú de almacenes).
  final String? almacenContiene;
  final int limit;
  final int offset;

  const BuscarUbicacionesParams({
    this.query = '',
    this.almacenContiene,
    required this.limit,
    this.offset = 0,
  });
}

/// Página de ubicaciones de la tabla local, ordenada por nombre (consulta
/// SQLite, sin cargar las ~19 mil ubicaciones en memoria).
@lazySingleton
class BuscarUbicacionesInventario
    implements UseCase<List<UbicacionInventario>, BuscarUbicacionesParams> {
  final InventarioRepository repository;

  BuscarUbicacionesInventario(this.repository);

  @override
  Future<Either<Failure, List<UbicacionInventario>>> call(
    BuscarUbicacionesParams params,
  ) {
    return repository.buscarUbicaciones(
      query: params.query,
      almacenContiene: params.almacenContiene,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
