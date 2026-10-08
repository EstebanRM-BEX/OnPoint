import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/info_rapida/domain/entities/recent_query.dart';
import 'package:wms_app/features/info_rapida/domain/repositories/info_rapida_repository.dart';

@lazySingleton
class GetConsultasRecientesUseCase
    implements UseCase<List<RecentQuery>, NoParams> {
  final InfoRapidaRepository repository;

  GetConsultasRecientesUseCase(this.repository);

  @override
  Future<Either<Failure, List<RecentQuery>>> call(NoParams params) async {
    return await repository.getConsultasRecientes();
  }
}
