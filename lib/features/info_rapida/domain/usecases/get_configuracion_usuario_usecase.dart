import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/info_rapida/domain/entities/config_info_rapida_usuario.dart';
import 'package:wms_app/features/info_rapida/domain/repositories/info_rapida_repository.dart';

class GetConfiguracionUsuarioParams extends Equatable {
  final int? userId;

  const GetConfiguracionUsuarioParams({this.userId});

  @override
  List<Object?> get props => [userId];
}

@lazySingleton
class GetConfiguracionUsuarioUseCase
    implements
        UseCase<ConfigInfoRapidaUsuario, GetConfiguracionUsuarioParams> {
  final InfoRapidaRepository repository;

  GetConfiguracionUsuarioUseCase(this.repository);

  @override
  Future<Either<Failure, ConfigInfoRapidaUsuario>> call(
    GetConfiguracionUsuarioParams params,
  ) async {
    return await repository.getConfiguracionUsuario(userId: params.userId);
  }
}
