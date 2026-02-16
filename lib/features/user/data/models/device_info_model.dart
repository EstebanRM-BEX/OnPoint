import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/utils/get_mac_utils.dart';
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

    String mac = (await DeviceInfoCustom.getMacAddress()) ?? 'unknown';
    String imei = (await DeviceInfoCustom.getImei()) ?? 'unknown';

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
