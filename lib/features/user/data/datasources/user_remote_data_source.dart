import 'dart:convert';
import 'package:injectable/injectable.dart';
import '../../../../src/api/api_request_service.dart';
import '../models/user_configuration_model.dart';
import '../models/user_location_model.dart';

abstract class UserRemoteDataSource {
  Future<UserConfigurationModel> getUserConfiguration();
  Future<List<UserLocationModel>> getUserLocations();
  Future<void> registerDevice(String deviceId, String deviceName,
      String deviceModel, String versionApp);
}

@LazySingleton(as: UserRemoteDataSource)
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final ApiRequestService apiService;

  UserRemoteDataSourceImpl(this.apiService);

  @override
  Future<UserConfigurationModel> getUserConfiguration() async {
    print("📍getUserConfiguration");
    final response = await apiService.get(
      endpoint: 'configurations',
      isunecodePath: true,
      isLoadinDialog: false,
    );

    if (response.statusCode < 400) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      return UserConfigurationModel.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to load user configuration');
    }
  }

  @override
  Future<List<UserLocationModel>> getUserLocations() async {
    print("📍getUserLocations");
    final response = await apiService.get(
      endpoint: 'ubicaciones',
      isunecodePath: true,
      isLoadinDialog: false,
    );

    if (response.statusCode < 400) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      if (jsonResponse.containsKey('result') &&
          jsonResponse['result']['code'] == 200) {
        final List<dynamic> list = jsonResponse['result']['result'] ?? [];
        return list.map((e) => UserLocationModel.fromJson(e)).toList();
      }
    }
    throw Exception('Failed to load locations');
  }

  @override
  Future<void> registerDevice(String deviceId, String deviceName,
      String deviceModel, String versionApp) async {
    print("📍registerDevice");
    final response = await apiService.postPicking(
      endpoint: 'pda/register',
      body: {
        "params": {
          "device_id": deviceId,
          "device_name": deviceName,
          "device_model": deviceModel,
          "version_app": versionApp,
        }
      },
      isunecodePath: true,
      isLoadinDialog: false,
    );

    if (response.statusCode >= 400) {
      throw Exception('Failed to register device');
    }
  }
}
