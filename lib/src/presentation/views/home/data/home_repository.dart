// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously

import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_app/src/api/api_request_service.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/presentation/views/home/domain/models/app_version_model.dart';

class HomeRepository {
  Future<AppVersion> getAppVersion() async {
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
      return AppVersion(); // Si no hay conexión, retornar una lista vacía
    }

    try {
      var response = await ApiRequestService().get(
        endpoint: 'last-version',
        isunecodePath: true,
        isLoadinDialog: true,
      );

      if (response.statusCode < 400) {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Decodifica la respuesta JSON a un mapa
        if (jsonResponse.containsKey('result')) {
          if (jsonResponse['result']['code'] == 400) {
             return AppVersion(
              message: jsonResponse['result']['msg'] ?? 'Error desconocido',
             );
          } else if (jsonResponse['result']['code'] == 200) {
            return AppVersion.fromMap(jsonDecode(response.body));
          }
        } else if (jsonResponse.containsKey('error')) {
          if (jsonResponse['error']['code'] == 100) {
            Get.defaultDialog(
              title: 'Alerta',
              titleStyle: TextStyle(color: Colors.red, fontSize: 18),
              middleText: 'Sesion expirada, por favor inicie sesión nuevamente',
              middleTextStyle: TextStyle(color: black, fontSize: 14),
              backgroundColor: Colors.white,
              radius: 10,
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColorApp,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Aceptar', style: TextStyle(color: white)),
                ),
              ],
            );
            return AppVersion();
          }
        }
        return AppVersion();
      } else {
        return AppVersion();
      }
    } catch (e, s) {
      print('Error en get last version: $e => $s');
      return AppVersion();
    }
  }
}
