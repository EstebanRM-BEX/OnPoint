import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/repositories/pick_scan_repository.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';

class GetBarcodesProductParams {
  final int pickId;
  final int productId;
  final int idMove;

  const GetBarcodesProductParams({
    required this.pickId,
    required this.productId,
    required this.idMove,
  });
}

@lazySingleton
class GetBarcodesProductUseCase
    implements UseCase<List<Barcodes>, GetBarcodesProductParams> {
  final PickScanRepository repository;

  GetBarcodesProductUseCase(this.repository);

  @override
  Future<Either<Failure, List<Barcodes>>> call(
          GetBarcodesProductParams params) =>
      repository.getBarcodesProduct(
          params.pickId, params.productId, params.idMove);
}
