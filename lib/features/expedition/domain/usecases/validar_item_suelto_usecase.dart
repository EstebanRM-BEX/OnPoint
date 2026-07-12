import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/expedition/domain/repositories/expedition_repository.dart';

class ValidarItemSueltoParams {
  final int expeditionId;
  final int packingId;

  const ValidarItemSueltoParams({
    required this.expeditionId,
    required this.packingId,
  });
}

@lazySingleton
class ValidarItemSueltoUseCase
    implements UseCase<Unit, ValidarItemSueltoParams> {
  final ExpeditionRepository repository;

  ValidarItemSueltoUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(ValidarItemSueltoParams params) async {
    return await repository.validarItemSuelto(
      expeditionId: params.expeditionId,
      packingId: params.packingId,
    );
  }
}
