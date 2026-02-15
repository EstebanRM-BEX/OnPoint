import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/home/domain/entities/app_version.dart';
import 'package:wms_app/features/home/domain/repositories/home_repository.dart';

/// Use case for getting the latest app version.
///
/// This encapsulates the business logic for fetching app version information.
@lazySingleton
class GetAppVersion implements UseCase<AppVersion, NoParams> {
  final HomeRepository repository;

  GetAppVersion(this.repository);

  @override
  Future<Either<Failure, AppVersion>> call(NoParams params) async {
    return await repository.getAppVersion();
  }
}
