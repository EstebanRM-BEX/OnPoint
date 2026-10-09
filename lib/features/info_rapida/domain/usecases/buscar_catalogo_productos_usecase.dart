import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/info_rapida/domain/entities/catalogo_info.dart';
import 'package:wms_app/features/info_rapida/domain/repositories/info_rapida_repository.dart';

class BuscarCatalogoProductosParams extends Equatable {
  final String query;
  final String? propietario;
  final int limit;
  final int offset;

  const BuscarCatalogoProductosParams({
    this.query = '',
    this.propietario,
    required this.limit,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [query, propietario, limit, offset];
}

/// Página del catálogo de productos (consulta SQLite, sin cargarlo completo
/// en memoria).
@lazySingleton
class BuscarCatalogoProductosUseCase
    implements UseCase<List<ProductoCatalogo>, BuscarCatalogoProductosParams> {
  final InfoRapidaRepository repository;

  BuscarCatalogoProductosUseCase(this.repository);

  @override
  Future<Either<Failure, List<ProductoCatalogo>>> call(
    BuscarCatalogoProductosParams params,
  ) async {
    return await repository.buscarCatalogoProductos(
      query: params.query,
      propietario: params.propietario,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
