import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_location.dart';
import '../repositories/user_repository.dart';

@lazySingleton
class GetUserLocations
    implements UseCase<List<UserLocation>, GetUserLocationsParams> {
  final UserRepository repository;

  GetUserLocations(this.repository);

  @override
  Future<Either<Failure, List<UserLocation>>> call(
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
