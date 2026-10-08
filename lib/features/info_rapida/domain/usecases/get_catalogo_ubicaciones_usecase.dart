import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/info_rapida/domain/entities/catalogo_info.dart';
import 'package:wms_app/features/info_rapida/domain/repositories/info_rapida_repository.dart';

class GetCatalogoUbicacionesParams extends Equatable {
  final bool forceRefresh;

  const GetCatalogoUbicacionesParams({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

@lazySingleton
class GetCatalogoUbicacionesUseCase
    implements UseCase<List<UbicacionCatalogo>, GetCatalogoUbicacionesParams> {
  final InfoRapidaRepository repository;

  GetCatalogoUbicacionesUseCase(this.repository);

  @override
  Future<Either<Failure, List<UbicacionCatalogo>>> call(
    GetCatalogoUbicacionesParams params,
  ) async {
    return await repository.getCatalogoUbicaciones(
      forceRefresh: params.forceRefresh,
    );
  }
}
