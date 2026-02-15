import 'package:fpdart/fpdart.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/home/domain/entities/app_version.dart';
import 'package:wms_app/features/home/domain/entities/user_data.dart';
import 'package:wms_app/features/user/domain/entities/user_configuration.dart';

/// Repository interface for home feature.
/// This is an abstraction that will be implemented in the data layer.
abstract class HomeRepository {
  /// Fetches the latest app version from the server.
  Future<Either<Failure, AppVersion>> getAppVersion();

  /// Retrieves user data from local storage.
  Future<Either<Failure, UserData>> getUserData();

  /// Retrieves user configurations from local database.
  Future<Either<Failure, UserConfiguration>> getUserConfigurations(int userId);
}
