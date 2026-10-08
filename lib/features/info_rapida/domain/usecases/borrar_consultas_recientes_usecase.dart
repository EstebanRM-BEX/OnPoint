import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/info_rapida/domain/repositories/info_rapida_repository.dart';

@lazySingleton
class BorrarConsultasRecientesUseCase implements UseCase<Unit, NoParams> {
  final InfoRapidaRepository repository;

  BorrarConsultasRecientesUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    return await repository.borrarConsultasRecientes();
  }
}
