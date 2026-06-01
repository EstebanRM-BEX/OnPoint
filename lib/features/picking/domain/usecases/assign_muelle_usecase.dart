import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/repositories/pick_scan_repository.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/submeuelle_model.dart';

class AssignMuelleParams {
  final List<ProductsBatch> products;
  final Muelles muelle;
  final bool isOccupied;
  final int currentBatchId;

  const AssignMuelleParams({
    required this.products,
    required this.muelle,
    required this.isOccupied,
    required this.currentBatchId,
  });
}

@lazySingleton
class AssignMuelleUseCase implements UseCase<String, AssignMuelleParams> {
  final PickScanRepository repository;

  AssignMuelleUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(AssignMuelleParams params) =>
      repository.assignMuelle(params.products, params.muelle, params.isOccupied,
          params.currentBatchId);
}
