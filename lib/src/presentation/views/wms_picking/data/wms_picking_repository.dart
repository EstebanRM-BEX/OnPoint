// // ignore_for_file: avoid_print

// ignore_for_file: unrelated_type_equality_checks, avoid_print,

// import 'package:wms_app/src/api/api_request_service.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_app/src/api/api_request_service.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/presentation/models/novedades_response_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/response_ocupar_muelle_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/history/models/batch_history_id_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/history/models/hisotry_done_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/item_picking_request.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import 'dart:io';

import 'package:wms_app/src/presentation/views/wms_picking/models/response_send_picking.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/submeuelle_model.dart';

class WmsPickingRepository {
  //metodo para pedir los batchs
  Future<DataBatch> resBatchs(
    bool isLoadinDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
      return DataBatch(
          code: 500,
          msg: 'No internet connection',
          updateVersion: false,
          result: []); // Si no hay conexión, retornar una lista vacía
    }

    try {
      var response = await ApiRequestService().getValidation(
        endpoint: 'batchs',
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
            return DataBatch(
                code: 400,
                msg: jsonResponse['result']['msg'] ?? 'Error',
                updateVersion: false,
                result: []);
          } else if (jsonResponse['result']['code'] == 200) {
            if (jsonResponse['result'].containsKey('result')) {
              // Si contiene 'result', se procede con el mapeo
              List<dynamic> batches = jsonResponse['result']['result'];
              List<BatchsModel> products =
                  batches.map((data) => BatchsModel.fromMap(data)).toList();
              return DataBatch(
                  code: 200,
                  msg: jsonResponse['result']['msg'] ?? 'Success',
                  updateVersion:
                      jsonResponse['result']['update_version'] ?? false,
                  result: products);
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
            return DataBatch(
                code: 403,
                msg: 'Device not authorized',
                updateVersion: false,
                result: []);
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
            return DataBatch(
                code: 100,
                msg: 'Session expired',
                updateVersion: false,
                result: []);
          }
        }
      }
    } on SocketException catch (e) {
      // Manejo de error de red
      print('Error de red: $e');
      return DataBatch(
          code: 500,
          msg: 'Network error: $e',
          updateVersion: false,
          result: []);
    } catch (e, s) {
      // Manejo de otros errores
      print('Error en resBatchs: $e $s');
    }
    return DataBatch(
        code: 500, msg: 'Unknown error', updateVersion: false, result: []);
  }

  //metodo para pedir los batchs
  Future<DataBatch> resBatchsByComponents(
    bool isLoadinDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
      return DataBatch(
          code: 500,
          msg: 'No internet connection',
          updateVersion: false,
          result: []); // Si no hay conexión, retornar una lista vacía
    }

    try {
      var response = await ApiRequestService().getValidation(
        endpoint: 'batchs/componentes',
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
            return DataBatch(
                code: 400,
                msg: jsonResponse['result']['msg'] ?? 'Error',
                updateVersion: false,
                result: []);
          } else if (jsonResponse['result']['code'] == 200) {
            if (jsonResponse['result'].containsKey('result')) {
              // Si contiene 'result', se procede con el mapeo
              List<dynamic> batches = jsonResponse['result']['result'];
              List<BatchsModel> products =
                  batches.map((data) => BatchsModel.fromMap(data)).toList();
              return DataBatch(
                  code: 200,
                  msg: jsonResponse['result']['msg'] ?? 'Success',
                  updateVersion:
                      jsonResponse['result']['update_version'] ?? false,
                  result: products);
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
            return DataBatch(
                code: 403,
                msg: 'Device not authorized',
                updateVersion: false,
                result: []);
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
            return DataBatch(
                code: 100,
                msg: 'Session expired',
                updateVersion: false,
                result: []);
          }
        }
      }
    } on SocketException catch (e) {
      // Manejo de error de red
      print('Error de red: $e');
      return DataBatch(
          code: 500,
          msg: 'Network error: $e',
          updateVersion: false,
          result: []);
    } catch (e, s) {
      // Manejo de otros errores
      print('Error en resBatchsByComponents: $e $s');
    }
    return DataBatch(
        code: 500, msg: 'Unknown error', updateVersion: false, result: []);
  }

  Future<List<HistoryBatch>> resBatchsHistory(
    bool isLoadinDialog,
    String date,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
      return []; // Si no hay conexión, retornar una lista vacía
    }

    try {
      var response = await ApiRequestService().getHistory(
          endpoint: 'batchs_done',
          isunecodePath: true,
          isLoadinDialog: isLoadinDialog,
          field: 'fecha_batch',
          date: date);

      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Accede a la clave "data" y luego a "result"

        // Asegúrate de que 'result' exista y sea una lista
        if (jsonResponse.containsKey('result')) {
          if (jsonResponse['result']['code'] == 200) {
            if (jsonResponse['result'].containsKey('result')) {
              // Si contiene 'result', se procede con el mapeo
              List<dynamic> batches = jsonResponse['result']['result'];
              List<HistoryBatch> products =
                  batches.map((data) => HistoryBatch.fromMap(data)).toList();
              return products;
            } else {
              return [];
            }
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
      print('Error de red: $e');
      return [];
    } catch (e, s) {
      // Manejo de otros errores

      print('Error resBatchs: $e, $s');
    }
    return [];
  }

  //metodo para pedir los batchs por id
  Future<HistoryBatchId> getBatchById(bool isLoadinDialog, int batchId) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
      return HistoryBatchId(); // Si no hay conexión, retornar una lista vacía
    }

    try {
      var response = await ApiRequestService().get(
        endpoint: 'batch/$batchId',
        isunecodePath: true,
        isLoadinDialog: isLoadinDialog,
      );

      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Accede a la clave "data" y luego a "result"

        // Asegúrate de que 'result' exista y sea una lista
        if (jsonResponse.containsKey('result')) {
          Map<String, dynamic> batches = jsonResponse['result']['result'];

          // Mapea los datos decodificados a una lista de BatchsModel
          HistoryBatchId historyBatchId = HistoryBatchId.fromMap(batches);
          return historyBatchId;
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
            return HistoryBatchId();
          }
        }
      } else {}
    } on SocketException catch (e) {
      // Manejo de error de red
      print('Error de red: $e');
      return HistoryBatchId();
    } catch (e, s) {
      // Manejo de otros errores
      print('Error getBatchById: $e, $s');
    }
    return HistoryBatchId();
  }

  //metodo para pedir los submuelles
  Future<List<Muelles>> getmuelles(
    bool isLoadinDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
      return []; // Si no hay conexión, retornar una lista vacía
    }

    try {
      var response = await ApiRequestService().get(
        endpoint: 'muelles',
        isunecodePath: true,
        isLoadinDialog: isLoadinDialog,
      );

      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Accede a la clave "data" y luego a "result"

        // Asegúrate de que 'result' exista y sea una lista
        if (jsonResponse.containsKey('result')) {
          List<dynamic> batches = jsonResponse['result']['result'];
          // Mapea los datos decodificados a una lista de BatchsModel
          List<Muelles> muelles =
              batches.map((data) => Muelles.fromMap(data)).toList();
          return muelles;
        }
      } else {}
    } on SocketException catch (e) {
      // Manejo de error de red
      print('Error de red: $e');
      return [];
    } catch (e, s) {
      // Manejo de otros errores
      print('Error getmuelles: $e, $s');
    }
    return [];
  }

  Future<SendPickingResponse> sendPicking({
    required int idBatch,
    required double timeTotal,
    required int cantItemsSeparados,
    required List<Item> listItem,
    //
  }) async {
    print('idBatch: $idBatch');
    print('timeTotal: $timeTotal');
    print('cantItemsSeparados: $cantItemsSeparados');
    print('listItem: ${listItem.map((item) => item.toJson()).toList()}');

    try {
      var response = await ApiRequestService().postPicking(
        endpoint: 'send_batch',
        isunecodePath: true,
        body: {
          "params": {
            "id_batch": idBatch,
            "time_total": timeTotal,
            "cant_items_separados": cantItemsSeparados,
            "list_item": listItem.map((item) => item.toJson()).toList(),
          }
        },
        isLoadinDialog: false,
      );

      print(response);
      return SendPickingResponse.fromJson(response.body);
    } on SocketException catch (e) {
      // Manejo de error de red
      print('Error de red: $e');
    } catch (e, s) {
      // Manejo de otros errores
      print('Error sendPicking: $e, $s');
    }
    return SendPickingResponse();
  }

  Future<OcuparMuelle> ocuparMuelle({
    required int idMuelle,
    required bool isFull,
    //
  }) async {
    try {
      var response = await ApiRequestService().postPicking(
        endpoint: 'update_dock',
        isunecodePath: true,
        body: {
          "params": {
            "muelle_id": idMuelle,
            "is_full": isFull,
          }
        },
        isLoadinDialog: false,
      );

      print(response);
      return OcuparMuelle.fromJson(response.body);
    } on SocketException catch (e) {
      // Manejo de error de red
      print('Error de red: $e');
    } catch (e, s) {
      // Manejo de otros errores
      print('Error ocuparMuelle: $e, $s');
    }
    return OcuparMuelle();
  }

  //metod para obtener las novedades:
  Future<List<Novedad>> getnovedades(
    bool isLoadinDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
      return []; // Si no hay conexión, retornar una lista vacía
    }

    try {
      var response = await ApiRequestService().get(
        endpoint: 'picking_novelties',
        isunecodePath: true,
        isLoadinDialog: isLoadinDialog,
      );

      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Accede a la clave "data" y luego a "result"

        // Asegúrate de que 'result' exista y sea una lista
        if (jsonResponse.containsKey('result')) {
          List<dynamic> result = jsonResponse['result']['result'];
          // Mapea los datos decodificados a una lista de BatchsModel
          List<Novedad> novedades =
              result.map((data) => Novedad.fromMap(data)).toList();
          return novedades;
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
      } else {
        print('Error getnovedades: response is null');
      }
    } on SocketException catch (e) {
      // Manejo de error de red
      print('Error de red: $e');
      return [];
    } catch (e, s) {
      // Manejo de otros errores
      print('Error getnovedades: $e, $s');
    }
    return [];
  }

  Future<bool> timePickingUser(int batchId, String time, String endpoint,
      String type, int userId) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
      return false; // Si no hay conexión, retornar una lista vacía
    }

    try {
      var response = await ApiRequestService().postPicking(
          endpoint: endpoint,
          isunecodePath: true,
          isLoadinDialog: false,
          body: {
            "params": {
              "id_batch": "$batchId",
              "user_id": "$userId",
              type: time,
              "operation_type": "picking"
            }
          });

      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Accede a la clave "data" y luego a "result"

        // Asegúrate de que 'result' exista y sea una lista
        if (jsonResponse.containsKey('result')) {
          if (jsonResponse['result']['code'] == 400) {
            return false;
          } else if (jsonResponse['result']['code'] == 200) {
            return true;
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
            return false;
          }
        }
      } else {}
    } on SocketException catch (e) {
      // Manejo de error de red
      print('Error de red: $e');
      return false;
    } catch (e, s) {
      // Manejo de otros errores
      print('Error timePickingUser: $e, $s');
    }
    return false;
  }

  Future<bool> timePickingBatch(int batchId, String time, String endpoint,
      String field, String type) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
      return false; // Si no hay conexión, retornar una lista vacía
    }

    try {
      var response = await ApiRequestService().postPicking(
          endpoint: endpoint,
          isunecodePath: true,
          isLoadinDialog: false,
          body: {
            "params": {
              "picking_id": "$batchId",
              type: time,
              "field_name": field,
            }
          });

      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Accede a la clave "data" y luego a "result"

        // Asegúrate de que 'result' exista y sea una lista
        if (jsonResponse.containsKey('result')) {
          if (jsonResponse['result']['code'] == 400) {
            return false;
          } else if (jsonResponse['result']['code'] == 200) {
            return true;
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
            return false;
          }
        }
      } else {}
    } on SocketException catch (e) {
      // Manejo de error de red
      print('Error de red: $e');
      return false;
    } catch (e, s) {
      // Manejo de otros errores

      print('Error timePickingBatch: $e, $s');
    }
    return false;
  }
}
