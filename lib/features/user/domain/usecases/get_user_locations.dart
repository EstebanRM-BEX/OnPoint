import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/user_repository.dart';

@lazySingleton
class GetUserLocations
    implements UseCase<int, GetUserLocationsParams> {
  final UserRepository repository;

  GetUserLocations(this.repository);

  @override
  Future<Either<Failure, int>> call(
    GetUserLocationsParams params,
  ) async {
    return await repository.getUserLocations(completa: params.completa);
  }
}

class GetUserLocationsParams {
  /// Ignora la marca del sync incremental y descarga todo.
  final bool completa;
  const GetUserLocationsParams({this.completa = false});
}
