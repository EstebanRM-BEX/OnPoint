import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/info_rapida/domain/repositories/info_rapida_repository.dart';

/// Propietarios distintos del catálogo local, para el filtro de productos.
@lazySingleton
class GetPropietariosCatalogoUseCase implements UseCase<List<String>, NoParams> {
  final InfoRapidaRepository repository;

  GetPropietariosCatalogoUseCase(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(NoParams params) async {
    return await repository.getPropietariosCatalogo();
  }
}
