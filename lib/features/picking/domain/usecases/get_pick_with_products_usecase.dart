import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/repositories/picking_repository.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/PickhWithProducts_model.dart';

class GetPickWithProductsParams {
  final int pickId;
  const GetPickWithProductsParams({required this.pickId});
}

/// Use case for retrieving a pick with its associated product lines.
@lazySingleton
class GetPickWithProductsUseCase
    implements UseCase<PickWithProducts, GetPickWithProductsParams> {
  final PickingRepository repository;

  GetPickWithProductsUseCase(this.repository);

  @override
  Future<Either<Failure, PickWithProducts>> call(
      GetPickWithProductsParams params) async {
    return await repository.getPickWithProducts(params.pickId);
  }
}
