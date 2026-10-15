import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_validacion.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/repositories/recepcion_multiusuario_repository.dart';

class ValidarRecepcionMultiParams {
  final int sessionId;
  final bool crearBackorder;

  /// null en el primer intento; true/false tras preguntar por lotes vencidos.
  final bool? confirmarCaducados;

  const ValidarRecepcionMultiParams({
    required this.sessionId,
    required this.crearBackorder,
    this.confirmarCaducados,
  });
}

@lazySingleton
class ValidarRecepcionMultiUseCase
    implements UseCase<RecepcionValidacion, ValidarRecepcionMultiParams> {
  final RecepcionMultiusuarioRepository repository;

  ValidarRecepcionMultiUseCase(this.repository);

  @override
  Future<Either<Failure, RecepcionValidacion>> call(
    ValidarRecepcionMultiParams params,
  ) async {
    return await repository.validarRecepcion(
      sessionId: params.sessionId,
      crearBackorder: params.crearBackorder,
      confirmarCaducados: params.confirmarCaducados,
    );
  }
}
