import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/src/api/api_request_service.dart';
import 'package:wms_app/features/login/data/models/user_model.dart';

/// Remote data source for login operations.
/// Handles all HTTP requests related to authentication.
abstract class LoginRemoteDataSource {
  Future<UserModel> authenticate({
    required String email,
    required String password,
    required String database,
  });
}

@LazySingleton(as: LoginRemoteDataSource)
class LoginRemoteDataSourceImpl implements LoginRemoteDataSource {
  final ApiRequestService apiService;

  LoginRemoteDataSourceImpl(this.apiService);

  @override
  Future<UserModel> authenticate({
    required String email,
    required String password,
    required String database,
  }) async {
    try {
      final response = await apiService.post(
        endpoint: 'web/session/authenticate',
        isunecodePath: false,
        body: {
          "params": {
            "login": email,
            "password": password,
            "db": database,
          }
        },
        isLoadinDialog: false,
      );

      if (response.statusCode < 400) {
        final jsonResponse = jsonDecode(response.body);

        // Log the full response for debugging
        print('📥 Server response: $jsonResponse');

        // Check if there's an error in the response
        if (jsonResponse['error'] != null) {
          final error = jsonResponse['error'];
          final errorMessage = error['data']?['message'] ??
              error['message'] ??
              'Error de autenticación';
          throw AuthenticationException(errorMessage);
        }

        // Check if result is null
        if (jsonResponse['result'] == null) {
          throw const AuthenticationException(
              'Credenciales inválidas o base de datos incorrecta');
        }

        return UserModel.fromJson(jsonResponse);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw const AuthenticationException('Credenciales inválidas');
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on AuthenticationException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }
}
