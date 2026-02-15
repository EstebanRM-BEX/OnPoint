import 'package:equatable/equatable.dart';

class DeviceInfo extends Equatable {
  final String model;
  final String version;
  final String manufacturer;
  final String mac;
  final String imei;
  final String appVersion;
  final String deviceId;

  const DeviceInfo({
    required this.model,
    required this.version,
    required this.manufacturer,
    required this.mac,
    required this.imei,
    required this.appVersion,
    required this.deviceId,
  });

  @override
  List<Object?> get props =>
      [model, version, manufacturer, mac, imei, appVersion, deviceId];
}
