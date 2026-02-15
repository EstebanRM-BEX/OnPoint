import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/home/domain/entities/user_data.dart';
import 'package:wms_app/features/home/domain/repositories/home_repository.dart';

/// Use case for getting user data from local storage.
@lazySingleton
class GetUserData implements UseCase<UserData, NoParams> {
  final HomeRepository repository;

  GetUserData(this.repository);

  @override
  Future<Either<Failure, UserData>> call(NoParams params) async {
    return await repository.getUserData();
  }
}
