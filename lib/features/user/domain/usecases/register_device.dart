import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/user_repository.dart';

@lazySingleton
class RegisterDevice implements UseCase<void, RegisterDeviceParams> {
  final UserRepository repository;

  RegisterDevice(this.repository);

  @override
  Future<Either<Failure, void>> call(RegisterDeviceParams params) async {
    return await repository.registerDevice(
      params.deviceId,
      params.deviceName,
      params.deviceModel,
      params.versionApp,
    );
  }
}

class RegisterDeviceParams extends Equatable {
  final String deviceId;
  final String deviceName;
  final String deviceModel;
  final String versionApp;

  const RegisterDeviceParams({
    required this.deviceId,
    required this.deviceName,
    required this.deviceModel,
    required this.versionApp,
  });

  @override
  List<Object?> get props => [deviceId, deviceName, deviceModel, versionApp];
}
