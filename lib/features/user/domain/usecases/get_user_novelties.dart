import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_novelty.dart';
import '../repositories/user_repository.dart';

@lazySingleton
class GetUserNovelties implements UseCase<List<Novedad>, NoParams> {
  final UserRepository repository;

  GetUserNovelties(this.repository);

  @override
  Future<Either<Failure, List<Novedad>>> call(NoParams params) async {
    return await repository.getNovelties();
  }
}
