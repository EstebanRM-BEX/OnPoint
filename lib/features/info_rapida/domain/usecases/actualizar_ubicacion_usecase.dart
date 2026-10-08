import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida_params.dart';
import 'package:wms_app/features/info_rapida/domain/repositories/info_rapida_repository.dart';

@lazySingleton
class ActualizarUbicacionUseCase
    implements UseCase<UbicacionInfo, ActualizarUbicacionParams> {
  final InfoRapidaRepository repository;

  ActualizarUbicacionUseCase(this.repository);

  @override
  Future<Either<Failure, UbicacionInfo>> call(
    ActualizarUbicacionParams params,
  ) async {
    return await repository.actualizarUbicacion(params);
  }
}
