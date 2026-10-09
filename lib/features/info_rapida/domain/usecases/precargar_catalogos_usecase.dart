import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/info_rapida/domain/repositories/info_rapida_repository.dart';

/// Precarga en segundo plano el catálogo de ubicaciones al entrar a
/// Información Rápida (los productos se consultan en SQLite al buscar).
@lazySingleton
class PrecargarCatalogosUseCase implements UseCase<Unit, NoParams> {
  final InfoRapidaRepository repository;

  PrecargarCatalogosUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    return await repository.precargarCatalogos();
  }
}
