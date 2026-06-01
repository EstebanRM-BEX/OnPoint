import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/repositories/pick_scan_repository.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';

class GetProductsForEditParams {
  final int pickId;

  const GetProductsForEditParams({required this.pickId});
}

@lazySingleton
class GetProductsForEditUseCase
    implements UseCase<List<ProductsBatch>, GetProductsForEditParams> {
  final PickScanRepository repository;

  GetProductsForEditUseCase(this.repository);

  @override
  Future<Either<Failure, List<ProductsBatch>>> call(
          GetProductsForEditParams params) =>
      repository.getProductsForEdit(params.pickId);
}
