import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/info_rapida/domain/entities/recent_query.dart';
import 'package:wms_app/features/info_rapida/domain/repositories/info_rapida_repository.dart';

class GuardarConsultaRecienteParams extends Equatable {
  final RecentQuery query;

  const GuardarConsultaRecienteParams({required this.query});

  @override
  List<Object?> get props => [query];
}

@lazySingleton
class GuardarConsultaRecienteUseCase
    implements UseCase<Unit, GuardarConsultaRecienteParams> {
  final InfoRapidaRepository repository;

  GuardarConsultaRecienteUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(
    GuardarConsultaRecienteParams params,
  ) async {
    return await repository.guardarConsultaReciente(params.query);
  }
}
