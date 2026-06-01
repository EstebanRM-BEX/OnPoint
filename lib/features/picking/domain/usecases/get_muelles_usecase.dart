import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/repositories/pick_scan_repository.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/submeuelle_model.dart';

class GetMuellesParams {
  final int muelleId;

  const GetMuellesParams({required this.muelleId});
}

@lazySingleton
class GetMuellesUseCase implements UseCase<List<Muelles>, GetMuellesParams> {
  final PickScanRepository repository;

  GetMuellesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Muelles>>> call(GetMuellesParams params) =>
      repository.getMuelles(params.muelleId);
}
