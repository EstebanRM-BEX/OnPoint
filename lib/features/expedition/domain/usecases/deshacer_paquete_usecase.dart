import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/expedition/domain/repositories/expedition_repository.dart';

class DeshacerPaqueteParams {
  final int expeditionId;
  final int packingId;

  const DeshacerPaqueteParams({
    required this.expeditionId,
    required this.packingId,
  });
}

@lazySingleton
class DeshacerPaqueteUseCase implements UseCase<Unit, DeshacerPaqueteParams> {
  final ExpeditionRepository repository;

  DeshacerPaqueteUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(DeshacerPaqueteParams params) async {
    return await repository.deshacerPaquete(
      expeditionId: params.expeditionId,
      packingId: params.packingId,
    );
  }
}
