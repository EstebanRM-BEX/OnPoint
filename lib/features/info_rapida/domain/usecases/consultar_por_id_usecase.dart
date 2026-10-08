import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/domain/repositories/info_rapida_repository.dart';

class ConsultarPorIdParams extends Equatable {
  final int id;
  final bool isProduct;

  const ConsultarPorIdParams({
    required this.id,
    required this.isProduct,
  });

  @override
  List<Object?> get props => [id, isProduct];
}

@lazySingleton
class ConsultarPorIdUseCase
    implements UseCase<InfoRapida, ConsultarPorIdParams> {
  final InfoRapidaRepository repository;

  ConsultarPorIdUseCase(this.repository);

  @override
  Future<Either<Failure, InfoRapida>> call(
    ConsultarPorIdParams params,
  ) async {
    return await repository.consultarPorId(
      id: params.id,
      isProduct: params.isProduct,
    );
  }
}
