import 'package:fpdart/fpdart.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/enterprise_repository.dart';

@lazySingleton
class DeleteRecentUrl implements UseCase<void, DeleteRecentUrlParams> {
  final EnterpriseRepository repository;

  DeleteRecentUrl(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteRecentUrlParams params) async {
    return await repository.deleteRecentUrl(params.url);
  }
}

class DeleteRecentUrlParams extends Equatable {
  final String url;

  const DeleteRecentUrlParams({required this.url});

  @override
  List<Object?> get props => [url];
}
