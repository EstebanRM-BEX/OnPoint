import 'dart:convert';
import 'package:injectable/injectable.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../src/api/api_request_service.dart';
import '../models/device_registration_model.dart';
import '../models/user_configuration_model.dart';
import '../models/user_location_model.dart';
import '../models/user_novelty_model.dart';

abstract class UserRemoteDataSource {
  Future<UserConfigurationModel> getUserConfiguration();
  Future<List<UserLocationModel>> getUserLocations();
  Future<List<UserNoveltyModel>> getNovelties();
  Future<DeviceRegistrationModel> registerDevice(String deviceId,
      String deviceName, String deviceModel, String versionApp);
}

@LazySingleton(as: UserRemoteDataSource)
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final ApiRequestService apiService;

  UserRemoteDataSourceImpl(this.apiService);

  @override
  Future<UserConfigurationModel> getUserConfiguration() async {
    final response = await apiService.get(
      endpoint: 'configurations',
      isunecodePath: true,
      isLoadinDialog: false,
    );

    if (response.statusCode < 400) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      final config = UserConfigurationModel.fromJson(jsonResponse);

      final code = config.result?.code;
      if (code != 200) {
        final msg = config.result?.msg?.toString().isNotEmpty == true
            ? config.result!.msg.toString()
            : 'No tienes permisos para acceder a la aplicación';
        throw ServerException(msg);
      }

      return config;
    } else {
      throw ServerException('Error del servidor: ${response.statusCode}');
    }
  }

  @override
  Future<List<UserLocationModel>> getUserLocations() async {
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
  Future<List<UserNoveltyModel>> getNovelties() async {
    final response = await apiService.get(
      endpoint: 'picking_novelties',
      isunecodePath: true,
      isLoadinDialog: false,
    );

    if (response.statusCode < 400) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      if (jsonResponse.containsKey('result') &&
          jsonResponse['result']['code'] == 200) {
        final List<dynamic> list = jsonResponse['result']['result'] ?? [];
        return list.map((e) => UserNoveltyModel.fromJson(e)).toList();
      }
    }
    throw Exception('Failed to load novelties');
  }

  @override
  Future<DeviceRegistrationModel> registerDevice(String deviceId,
      String deviceName, String deviceModel, String versionApp) async {
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

    if (response.statusCode < 400) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      if (jsonResponse.containsKey('result') &&
          jsonResponse['result']['code'] == 200) {
        final Map<String, dynamic> data = jsonResponse['result']['data'];
        return DeviceRegistrationModel.fromJson(data);
      }
      throw Exception(jsonResponse['result']?['msg'] ?? 'Failed to register device');
    }
    throw Exception('Failed to register device');
  }
}
