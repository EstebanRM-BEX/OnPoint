import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida_params.dart';
import 'package:wms_app/features/info_rapida/domain/entities/transfer_results.dart';
import 'package:wms_app/features/info_rapida/domain/repositories/info_rapida_repository.dart';

@lazySingleton
class CrearTransferenciaIndividualUseCase
    implements
        UseCase<TransferenciaIndividualResult,
            CrearTransferenciaIndividualParams> {
  final InfoRapidaRepository repository;

  CrearTransferenciaIndividualUseCase(this.repository);

  @override
  Future<Either<Failure, TransferenciaIndividualResult>> call(
    CrearTransferenciaIndividualParams params,
  ) async {
    return await repository.crearTransferenciaIndividual(params);
  }
}
