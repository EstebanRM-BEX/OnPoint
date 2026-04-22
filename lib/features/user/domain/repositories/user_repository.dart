import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/device_info.dart';
import '../entities/device_registration.dart';
import '../entities/user_configuration.dart';
import '../entities/user_location.dart';
import '../entities/user_novelty.dart';

abstract class UserRepository {
  Future<Either<Failure, UserConfiguration>> getUserConfiguration();
  Future<Either<Failure, DeviceInfo>> getDeviceInfo();
  Future<Either<Failure, List<UserLocation>>> getUserLocations();
  Future<Either<Failure, List<Novedad>>> getNovelties();
  Future<Either<Failure, DeviceRegistration>> registerDevice(String deviceId,
      String deviceName, String deviceModel, String versionApp);
}
