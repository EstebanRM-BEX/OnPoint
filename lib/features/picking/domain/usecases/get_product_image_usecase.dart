import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/repositories/pick_scan_repository.dart';

class GetProductImageParams {
  final int productId;

  const GetProductImageParams({required this.productId});
}

@lazySingleton
class GetProductImageUseCase
    implements UseCase<String, GetProductImageParams> {
  final PickScanRepository repository;

  GetProductImageUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(GetProductImageParams params) =>
      repository.getProductImageUrl(params.productId);
}
