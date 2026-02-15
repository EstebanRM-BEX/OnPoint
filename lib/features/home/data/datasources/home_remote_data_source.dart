import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/features/home/data/models/app_version_model.dart';
import 'package:wms_app/src/api/api_request_service.dart';

/// Abstract data source for remote operations.
abstract class HomeRemoteDataSource {
  Future<AppVersionModel> getAppVersion();
}

/// Implementation of remote data source using HTTP client.
@LazySingleton(as: HomeRemoteDataSource)
class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final ApiRequestService apiService;

  HomeRemoteDataSourceImpl(this.apiService);

  @override
  Future<AppVersionModel> getAppVersion() async {
    try {
      var response = await apiService.get(
        endpoint: 'last-version',
        isunecodePath: true,
        isLoadinDialog: true,
      );

      if (response.statusCode < 400) {
        final jsonResponse = jsonDecode(response.body);
        // Check for session expired error
        if (jsonResponse.containsKey('error') &&
            jsonResponse['error']['code'] == 100) {
          throw const SessionExpiredException('Sesión expirada');
        }

        return AppVersionModel.fromMap(jsonResponse);
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      throw ServerException('Error al obtener versión: $e');
    }
  }
}
