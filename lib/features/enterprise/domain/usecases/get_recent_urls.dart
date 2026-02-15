import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/recent_url.dart';
import '../repositories/enterprise_repository.dart';

@lazySingleton
class GetRecentUrls implements UseCase<List<RecentUrl>, NoParams> {
  final EnterpriseRepository repository;

  GetRecentUrls(this.repository);

  @override
  Future<Either<Failure, List<RecentUrl>>> call(NoParams params) async {
    return await repository.getRecentUrls();
  }
}
