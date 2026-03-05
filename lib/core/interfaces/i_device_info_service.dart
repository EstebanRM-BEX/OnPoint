abstract class IDeviceInfoService {
  Future<String?> getMacAddress();
  Future<String?> getImei();
}
