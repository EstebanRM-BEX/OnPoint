import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/info_rapida/domain/entities/catalogo_info.dart';
import 'package:wms_app/features/info_rapida/domain/repositories/info_rapida_repository.dart';

class GetCatalogoProductosParams extends Equatable {
  final bool forceRefresh;

  const GetCatalogoProductosParams({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

@lazySingleton
class GetCatalogoProductosUseCase
    implements UseCase<List<ProductoCatalogo>, GetCatalogoProductosParams> {
  final InfoRapidaRepository repository;

  GetCatalogoProductosUseCase(this.repository);

  @override
  Future<Either<Failure, List<ProductoCatalogo>>> call(
    GetCatalogoProductosParams params,
  ) async {
    return await repository.getCatalogoProductos(
      forceRefresh: params.forceRefresh,
    );
  }
}
