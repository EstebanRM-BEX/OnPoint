import 'package:equatable/equatable.dart';

class DeviceRegistration extends Equatable {
  final String deviceId;
  final String deviceName;
  final String isAuthorized;
  final bool isActive;
  final int totalConnections;
  final int monthlyConnections;
  final String deviceModel;
  final String versionApp;
  final bool needsAuthorization;

  const DeviceRegistration({
    required this.deviceId,
    required this.deviceName,
    required this.isAuthorized,
    required this.isActive,
    required this.totalConnections,
    required this.monthlyConnections,
    required this.deviceModel,
    required this.versionApp,
    required this.needsAuthorization,
  });

  @override
  List<Object?> get props => [
        deviceId,
        deviceName,
        isAuthorized,
        isActive,
        totalConnections,
        monthlyConnections,
        deviceModel,
        versionApp,
        needsAuthorization,
      ];
}
