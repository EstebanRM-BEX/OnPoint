import 'package:flutter/services.dart';

class DeviceInfoCustom {
  static const _channel = MethodChannel('device_info/custom');

  /// Obtener la dirección MAC
  static Future<String?> getMacAddress() async {
    try {
      final mac = await _channel.invokeMethod<String>('getMacAddress');
      return mac;
    } catch (e) {
      print('Error obteniendo MAC: $e');
      return null;
    }
  }

  /// Obtener el IMEI
  static Future<String?> getImei() async {
    try {
      final imei = await _channel.invokeMethod<String>('getImei');
      return imei;
    } catch (e) {
      print('Error obteniendo IMEI: $e');
      return null;
    }
  }
}
