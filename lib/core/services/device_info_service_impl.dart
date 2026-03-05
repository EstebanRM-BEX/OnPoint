import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import '../interfaces/i_device_info_service.dart';

@LazySingleton(as: IDeviceInfoService)
class DeviceInfoServiceImpl implements IDeviceInfoService {
  static const _channel = MethodChannel('device_info/custom');

  @override
  Future<String?> getMacAddress() async {
    try {
      return await _channel.invokeMethod<String>('getMacAddress');
    } catch (e) {
      debugPrint('Error obteniendo MAC: $e');
      return null;
    }
  }

  @override
  Future<String?> getImei() async {
    try {
      return await _channel.invokeMethod<String>('getImei');
    } catch (e) {
      debugPrint('Error obteniendo IMEI: $e');
      return null;
    }
  }
}
