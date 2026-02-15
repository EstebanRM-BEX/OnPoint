import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/src/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/features/home/data/models/app_version_model.dart';

/// Abstract data source for remote operations.
abstract class HomeRemoteDataSource {
  Future<AppVersionModel> getAppVersion();
}

/// Implementation of remote data source using HTTP client.
@LazySingleton(as: HomeRemoteDataSource)
class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final http.Client client;

  HomeRemoteDataSourceImpl(this.client);

  @override
  Future<AppVersionModel> getAppVersion() async {
    try {
      final url = await PrefUtils.getEnterprise();
      final fullUrl = '$url/api/last-version';

      final response = await client.get(
        Uri.parse(fullUrl),
        headers: {'Content-Type': 'application/json'},
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
