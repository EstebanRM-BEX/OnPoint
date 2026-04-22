import '../../domain/entities/device_registration.dart';

class DeviceRegistrationModel extends DeviceRegistration {
  const DeviceRegistrationModel({
    required super.deviceId,
    required super.deviceName,
    required super.isAuthorized,
    required super.isActive,
    required super.totalConnections,
    required super.monthlyConnections,
    required super.deviceModel,
    required super.versionApp,
    required super.needsAuthorization,
  });

  factory DeviceRegistrationModel.fromJson(Map<String, dynamic> json) {
    return DeviceRegistrationModel(
      deviceId: json['device_id'] ?? '',
      deviceName: json['device_name'] ?? '',
      isAuthorized: json['is_authorized'] ?? '',
      isActive: json['is_active'] ?? false,
      totalConnections: json['total_connections'] ?? 0,
      monthlyConnections: json['monthly_connections'] ?? 0,
      deviceModel: json['device_model'] ?? '',
      versionApp: json['version_app'] ?? '',
      needsAuthorization: json['needs_authorization'] ?? false,
    );
  }
}
