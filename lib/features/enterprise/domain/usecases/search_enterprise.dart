import 'package:fpdart/fpdart.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/enterprise_info.dart';
import '../repositories/enterprise_repository.dart';

@lazySingleton
class SearchEnterprise
    implements UseCase<EnterpriseInfo, SearchEnterpriseParams> {
  final EnterpriseRepository repository;

  SearchEnterprise(this.repository);

  @override
  Future<Either<Failure, EnterpriseInfo>> call(
      SearchEnterpriseParams params) async {
    return await repository.searchEnterprise(params.url);
  }
}

class SearchEnterpriseParams extends Equatable {
  final String url;

  const SearchEnterpriseParams({required this.url});

  @override
  List<Object?> get props => [url];
}
