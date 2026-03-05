// ignore_for_file: unrelated_type_equality_checks

import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_app/src/api/api_request_service.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_validate_model.dart';
import 'package:wms_app/src/presentation/views/transferencias/models/requets_transfer_model.dart';
import 'package:wms_app/src/presentation/views/transferencias/models/response_check_availability_model.dart';
import 'package:wms_app/src/presentation/views/transferencias/models/response_delete_line_model.dart';
import 'package:wms_app/src/presentation/views/transferencias/models/response_transfer_send_model.dart';
import 'package:wms_app/src/presentation/views/transferencias/models/response_transferencias.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/models/request_create_trasnfer_model.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/models/response_create_transfer_mode.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/models/response_validate_stock_model.dart';

class TransferenciasRepository {
  Future<ResponseTransferenciasResult> fetAllTransferencias(
    bool isLoadinDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return ResponseTransferenciasResult(); // Si no hay conexión, retornar una lista vacía
    }

    try {
      var response = await ApiRequestService().getValidation(
        endpoint: 'transferencias',
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
            return ResponseTransferenciasResult(
              code: 400,
              msg: jsonResponse['result']['msg'],
              updateVersion: jsonResponse['result']['update_version'] ?? false,
              result: [],
            );
          } else if (jsonResponse['result']['code'] == 200) {
            List<dynamic> batches = jsonResponse['result']['result'];
            // Mapea los datos decodificados a una lista de BatchsModel
            List<ResultTransFerencias> transferencias = batches
                .map((data) => ResultTransFerencias.fromMap(data))
                .toList();

            return ResponseTransferenciasResult(
              code: 200,
              result: transferencias,
              updateVersion: jsonResponse['result']['update_version'] ?? false,
              msg: jsonResponse['result']['msg'] ?? 'Success',
            );
          } else if (jsonResponse['result']['code'] == 403) {
            return ResponseTransferenciasResult(
              code: 403,
              msg: jsonResponse['result']['msg'] ?? 'Error desconocido',
              updateVersion: jsonResponse['result']['update_version'] ?? false,
              result: [],
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
            return ResponseTransferenciasResult(
              updateVersion: jsonResponse['error']['update_version'] ?? false,
              code: 100,
              msg: jsonResponse['error']['msg'] ?? 'Error desconocido',
              result: [],
            );
          }
        }
      } else {}
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
      return ResponseTransferenciasResult(
        updateVersion: false,
        result: [],
        code: 500,
        msg: 'Error de red',
      );
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error fetAllTransferencias: $e, $s');
    }
    return ResponseTransferenciasResult(
      updateVersion: false,
      result: [],
      code: 500,
      msg: 'Error desconocido',
    );
  }

  Future<ResponseTransferenciasResult> fetAllEntradasProducts(
    bool isLoadinDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return ResponseTransferenciasResult(
        result: [],
        code: 500,
        msg: 'Error de red',
        updateVersion: false,
      ); // Si no hay conexión, retornar una lista vacía
    }

    try {
      var response = await ApiRequestService().getValidation(
        endpoint: 'transferencias/producto_terminado',
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
            return ResponseTransferenciasResult(
              code: 400,
              msg: jsonResponse['result']['msg'],
              updateVersion: jsonResponse['result']['update_version'] ?? false,
              result: [],
            );
          } else if (jsonResponse['result']['code'] == 200) {
            List<dynamic> batches = jsonResponse['result']['result'];
            // Mapea los datos decodificados a una lista de BatchsModel
            List<ResultTransFerencias> transferencias = batches
                .map((data) => ResultTransFerencias.fromMap(data))
                .toList();

            return ResponseTransferenciasResult(
                code: 200,
                result: transferencias,
                updateVersion:
                    jsonResponse['result']['update_version'] ?? false,
                msg: jsonResponse['result']['msg'] ?? 'Success');
          } else if (jsonResponse['result']['code'] == 403) {
            return ResponseTransferenciasResult(
              code: 403,
              result: [],
              msg: jsonResponse['result']['msg'] ?? 'Error desconocido',
              updateVersion: jsonResponse['result']['update_version'] ?? false,
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
            return ResponseTransferenciasResult(
              updateVersion: jsonResponse['error']['update_version'] ?? false,
              code: 100,
              msg: jsonResponse['error']['msg'] ?? 'Error desconocido',
              result: [],
            );
          }
        }
      } else {
        return ResponseTransferenciasResult(
          result: [],
          code: 500,
          msg: 'Error del servidor',
          updateVersion: false,
        );
      }
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
      return ResponseTransferenciasResult();
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error fetAllTransferencias: $e, $s');
    }
    return ResponseTransferenciasResult(
      result: [],
      code: 500,
      msg: 'Error desconocido',
      updateVersion: false,
    );
  }

  Future<bool> sendTime(
    int idTransfer,
    String field,
    String date,
    bool isLoadingDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return true; // Si no hay conexión, terminamos la ejecución
    }

    try {
      var response = await ApiRequestService().postPacking(
        endpoint:
            'update_time_transfer', // Cambiado para que sea el endpoint correspondiente
        body: {
          "params": {
            "transfer_id": idTransfer,
            "time": date,
            "field_name": field
            // "field_name": "end_time_reception"
          }
        },
        isLoadinDialog: false,
      );
      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('result')) {
          if (jsonResponse['result']['code'] == 200) {
            return true;
          } else {
            return false;
          }
        } else if (jsonResponse.containsKey('error')) {
          if (jsonResponse['error']['code'] == 100) {
            //mostramos una alerta de get
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
      } else {
        // Manejo de error si la respuesta no es exitosa
        // ...
      }
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
      return false; // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error en sendTransferRequest: $e, $s');
      return false; // Retornamos un objeto vacío en caso de error de red
    }
    return false; // Retornamos un objeto vacío en caso de error de red
  }

  //metodo para asignar un usuario a una orden de compra
  Future<bool> assignUserToTransfer(
    bool isLoadinDialog,
    int idUser,
    int idTransfer,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return false; // Si no hay conexión, retornar una lista vacía
    }

    try {
      var response = await ApiRequestService().postPacking(
          endpoint: 'transferencias/asignar',
          isLoadinDialog: isLoadinDialog,
          body: {
            "params": {
              "id_transferencia": idTransfer,
              "id_responsable": idUser,
            }
          });

      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Accede a la clave "data" y luego a "result"

        // Asegúrate de que 'result' exista y sea una lista
        if (jsonResponse.containsKey('result')) {
          if (jsonResponse['result']['code'] == 200) {
            return true;
          } else {
            return false;
          }
        } else if (jsonResponse.containsKey('error')) {
          if (jsonResponse['error']['code'] == 100) {
            //mostramos una alerta de get
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
      debugPrint('Error de red: $e');
      return false;
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error assignUserToTransfer: $e, $s');
    }
    return false;
  }

//metodo para enviar los productos recepcionados de la orden de entrada
  Future<ResponseSenTransfer> sendProductTransfer(
    TransferRequest transferRequest,
    bool isLoadingDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return ResponseSenTransfer(); // Si no hay conexión, terminamos la ejecución
    }

    debugPrint("transferRequest ${transferRequest.toMap()}");

    try {
      var response = await ApiRequestService().postPacking(
        endpoint:
            'send_transfer', // Cambiado para que sea el endpoint correspondiente
        body: {
          "params": {
            "id_transferencia": transferRequest.idTransferencia,
            "list_items":
                transferRequest.listItems.map((item) => item.toMap()).toList(),
          },
        },
        isLoadinDialog: true,
      );
      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Verifica si la respuesta contiene la clave 'result' y convierte la lista correctamente
        var resultData = jsonResponse['result'];

        return ResponseSenTransfer(
          jsonrpc: jsonResponse['jsonrpc'],
          id: jsonResponse['id'],
          result: resultData != null
              ? ResponseSenTransferResult(
                  code: resultData['code'],
                  msg: resultData['msg'],
                  result: resultData['result'] != null
                      ? List<ResultElement>.from(resultData['result']
                          .map((x) => ResultElement.fromMap(x)))
                      : [], // Si no hay elementos en 'result', se retorna una lista vacía
                )
              : null, // Si 'result' no existe, asigna null a 'result'
        );
      }
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
      return ResponseSenTransfer(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error en sendProductTransfer: $e, $s');
      return ResponseSenTransfer(); // Retornamos un objeto vacío en caso de error de red
    }
    return ResponseSenTransfer(); // Retornamos un objeto vacío en caso de error de red
  }

  Future<ResponseSenTransfer> sendProductTransferPick(
    TransferRequest transferRequest,
    bool isLoadingDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return ResponseSenTransfer(); // Si no hay conexión, terminamos la ejecución
    }

    debugPrint("transferRequest pick ${transferRequest.toMap()}");

    try {
      var response = await ApiRequestService().postPacking(
        endpoint:
            'send_transfer/pick', // Cambiado para que sea el endpoint correspondiente
        body: {
          "params": {
            "id_transferencia": transferRequest.idTransferencia,
            "list_items":
                transferRequest.listItems.map((item) => item.toMap()).toList(),
          },
        },
        isLoadinDialog: isLoadingDialog,
      );
      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Verifica si la respuesta contiene la clave 'result' y convierte la lista correctamente
        var resultData = jsonResponse['result'];
        return ResponseSenTransfer(
          jsonrpc: jsonResponse['jsonrpc'],
          id: jsonResponse['id'],
          result: resultData != null
              ? ResponseSenTransferResult(
                  code: resultData['code'],
                  msg: resultData['msg'],
                  result: resultData['result'] != null
                      ? List<ResultElement>.from(resultData['result']
                          .map((x) => ResultElement.fromMap(x)))
                      : [], // Si no hay elementos en 'result', se retorna una lista vacía
                )
              : null, // Si 'result' no existe, asigna null a 'result'
        );
      }
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
      return ResponseSenTransfer(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error en sendProductTransfer: $e, $s');
      return ResponseSenTransfer(); // Retornamos un objeto vacío en caso de error de red
    }
    return ResponseSenTransfer(); // Retornamos un objeto vacío en caso de error de red
  }

  Future<ResponseValidate> validateTransfer(
    int idTransfer,
    bool isBackorder,
    bool isLoadingDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return ResponseValidate(); // Si no hay conexión, terminamos la ejecución
    }

    try {
      var response = await ApiRequestService().postPacking(
        endpoint:
            'complete_transfer', // Cambiado para que sea el endpoint correspondiente
        body: {
          "params": {
            "id_transferencia": idTransfer,
            "crear_backorder": isBackorder,
          }
        },
        isLoadinDialog: isLoadingDialog,
      );
      if (response.statusCode <= 500) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('result')) {
          return ResponseValidate(
            jsonrpc: jsonResponse['jsonrpc'],
            result: jsonResponse['result'] != null
                ? ResultValidate.fromMap(jsonResponse['result'])
                : null,
          );
        } else if (jsonResponse.containsKey('error')) {
          if (jsonResponse['error']['code'] == 100) {
            //mostramos una alerta de get
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

            return ResponseValidate();
          }
        }
      }
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
      return ResponseValidate(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error en validateTransfer: $e, $s');
      return ResponseValidate(); // Retornamos un objeto vacío en caso de error de red
    }
    return ResponseValidate(); // Retornamos un objeto vacío en caso de error de red
  }

  Future<ResponseValidate> confirmationValidate(
    int idTransfer,
    bool isBackorder,
    bool isLoadingDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return ResponseValidate(); // Si no hay conexión, terminamos la ejecución
    }

    try {
      var response = await ApiRequestService().postPacking(
        endpoint:
            'complete_transfer/expire', // Cambiado para que sea el endpoint correspondiente
        body: {
          "params": {
            "id_transferencia": idTransfer,
            "crear_backorder": isBackorder,
          }
        },
        isLoadinDialog: isLoadingDialog,
      );
      if (response.statusCode <= 500) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('result')) {
          return ResponseValidate(
            jsonrpc: jsonResponse['jsonrpc'],
            result: jsonResponse['result'] != null
                ? ResultValidate.fromMap(jsonResponse['result'])
                : null,
          );
        } else if (jsonResponse.containsKey('error')) {
          if (jsonResponse['error']['code'] == 100) {
            //mostramos una alerta de get
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

            return ResponseValidate();
          }
        }
      }
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
      return ResponseValidate(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error en validateTransfer: $e, $s');
      return ResponseValidate(); // Retornamos un objeto vacío en caso de error de red
    }
    return ResponseValidate(); // Retornamos un objeto vacío en caso de error de red
  }

  Future<CheckAvailabilityResponseResult> checkAvailability(
    int idTransfer,
    bool isLoadingDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return CheckAvailabilityResponseResult(); // Si no hay conexión, terminamos la ejecución
    }

    try {
      var response = await ApiRequestService().postPacking(
        endpoint:
            'comprobar_disponibilidad', // Cambiado para que sea el endpoint correspondiente
        body: {
          "params": {
            "id_transferencia": idTransfer,
          }
        },
        isLoadinDialog: isLoadingDialog,
      );
      if (response.statusCode <= 500) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('result')) {
          return CheckAvailabilityResponseResult(
            code: jsonResponse['result']['code'],
            msg: jsonResponse['result']['msg'],
            result: jsonResponse['result']['result'] != null
                ? ResultTransFerencias.fromMap(jsonResponse['result']['result'])
                : null,
          );
        } else if (jsonResponse.containsKey('error')) {
          if (jsonResponse['error']['code'] == 100) {
            //mostramos una alerta de get
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

            return CheckAvailabilityResponseResult();
          }
        }
      }
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
      return CheckAvailabilityResponseResult(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error en checkAvailability: $e, $s');
      return CheckAvailabilityResponseResult(); // Retornamos un objeto vacío en caso de error de red
    }
    return CheckAvailabilityResponseResult(); // Retornamos un objeto vacío en caso de error de red
  }

//metodo para eliminar una linea de transferencia
  Future<ResponseDeleteLine> deleteLineTransfer(
    int idMove,
    bool isLoadingDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return ResponseDeleteLine(); // Si no hay conexión, terminamos la ejecución
    }

    try {
      var response = await ApiRequestService().postPacking(
        endpoint:
            'transferencias/delete_line', // Cambiado para que sea el endpoint correspondiente
        body: {
          "params": {
            "id_linea": idMove,
          }
        },
        isLoadinDialog: isLoadingDialog,
      );
      if (response.statusCode <= 500) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('result')) {
          if (jsonResponse['result']['code'] == 200) {
            return ResponseDeleteLine(
              result: ResponseDeleteLineResult(
                  code: jsonResponse['result']['code'],
                  msg: jsonResponse['result']['msg'],
                  result:
                      ResultResult.fromMap(jsonResponse['result']['result'])),
            );
          } else {
            return ResponseDeleteLine(
              result: ResponseDeleteLineResult(
                code: jsonResponse['result']['code'],
                msg: jsonResponse['result']['msg'],
                result: null,
              ),
            );
          }
        } else if (jsonResponse.containsKey('error')) {
          if (jsonResponse['error']['code'] == 100) {
            //mostramos una alerta de get
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

            return ResponseDeleteLine();
          }
        }
      }
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
      return ResponseDeleteLine(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error en deleteLineTransfer: $e, $s');
      return ResponseDeleteLine(); // Retornamos un objeto vacío en caso de error de red
    }
    return ResponseDeleteLine(); // Retornamos un objeto vacío en caso de error de red
  }

//endpoint para crear una transferencia

  Future<RespondeCreateTransfer> createTransfer(
    CreateTransferRequest request,
    bool isLoadingDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return RespondeCreateTransfer(); // Si no hay conexión, terminamos la ejecución
    }

    try {
      var response = await ApiRequestService().postPacking(
        endpoint:
            'transferencias/create_trasferencia', // Cambiado para que sea el endpoint correspondiente
        body: {
          "params": {
            "date_start": request.dateStart,
            "date_end": request.dateEnd,
            "id_almacen": request.idAlmacen,
            "id_ubicacion_origen": request.idUbicacionOrigen,
            "id_ubicacion_destino": request.idUbicacionDestino,
            "id_operario": request.idOperario,
            "fecha_transaccion": request.fechaTransaccion,
            "list_items":
                request.listItems.map((item) => item.toMap()).toList(),
          }
        },
        isLoadinDialog: isLoadingDialog,
      );
      if (response.statusCode <= 500) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('result')) {
          return RespondeCreateTransfer(
            jsonrpc: jsonResponse['jsonrpc'],
            id: jsonResponse['id'],
            result: jsonResponse['result'] != null
                ? Result.fromMap(jsonResponse['result'])
                : null,
          );
        } else if (jsonResponse.containsKey('error')) {
          if (jsonResponse['error']['code'] == 100) {
            //mostramos una alerta de get
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

            return RespondeCreateTransfer();
          }
        }
      }
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
      return RespondeCreateTransfer(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error en checkAvailability: $e, $s');
      return RespondeCreateTransfer(); // Retornamos un objeto vacío en caso de error de red
    }
    return RespondeCreateTransfer();
  }

  //metodo para validar si unproducto tiene stock suficiente en la transferencia
  Future<RespondeValidateStock> validateStockTransfer(
    int idProducto,
    int idUbicacion,
    int idLote,
    dynamic cantidad,
    bool isLoadingDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return RespondeValidateStock(); // Si no hay conexión, terminamos la ejecución
    }

    try {
      var response = await ApiRequestService().getInfo(
        endpoint:
            'validar_stock', // Cambiado para que sea el endpoint correspondiente
        body: {
          "params": {
            "id_producto": idProducto,
            "id_ubicacion": idUbicacion,
            "id_lote": idLote,
            "cantidad_requerida": cantidad,
          }
        },
        isLoadinDialog: isLoadingDialog,
      );
      if (response.statusCode <= 500) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('result')) {
          if (jsonResponse['result']['code'] == 200) {
            return RespondeValidateStock.fromMap(jsonResponse);
          } else {
            return RespondeValidateStock.fromMap(jsonResponse);
          }
        } else if (jsonResponse.containsKey('error')) {
          if (jsonResponse['error']['code'] == 100) {
            //mostramos una alerta de get
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

            return RespondeValidateStock();
          }
        }
      }
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
      return RespondeValidateStock(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error en validateStockTransfer: $e, $s');
      return RespondeValidateStock(); // Retornamos un objeto vacío en caso de error de
    }
    return RespondeValidateStock(); // Retornamos un objeto vacío en caso de error de
  }
}
