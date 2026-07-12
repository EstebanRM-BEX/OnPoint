import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/expedition/domain/repositories/expedition_repository.dart';

class ValidarMultipleParams {
  final int expeditionId;
  final List<int> packingIdsPaquetes;
  final List<int> packingIdsItemsSueltos;

  const ValidarMultipleParams({
    required this.expeditionId,
    required this.packingIdsPaquetes,
    required this.packingIdsItemsSueltos,
  });
}

/// Valida de una sola vez varios paquetes y/o productos sueltos de la misma
/// expedición. Requiere el permiso `allow_validate_multiple`.
@lazySingleton
class ValidarMultipleUseCase implements UseCase<Unit, ValidarMultipleParams> {
  final ExpeditionRepository repository;

  ValidarMultipleUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(ValidarMultipleParams params) async {
    return await repository.validarMultiple(
      expeditionId: params.expeditionId,
      packingIdsPaquetes: params.packingIdsPaquetes,
      packingIdsItemsSueltos: params.packingIdsItemsSueltos,
    );
  }
}
