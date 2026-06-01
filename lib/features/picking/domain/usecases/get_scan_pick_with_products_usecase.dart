import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/repositories/pick_scan_repository.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/PickhWithProducts_model.dart';

class GetScanPickWithProductsParams {
  final int pickId;

  const GetScanPickWithProductsParams({required this.pickId});
}

@lazySingleton
class GetScanPickWithProductsUseCase
    implements UseCase<PickWithProducts, GetScanPickWithProductsParams> {
  final PickScanRepository repository;

  GetScanPickWithProductsUseCase(this.repository);

  @override
  Future<Either<Failure, PickWithProducts>> call(
          GetScanPickWithProductsParams params) =>
      repository.getPickWithProducts(params.pickId);
}
