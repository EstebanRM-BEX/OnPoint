// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_app/src/api/api_request_service.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/presentation/views/global/login/models/user_model_response.dart';
import 'package:wms_app/src/services/preferences.dart';

class LoginRepository {
  Future<UserModelResponse> login(
    String email,
    String password,
  ) async {
    try {
      final String dataBd = Preferences.nameDatabase;

      var response = await ApiRequestService().post(
        endpoint: 'web/session/authenticate',
        isunecodePath: false,
        body: {
          "params": {"login": email, "password": password, "db": dataBd}
        },
        isLoadinDialog: false,
      );

      print('Response status code: ${response.statusCode}');
      if (response.statusCode < 400) {
        return UserModelResponse.fromMap(jsonDecode(response.body));
      } else {
        print(response.body);
        if (response.body.contains('jsonrpc')) {
          throw Exception('Error en el método de la petición de la API');
        }
        return UserModelResponse();
      }
    } catch (e, s) {
      print('Error en login_repository.dart: $e $s');
    }
    return UserModelResponse();
  }
}
