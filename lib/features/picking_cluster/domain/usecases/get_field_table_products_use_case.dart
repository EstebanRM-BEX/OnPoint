import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import '../repositories/picking_cluster_repository.dart';

@lazySingleton
class GetFieldTableProductsUseCase
    implements UseCase<String, GetFieldTableProductsParams> {
  final IPickingClusterRepository repository;

  GetFieldTableProductsUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(
      GetFieldTableProductsParams params) async {
    return await repository.getFieldTableProducts(
      params.batchId,
      params.productId,
      params.moveId,
      params.field,
      params.type,
    );
  }
}

class GetFieldTableProductsParams {
  final int batchId;
  final int productId;
  final int moveId;
  final String field;
  final String type;

  GetFieldTableProductsParams({
    required this.batchId,
    required this.productId,
    required this.moveId,
    required this.field,
    required this.type,
  });
}
