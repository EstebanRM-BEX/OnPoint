import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/picking_cluster_repository.dart';

@lazySingleton
class ViewProductImageUseCase
    implements UseCase<String, ViewProductImageParams> {
  final IPickingClusterRepository repository;

  ViewProductImageUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(ViewProductImageParams params) async {
    return await repository.viewProductImage(
        params.idProduct, params.isLoadinDialog);
  }
}

class ViewProductImageParams {
  final int idProduct;
  final bool isLoadinDialog;

  ViewProductImageParams({required this.idProduct, this.isLoadinDialog = true});
}
