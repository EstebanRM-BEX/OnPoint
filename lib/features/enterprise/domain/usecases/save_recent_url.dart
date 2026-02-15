import 'package:fpdart/fpdart.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/recent_url.dart';
import '../repositories/enterprise_repository.dart';

@lazySingleton
class SaveRecentUrl implements UseCase<void, SaveRecentUrlParams> {
  final EnterpriseRepository repository;

  SaveRecentUrl(this.repository);

  @override
  Future<Either<Failure, void>> call(SaveRecentUrlParams params) async {
    return await repository.saveRecentUrl(params.recentUrl);
  }
}

class SaveRecentUrlParams extends Equatable {
  final RecentUrl recentUrl;

  const SaveRecentUrlParams({required this.recentUrl});

  @override
  List<Object?> get props => [recentUrl];
}
