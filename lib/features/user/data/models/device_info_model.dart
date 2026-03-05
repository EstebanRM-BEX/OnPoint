import 'package:wms_app/core/interfaces/i_device_info_service.dart';
import 'package:wms_app/injection_container.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../domain/entities/device_info.dart';

class DeviceInfoModel extends DeviceInfo {
  const DeviceInfoModel({
    required super.model,
    required super.version,
    required super.manufacturer,
    required super.mac,
    required super.imei,
    required super.appVersion,
    required super.deviceId,
  });

  // Factory to create from platform info
  static Future<DeviceInfoModel> fromPlatform() async {
    DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    String mac = (await getIt<IDeviceInfoService>().getMacAddress()) ?? 'unknown';
    String imei = (await getIt<IDeviceInfoService>().getImei()) ?? 'unknown';

    return DeviceInfoModel(
      model: androidInfo.model,
      version: androidInfo.version.release,
      manufacturer: androidInfo.manufacturer,
      mac: mac,
      imei: imei,
      appVersion: packageInfo.version,
      deviceId: androidInfo.id,
    );
  }
}
