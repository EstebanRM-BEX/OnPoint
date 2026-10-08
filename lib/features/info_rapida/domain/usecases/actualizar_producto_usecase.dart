import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida_params.dart';
import 'package:wms_app/features/info_rapida/domain/repositories/info_rapida_repository.dart';

@lazySingleton
class ActualizarProductoUseCase
    implements UseCase<ProductoInfo, ActualizarProductoParams> {
  final InfoRapidaRepository repository;

  ActualizarProductoUseCase(this.repository);

  @override
  Future<Either<Failure, ProductoInfo>> call(
    ActualizarProductoParams params,
  ) async {
    return await repository.actualizarProducto(params);
  }
}
