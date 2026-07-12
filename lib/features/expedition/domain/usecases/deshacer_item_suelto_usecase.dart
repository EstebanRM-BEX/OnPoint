import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/expedition/domain/repositories/expedition_repository.dart';

class DeshacerItemSueltoParams {
  final int expeditionId;
  final int packingId;

  const DeshacerItemSueltoParams({
    required this.expeditionId,
    required this.packingId,
  });
}

@lazySingleton
class DeshacerItemSueltoUseCase
    implements UseCase<Unit, DeshacerItemSueltoParams> {
  final ExpeditionRepository repository;

  DeshacerItemSueltoUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(DeshacerItemSueltoParams params) async {
    return await repository.deshacerItemSuelto(
      expeditionId: params.expeditionId,
      packingId: params.packingId,
    );
  }
}
