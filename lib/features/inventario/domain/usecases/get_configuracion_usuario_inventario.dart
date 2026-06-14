// lib/features/inventario/domain/usecases/get_configuracion_usuario_inventario.dart

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/inventario/domain/repositories/inventario_repository.dart';
import 'package:wms_app/features/user/domain/entities/user_configuration.dart';

@lazySingleton
class GetConfiguracionUsuarioInventario
    implements UseCase<UserConfiguration, NoParams> {
  final InventarioRepository repository;

  GetConfiguracionUsuarioInventario(this.repository);

  @override
  Future<Either<Failure, UserConfiguration>> call(NoParams params) {
    return repository.getConfiguracionUsuarioInventario();
  }
}
