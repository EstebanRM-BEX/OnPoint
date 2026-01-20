// ignore_for_file: avoid_print, use_build_context_synchronously, unrelated_type_equality_checks

import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_app/src/api/api_request_service.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/views/user/models/configuration.dart';
import 'package:wms_app/src/presentation/views/user/models/response_pda_register_model.dart';

class UserRepository {
  Future<Configurations> configurations(
  ) async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        print("Error: No hay conexión a Internet.");
        return Configurations(); // Si no hay conexión, retornar una lista vacía
      }

      var response = await ApiRequestService().get(
        endpoint: 'configurations',
        isunecodePath: true,
        isLoadinDialog: false,
      );
      if (response.statusCode < 400) {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('result')) {
          print('code : ${jsonResponse['result']['code']}');
          if (jsonResponse['result']['code'] == 200) {
            return Configurations.fromMap(jsonDecode(response.body));
          } else {
            return Configurations(
              result: ConfigurationsResult(
                code: jsonResponse['result']['code'],
                msg: jsonResponse['result']['msg'],
              ),
            );
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
            return Configurations();
          }
        }
      } else {
        return Configurations();
      }
    } catch (e, s) {
      print('Error en configurations.dart: $e $s');
    }
    return Configurations();
  }
  Future<List<ResultUbicaciones>> ubicaciones() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        print("Error: No hay conexión a Internet.");
        return [];
      }

      var response = await ApiRequestService().get(
        endpoint: 'ubicaciones',
        isunecodePath: true,
        isLoadinDialog: false,
      );

      if (response.statusCode < 400) {
        final jsonResponse = await parseJson(response.body);

        if (jsonResponse.containsKey('result')) {
          if (jsonResponse['result']['code'] == 200) {
            if (jsonResponse['result'].containsKey('result')) {
              List<dynamic> responseUbicaciones =
                  jsonResponse['result']['result'];
              List<ResultUbicaciones> ubicaciones = responseUbicaciones
                  .map((data) => ResultUbicaciones.fromMap(data))
                  .toList();
              return ubicaciones;
            }
          }
        } else if (jsonResponse.containsKey('error')) {
          if (jsonResponse['error']['code'] == 100) {
            Get.defaultDialog(
              title: 'Alerta',
              titleStyle: TextStyle(color: Colors.red, fontSize: 18),
              middleText: 'Sesión expirada, por favor inicie sesión nuevamente',
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
            return [];
          }
        }
      } 
    } catch (e, s) {
      print('Error en ubicaciones USER: $e $s');
    }
    return [];
  }

  Future<ResponsePdaRegister> sendIdPda(
      String deviceId, String deviceName, String deviceModel, String versionApp) async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();

      //obtenemos la versión de la app

      if (connectivityResult == ConnectivityResult.none) {
        print("Error: No hay conexión a Internet.");
        return ResponsePdaRegister();
      }

      var response = await ApiRequestService().postPicking(
        endpoint: 'pda/register',
        body: {
          "params": {
            "device_id": deviceId,
            "device_name": deviceName,
            "device_model": deviceModel,
            "version_app" : versionApp, // Cambia esto según tu versión de la app
          }
        },
        isunecodePath: true,
        isLoadinDialog: false,
      );

      if (response.statusCode < 400) {
        final jsonResponse = await parseJson(response.body);

        if (jsonResponse.containsKey('result')) {
          if (jsonResponse['result']['code'] == 200) {

            if (jsonResponse['result'].containsKey('data')) {
              return ResponsePdaRegister.fromMap(jsonResponse);
            } else {
              return ResponsePdaRegister(
                result: Result(
                  code: jsonResponse['result']['code'],
                  msg: jsonResponse['result']['msg'],
                ),
              );
            }
          }
        } else if (jsonResponse.containsKey('error')) {
          if (jsonResponse['error']['code'] == 100) {
            Get.defaultDialog(
              title: 'Alerta',
              titleStyle: TextStyle(color: Colors.red, fontSize: 18),
              middleText: 'Sesión expirada, por favor inicie sesión nuevamente',
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
            return ResponsePdaRegister();
          }
        }
      }
    } catch (e, s) {
      print('Error en sendIdPda: $e $s');
    }
    return ResponsePdaRegister();
  }

  Future<Map<String, dynamic>> parseJson(String body) async {
    return compute(_parseJson, body);
  }

  Map<String, dynamic> _parseJson(String body) {
    return jsonDecode(body);
  }
}
