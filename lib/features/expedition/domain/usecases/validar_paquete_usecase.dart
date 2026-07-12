import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/expedition/domain/repositories/expedition_repository.dart';

class ValidarPaqueteParams {
  final int expeditionId;
  final int packingId;

  const ValidarPaqueteParams({
    required this.expeditionId,
    required this.packingId,
  });
}

@lazySingleton
class ValidarPaqueteUseCase implements UseCase<Unit, ValidarPaqueteParams> {
  final ExpeditionRepository repository;

  ValidarPaqueteUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(ValidarPaqueteParams params) async {
    return await repository.validarPaquete(
      expeditionId: params.expeditionId,
      packingId: params.packingId,
    );
  }
}
