import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/services/interfaces/i_storage_service.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/src/api/api_request_service.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/response_pick_done_id_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/response_pick_model.dart';

class PickingPickRepository {
  Future<ResponsePickResult> resPicks(
    bool isLoadinDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return ResponsePickResult(
        code: 500,
        result: [],
      ); // Si no hay conexión, retornar una lista vacía
    }

    try {
      var response = await ApiRequestService().getValidation(
        endpoint: 'transferencias/pick',
        isunecodePath: true,
        isLoadinDialog: isLoadinDialog,
      );

      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Accede a la clave "data" y luego a "result"

        // Asegúrate de que 'result' exista y sea una lista
        if (jsonResponse.containsKey('result')) {
          if (jsonResponse['result']['code'] == 400) {
            Get.snackbar(
              'Error',
              'Error : ${jsonResponse['result']['msg']}',
              backgroundColor: white,
              colorText: primaryColorApp,
              icon: Icon(Icons.check, color: Colors.red),
            );
          } else if (jsonResponse['result']['code'] == 200) {
            if (jsonResponse['result'].containsKey('result')) {
              // Si contiene 'result', se procede con el mapeo
              List<dynamic> batches = jsonResponse['result']['result'];
              List<ResultPick> products =
                  batches.map((data) => ResultPick.fromMap(data)).toList();
              return ResponsePickResult(
                code: 200,
                result: products,
                updateVersion:
                    jsonResponse['result']['update_version'] ?? false,
              );
            }
          } else if (jsonResponse['result']['code'] == 403) {
            Get.defaultDialog(
              title: 'Dispositivo no autorizado',
              titleStyle: TextStyle(
                  color: primaryColorApp,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
              middleText:
                  'Este dispositivo no está autorizado para usar la aplicación. su suscripción ha expirado o no está activa, por favor contacte con el administrador.',
              middleTextStyle: TextStyle(color: black, fontSize: 14),
              backgroundColor: Colors.white,
              radius: 10,
              barrierDismissible:
                  false, // Evita que se cierre al tocar fuera del diálogo
              onWillPop: () async => false,
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
            return ResponsePickResult(
              code: 500,
              msg: 'Error de conexión',
              result: [],
            );
          }
        }
      } else {}
    } on SocketException catch (e) {
      // Manejo de error de red
      debugPrint('Error de red: $e');
      return ResponsePickResult(
        code: 500,
        msg: 'Error de conexión',
        result: [],
      );
    } catch (e, s) {
      // Manejo de otros errores

      Get.snackbar(
        'Error',
        'Error en resPicks: $e $s',
        backgroundColor: white,
        colorText: primaryColorApp,
        icon: Icon(Icons.check, color: Colors.red),
      );

      debugPrint('Error resPicks: $e, $s');
    }
    return ResponsePickResult(
      code: 500,
      msg: 'Error de conexión',
      result: [],
    );
  }

  Future<List<ResultPick>> resPicksDone(
    bool isLoadinDialog,
    String date,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return []; // Si no hay conexión, retornar una lista vacía
    }

    try {
      var response = await ApiRequestService().getHistory(
          endpoint: 'transferencias/history_picking',
          isunecodePath: true,
          field: 'fecha_picking',
          isLoadinDialog: isLoadinDialog,
          date: date);

      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Accede a la clave "data" y luego a "result"

        // Asegúrate de que 'result' exista y sea una lista
        if (jsonResponse.containsKey('result')) {
          if (jsonResponse['result']['code'] == 400) {
            Get.snackbar(
              'Error',
              'Error : ${jsonResponse['result']['msg']}',
              backgroundColor: white,
              colorText: primaryColorApp,
              icon: Icon(Icons.check, color: Colors.red),
            );
          } else if (jsonResponse['result']['code'] == 200) {
            if (jsonResponse['result'].containsKey('result')) {
              // Si contiene 'result', se procede con el mapeo
              List<dynamic> batches = jsonResponse['result']['result'];
              List<ResultPick> products =
                  batches.map((data) => ResultPick.fromMap(data)).toList();
              return products;
            }
          } else if (jsonResponse['result']['code'] == 403) {
            Get.defaultDialog(
              title: 'Dispositivo no autorizado',
              titleStyle: TextStyle(
                  color: primaryColorApp,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
              middleText:
                  'Este dispositivo no está autorizado para usar la aplicación. su suscripción ha expirado o no está activa, por favor contacte con el administrador.',
              middleTextStyle: TextStyle(color: black, fontSize: 14),
              backgroundColor: Colors.white,
              radius: 10,
              barrierDismissible:
                  false, // Evita que se cierre al tocar fuera del diálogo
              onWillPop: () async => false,
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
            return [];
          }
        }
      } else {}
    } on SocketException catch (e) {
      // Manejo de error de red
      debugPrint('Error de red: $e');
      return [];
    } catch (e, s) {
      // Manejo de otros errores

      Get.snackbar(
        'Error',
        'Error en resPicks: $e $s',
        backgroundColor: white,
        colorText: primaryColorApp,
        icon: Icon(Icons.check, color: Colors.red),
      );

      debugPrint('Error resPicksDone: $e, $s');
    }
    return [];
  }

  Future<List<ResultPick>> resPicksComponentsDone(
    bool isLoadinDialog,
    String date,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return []; // Si no hay conexión, retornar una lista vacía
    }

    try {
      var response = await ApiRequestService().getHistory(
          endpoint: 'picking/componentes/history',
          isunecodePath: true,
          field: 'fecha_picking',
          isLoadinDialog: isLoadinDialog,
          date: date);

      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Accede a la clave "data" y luego a "result"

        // Asegúrate de que 'result' exista y sea una lista
        if (jsonResponse.containsKey('result')) {
          if (jsonResponse['result']['code'] == 400) {
            Get.snackbar(
              'Error',
              'Error : ${jsonResponse['result']['msg']}',
              backgroundColor: white,
              colorText: primaryColorApp,
              icon: Icon(Icons.check, color: Colors.red),
            );
          } else if (jsonResponse['result']['code'] == 200) {
            if (jsonResponse['result'].containsKey('result')) {
              // Si contiene 'result', se procede con el mapeo
              List<dynamic> batches = jsonResponse['result']['result'];
              List<ResultPick> products =
                  batches.map((data) => ResultPick.fromMap(data)).toList();
              return products;
            }
          } else if (jsonResponse['result']['code'] == 403) {
            Get.defaultDialog(
              title: 'Dispositivo no autorizado',
              titleStyle: TextStyle(
                  color: primaryColorApp,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
              middleText:
                  'Este dispositivo no está autorizado para usar la aplicación. su suscripción ha expirado o no está activa, por favor contacte con el administrador.',
              middleTextStyle: TextStyle(color: black, fontSize: 14),
              backgroundColor: Colors.white,
              radius: 10,
              barrierDismissible:
                  false, // Evita que se cierre al tocar fuera del diálogo
              onWillPop: () async => false,
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
            return [];
          }
        }
      } else {}
    } on SocketException catch (e) {
      // Manejo de error de red
      debugPrint('Error de red: $e');
      return [];
    } catch (e, s) {
      // Manejo de otros errores

      Get.snackbar(
        'Error',
        'Error en resPicks: $e $s',
        backgroundColor: white,
        colorText: primaryColorApp,
        icon: Icon(Icons.check, color: Colors.red),
      );

      debugPrint('Error resPicksDone: $e, $s');
    }
    return [];
  }

  Future<ResponsePickResult> resPickingComponentes(
    bool isLoadinDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return ResponsePickResult(
        code: 500,
        result: [],
        updateVersion: false,
      ); // Si no hay conexión, retornar una lista vacía
    }

    try {
      var response = await ApiRequestService().getValidation(
        endpoint: 'picking/componentes',
        isunecodePath: true,
        isLoadinDialog: isLoadinDialog,
      );

      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Accede a la clave "data" y luego a "result"

        // Asegúrate de que 'result' exista y sea una lista
        if (jsonResponse.containsKey('result')) {
          if (jsonResponse['result']['code'] == 400) {
            Get.snackbar(
              'Error',
              'Error : ${jsonResponse['result']['msg']}',
              backgroundColor: white,
              colorText: primaryColorApp,
              icon: Icon(Icons.check, color: Colors.red),
            );
            return ResponsePickResult(
              code: 400,
              msg: jsonResponse['result']['msg'],
              result: [],
              updateVersion: false,
            );
          } else if (jsonResponse['result']['code'] == 200) {
            if (jsonResponse['result'].containsKey('result')) {
              // Si contiene 'result', se procede con el mapeo
              List<dynamic> batches = jsonResponse['result']['result'];
              List<ResultPick> products =
                  batches.map((data) => ResultPick.fromMap(data)).toList();
              return ResponsePickResult(
                code: 200,
                result: products,
                updateVersion:
                    jsonResponse['result']['update_version'] ?? false,
              );
            }
          } else if (jsonResponse['result']['code'] == 403) {
            Get.defaultDialog(
              title: 'Dispositivo no autorizado',
              titleStyle: TextStyle(
                  color: primaryColorApp,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
              middleText:
                  'Este dispositivo no está autorizado para usar la aplicación. su suscripción ha expirado o no está activa, por favor contacte con el administrador.',
              middleTextStyle: TextStyle(color: black, fontSize: 14),
              backgroundColor: Colors.white,
              radius: 10,
              barrierDismissible:
                  false, // Evita que se cierre al tocar fuera del diálogo
              onWillPop: () async => false,
            );
          }
          return ResponsePickResult(
            code: jsonResponse['result']['code'],
            msg: jsonResponse['result']['msg'],
            result: [],
            updateVersion: false,
          );
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
            return ResponsePickResult(
              code: 500,
              msg: 'Error de conexión',
              result: [],
              updateVersion: false,
            );
          }
        }
      } else {}
    } on SocketException catch (e) {
      // Manejo de error de red
      debugPrint('Error de red: $e');
      return ResponsePickResult(
        code: 500,
        msg: 'Error de conexión',
        result: [],
        updateVersion: false,
      );
    } catch (e, s) {
      // Manejo de otros errores

      Get.snackbar(
        'Error',
        'Error en resPicks: $e $s',
        backgroundColor: white,
        colorText: primaryColorApp,
        icon: Icon(Icons.check, color: Colors.red),
      );

      debugPrint('Error resPicks: $e, $s');
    }
    return ResponsePickResult(
      code: 500,
      msg: 'Error de conexión',
      result: [],
      updateVersion: false,
    );
  }

//metodo para pedir un pcikdone por id
  Future<RespondePickDoneId> getPicksDoneId(
    bool isLoadinDialog,
    int idPicking,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return RespondePickDoneId(); // Si no hay conexión, retornar una lista vacía
    }

    try {
      var response = await ApiRequestService().get(
        endpoint: 'transferencias/$idPicking',
        isunecodePath: true,
        isLoadinDialog: isLoadinDialog,
      );

      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Accede a la clave "data" y luego a "result"

        // Asegúrate de que 'result' exista y sea una lista
        if (jsonResponse.containsKey('result')) {
          if (jsonResponse['result']['code'] == 400) {
            Get.snackbar(
              'Error',
              'Error : ${jsonResponse['result']['msg']}',
              backgroundColor: white,
              colorText: primaryColorApp,
              icon: Icon(Icons.check, color: Colors.red),
            );
          } else if (jsonResponse['result']['code'] == 200) {
            if (jsonResponse['result'].containsKey('result')) {
              return RespondePickDoneId(
                id: jsonResponse['id'],
                jsonrpc: jsonResponse['jsonrpc'],
                result: jsonResponse['result'] != null
                    ? RespondePickDoneIdResult(
                        code: jsonResponse['result']['code'],
                        result: ResultResult.fromMap(
                            jsonResponse['result']['result']),
                      )
                    : null,
              );
            }
          } else if (jsonResponse['result']['code'] == 403) {
            Get.defaultDialog(
              title: 'Dispositivo no autorizado',
              titleStyle: TextStyle(
                  color: primaryColorApp,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
              middleText:
                  'Este dispositivo no está autorizado para usar la aplicación. su suscripción ha expirado o no está activa, por favor contacte con el administrador.',
              middleTextStyle: TextStyle(color: black, fontSize: 14),
              backgroundColor: Colors.white,
              radius: 10,
              barrierDismissible:
                  false, // Evita que se cierre al tocar fuera del diálogo
              onWillPop: () async => false,
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
            return RespondePickDoneId();
          }
        }
      } else {}
    } on SocketException catch (e) {
      // Manejo de error de red
      debugPrint('Error de red: $e');
      return RespondePickDoneId();
    } catch (e, s) {
      // Manejo de otros errores

      Get.snackbar(
        'Error',
        'Error en resPicks: $e $s',
        backgroundColor: white,
        colorText: primaryColorApp,
        icon: Icon(Icons.check, color: Colors.red),
      );

      debugPrint('Error getPickId: $e, $s');
    }
    return RespondePickDoneId();
  }
}
