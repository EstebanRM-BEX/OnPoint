import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/info_rapida/domain/entities/catalogo_info.dart';
import 'package:wms_app/features/info_rapida/domain/repositories/info_rapida_repository.dart';

class BuscarCatalogoUbicacionesParams extends Equatable {
  /// Texto en nombre o barcode (vacío = todas).
  final String query;

  /// Solo las del almacén con este nombre (sin distinguir mayúsculas).
  final String? almacen;
  final int limit;
  final int offset;

  const BuscarCatalogoUbicacionesParams({
    this.query = '',
    this.almacen,
    required this.limit,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [query, almacen, limit, offset];
}

/// Página del catálogo de ubicaciones ordenada por nombre (consulta SQLite,
/// sin cargar las ~19 mil ubicaciones en memoria).
@lazySingleton
class BuscarCatalogoUbicacionesUseCase
    implements
        UseCase<List<UbicacionCatalogo>, BuscarCatalogoUbicacionesParams> {
  final InfoRapidaRepository repository;

  BuscarCatalogoUbicacionesUseCase(this.repository);

  @override
  Future<Either<Failure, List<UbicacionCatalogo>>> call(
    BuscarCatalogoUbicacionesParams params,
  ) async {
    return await repository.buscarCatalogoUbicaciones(
      query: params.query,
      almacen: params.almacen,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
