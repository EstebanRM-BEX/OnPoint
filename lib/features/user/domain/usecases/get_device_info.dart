import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/device_info.dart';
import '../repositories/user_repository.dart';

@lazySingleton
class GetDeviceInfo implements UseCase<DeviceInfo, NoParams> {
  final UserRepository repository;

  GetDeviceInfo(this.repository);

  @override
  Future<Either<Failure, DeviceInfo>> call(NoParams params) async {
    return await repository.getDeviceInfo();
  }
}
