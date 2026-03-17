// ignore_for_file: avoid_print, unrelated_type_equality_checks, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_app/src/api/api_request_service.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_image_send_novedad_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_sen_temperature_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_temp_ia_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_validate_model.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/packing_response_model.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/response_packing_pedido_model.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/response_sedn_packing.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/response_send_pack_model.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/sen_pack_request.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/sen_packing_request.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/un_pack_request.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/un_packing_request.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/unpacking_response_model.dart';

class WmsPackingRepository {
  //metodo para obtener todos los batch de packing con sus pedidos y productos
  Future<PackingModelResponseResult> resBatchsPacking(
    bool isLoadinDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return PackingModelResponseResult(
          code: 500,
          result: [],
          msg: 'No hay conexión a Internet',
          updateVersion: false);
    }

    try {
      var response = await ApiRequestService().getValidation(
        endpoint: 'batch_packing',
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
            return PackingModelResponseResult(
                code: 400,
                result: [],
                msg: jsonResponse['result']['msg'] ?? 'Error desconocido',
                updateVersion:
                    jsonResponse['result']['update_version'] ?? false);
          } else if (jsonResponse['result']['code'] == 200) {
            List<dynamic> batches = jsonResponse['result']['result'];
            // Mapea los datos decodificados a una lista de BatchsModel
            List<BatchPackingModel> batchs =
                batches.map((data) => BatchPackingModel.fromMap(data)).toList();

            return PackingModelResponseResult(
              code: 200,
              result: batchs,
              msg: 'Batches obtenidos correctamente',
              updateVersion: jsonResponse['result']['update_version'] ?? false,
            );
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

            return PackingModelResponseResult(
                code: 403,
                result: [],
                msg: 'Dispositivo no autorizado',
                updateVersion: false);
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
            return PackingModelResponseResult(
                code: 100,
                result: [],
                msg: 'Sesion expirada, por favor inicie sesión nuevamente',
                updateVersion: false);
          }
        }
      } else {}
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
      return PackingModelResponseResult(
          code: 500, result: [], msg: 'Error de red: $e', updateVersion: false);
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error resBatchsPacking: $e, $s');
    }
    return PackingModelResponseResult(
        code: 500, result: [], msg: 'Error desconocido', updateVersion: false);
  }

  Future<PackingModelResponseResult> resBatchsPackingConsolidate(
    bool isLoadinDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return PackingModelResponseResult(
          code: 500,
          result: [],
          msg: 'No hay conexión a Internet',
          updateVersion: false);
    }

    try {
      var response = await ApiRequestService().getValidation(
        endpoint: 'batch_packing_unificado',
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
            return PackingModelResponseResult(
                code: 400,
                result: [],
                msg: jsonResponse['result']['msg'] ?? 'Error desconocido',
                updateVersion:
                    jsonResponse['result']['update_version'] ?? false);
          } else if (jsonResponse['result']['code'] == 200) {
            List<dynamic> batches = jsonResponse['result']['result'];
            // Mapea los datos decodificados a una lista de BatchsModel
            List<BatchPackingModel> batchs =
                batches.map((data) => BatchPackingModel.fromMap(data)).toList();

            return PackingModelResponseResult(
              code: 200,
              result: batchs,
              msg: 'Batches obtenidos correctamente',
              updateVersion: jsonResponse['result']['update_version'] ?? false,
            );
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

            return PackingModelResponseResult(
                code: 403,
                result: [],
                msg: 'Dispositivo no autorizado',
                updateVersion: false);
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
            return PackingModelResponseResult(
                code: 100,
                result: [],
                msg: 'Sesion expirada, por favor inicie sesión nuevamente',
                updateVersion: false);
          }
        }
      } else {}
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
      return PackingModelResponseResult(
          code: 500, result: [], msg: 'Error de red: $e', updateVersion: false);
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error resBatchsPacking consolidate: $e, $s');
    }
    return PackingModelResponseResult(
        code: 500, result: [], msg: 'Error desconocido', updateVersion: false);
  }

  Future<PackingPedidoResult> resPackingPedido(
    bool isLoadinDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return PackingPedidoResult(
          code: 500, msg: 'No hay conexión a Internet', updateVersion: false);
    }

    try {
      var response = await ApiRequestService().getValidation(
        endpoint: 'transferencias/pack',
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
            return PackingPedidoResult(
                code: 400,
                msg: jsonResponse['result']['msg'] ?? 'Error desconocido',
                updateVersion:
                    jsonResponse['result']['update_version'] ?? false);
          } else if (jsonResponse['result']['code'] == 200) {
            final List<dynamic> rawBatches = jsonResponse['result']['result'];
            final List<PedidoPackingResult> pedidos = rawBatches
                .map((data) =>
                    PedidoPackingResult.fromMap(data as Map<String, dynamic>))
                .toList();

            return PackingPedidoResult(
              code: 200,
              msg: 'Pedidos obtenidos correctamente',
              result: pedidos,
              updateVersion: jsonResponse['result']['update_version'] ?? false,
            );
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
          return PackingPedidoResult(
              code: 403,
              msg: 'Dispositivo no autorizado',
              updateVersion: false);
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
            return PackingPedidoResult(
                code: 100,
                msg: 'Sesion expirada, por favor inicie sesión nuevamente',
                updateVersion: false);
          }
        }
      } else {}
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
      return PackingPedidoResult(
          code: 500, msg: 'Error de red: $e', updateVersion: false);
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error resPackingPedido: $e, $s');
    }
    return PackingPedidoResult(
        code: 500, msg: 'Error desconocido', updateVersion: false);
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

  Future<bool> sendTimePack(
    int idPedido,
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
            "transfer_id": idPedido,
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

//endpoint para desempacar productos de su caja
  Future<UnPacking> unPacking(
    UnPackingRequest request,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return UnPacking(); // Si no hay conexión, terminamos la ejecución
    }

    try {
      var response = await ApiRequestService().postPacking(
        endpoint:
            'unpacking', // Cambiado para que sea el endpoint correspondiente
        body: {
          "params": {
            "id_batch": request.idBatch,
            "id_paquete": request.idPaquete,
            "list_item": request.listItem.map((item) => item.toMap()).toList(),
          },
        },
        isLoadinDialog: true,
      );
      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Verifica si la respuesta contiene la clave 'result' y convierte la lista correctamente
        var resultData = jsonResponse['result'];

        return UnPacking(
            jsonrpc: jsonResponse['jsonrpc'],
            id: jsonResponse['id'],
            result: UnPackingResult(
              code: resultData['code'],
              result: resultData['result'] != null
                  ? List<UnPackingElement>.from(resultData['result']
                      .map((x) => UnPackingElement.fromMap(x)))
                  : [], // Si no hay elementos en 'result', se retorna una lista vacía
            ));
      } else {
        // Manejo de error si la respuesta no es exitosa
        // ...
      }
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
      return UnPacking(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error en unPacking: $e, $s');
      return UnPacking(); // Retornamos un objeto vacío en caso de error de red
    }
    return UnPacking(); // Retornamos un objeto vacío en caso de error de red
  }

  Future<UnPacking> unPackingConsolidate(
    UnPackingRequest request,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return UnPacking(); // Si no hay conexión, terminamos la ejecución
    }

    try {
      var response = await ApiRequestService().postPacking(
        endpoint:
            'unpack_unified', // Cambiado para que sea el endpoint correspondiente
        body: {
          "params": {
            "id_batch": request.idBatch,
            "id_paquete": request.idPaquete,
            "list_item": request.listItem.map((item) => item.toMap()).toList(),
          },
        },
        isLoadinDialog: true,
      );
      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Verifica si la respuesta contiene la clave 'result' y convierte la lista correctamente
        var resultData = jsonResponse['result'];

        return UnPacking(
            jsonrpc: jsonResponse['jsonrpc'],
            id: jsonResponse['id'],
            result: UnPackingResult(
              code: resultData['code'],
              result: resultData['result'] != null
                  ? List<UnPackingElement>.from(resultData['result']
                      .map((x) => UnPackingElement.fromMap(x)))
                  : [], // Si no hay elementos en 'result', se retorna una lista vacía
            ));
      } else {
        // Manejo de error si la respuesta no es exitosa
        // ...
      }
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
      return UnPacking(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error en unPacking: $e, $s');
      return UnPacking(); // Retornamos un objeto vacío en caso de error de red
    }
    return UnPacking(); // Retornamos un objeto vacío en caso de error de red
  }

  Future<UnPacking> unPack(
    UnPackRequest request,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return UnPacking(); // Si no hay conexión, terminamos la ejecución
    }

    try {
      var response = await ApiRequestService().postPacking(
        endpoint:
            'transferencias/unpacking', // Cambiado para que sea el endpoint correspondiente
        body: {
          "params": {
            "id_transferencia": request.idTransferencia,
            "id_paquete": request.idPaquete,
            "list_items":
                request.listItems.map((item) => item.toMap()).toList(),
          },
        },
        isLoadinDialog: true,
      );
      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Verifica si la respuesta contiene la clave 'result' y convierte la lista correctamente
        var resultData = jsonResponse['result'];

        return UnPacking(
            jsonrpc: jsonResponse['jsonrpc'],
            id: jsonResponse['id'],
            result: UnPackingResult(
              code: resultData['code'],
              result: resultData['result'] != null
                  ? List<UnPackingElement>.from(resultData['result']
                      .map((x) => UnPackingElement.fromMap(x)))
                  : [], // Si no hay elementos en 'result', se retorna una lista vacía
            ));
      } else {
        // Manejo de error si la respuesta no es exitosa
        // ...
      }
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
      return UnPacking(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error en unPacking: $e, $s');
      return UnPacking(); // Retornamos un objeto vacío en caso de error de red
    }
    return UnPacking(); // Retornamos un objeto vacío en caso de error de red
  }

  //endpoint para enviar los productos dentro del paquete anteriormente creado
  Future<ResponseSendPacking> sendPackingRequest(
    PackingRequest packingRequest,
    bool isLoadingDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return ResponseSendPacking(); // Si no hay conexión, terminamos la ejecución
    }

    try {
      var response = await ApiRequestService().postPacking(
        endpoint:
            'send_packing', // Cambiado para que sea el endpoint correspondiente
        body: {
          "params": {
            "id_batch": packingRequest.idBatch,
            "is_sticker": packingRequest.isSticker,
            "is_certificate": packingRequest.isCertificate,
            "peso_total_paquete": packingRequest.pesoTotalPaquete,
            "list_item":
                packingRequest.listItem.map((item) => item.toMap()).toList(),
          },
        },
        isLoadinDialog: true,
      );
      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Verifica si la respuesta contiene la clave 'result' y convierte la lista correctamente
        var resultData = jsonResponse['result'];

        return ResponseSendPacking(
          jsonrpc: jsonResponse['jsonrpc'],
          id: jsonResponse['id'],
          result: resultData != null
              ? ResponseSendPackingResult(
                  code: resultData['code'],
                  msg: resultData['msg'],
                  result: resultData['result'] != null
                      ? List<ResultElement>.from(resultData['result']
                          .map((x) => ResultElement.fromMap(x)))
                      : [], // Si no hay elementos en 'result', se retorna una lista vacía
                )
              : null, // Si 'result' no existe, asigna null a 'result'
        );
      } else {
        // Manejo de error si la respuesta no es exitosa
        // ...
      }
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
      return ResponseSendPacking(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error en sendPackingRequest: $e, $s');
      return ResponseSendPacking(); // Retornamos un objeto vacío en caso de error de red
    }
    return ResponseSendPacking(); // Retornamos un objeto vacío en caso de error de red
  }

  Future<ResponseSendPacking> sendPackingConsolidateRequest(
    PackingRequest packingRequest,
    bool isLoadingDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return ResponseSendPacking(); // Si no hay conexión, terminamos la ejecución
    }

    try {
      var response = await ApiRequestService().postPacking(
        endpoint:
            'send_pack_unified', // Cambiado para que sea el endpoint correspondiente
        body: {
          "params": {
            "id_batch": packingRequest.idBatch,
            "is_sticker": packingRequest.isSticker,
            "is_certificate": packingRequest.isCertificate,
            "peso_total_paquete": packingRequest.pesoTotalPaquete,
            "list_item":
                packingRequest.listItem.map((item) => item.toMap()).toList(),
          },
        },
        isLoadinDialog: true,
      );
      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Verifica si la respuesta contiene la clave 'result' y convierte la lista correctamente
        var resultData = jsonResponse['result'];

        return ResponseSendPacking(
          jsonrpc: jsonResponse['jsonrpc'],
          id: jsonResponse['id'],
          result: resultData != null
              ? ResponseSendPackingResult(
                  code: resultData['code'],
                  msg: resultData['msg'],
                  result: resultData['result'] != null
                      ? List<ResultElement>.from(resultData['result']
                          .map((x) => ResultElement.fromMap(x)))
                      : [], // Si no hay elementos en 'result', se retorna una lista vacía
                )
              : null, // Si 'result' no existe, asigna null a 'result'
        );
      } else {
        // Manejo de error si la respuesta no es exitosa
        // ...
      }
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
      return ResponseSendPacking(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error en sendPackingRequest: $e, $s');
      return ResponseSendPacking(); // Retornamos un objeto vacío en caso de error de red
    }
    return ResponseSendPacking(); // Retornamos un objeto vacío en caso de error de red
  }

  Future<ResponseSendPack> sendPackRequest(
    PackingPackRequest packingRequest,
    bool isLoadingDialog,
    bool isCluster,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return ResponseSendPack(); // Si no hay conexión, terminamos la ejecución
    }

    try {
      var response = await ApiRequestService().postPacking(
        endpoint: isCluster
            ? 'send_cluster/pack'
            : 'send_transfer/pack', // Cambiado para que sea el endpoint correspondiente
        body: {
          "params": {
            "id_transferencia": packingRequest.idTransferencia,
            "is_sticker": packingRequest.isSticker,
            "is_certificate": packingRequest.isCertificate,
            "tipo_paquete": packingRequest.tipoEmpaque,
            "peso_caja": packingRequest.pesoCaja,
            "peso_total_paquete": packingRequest.pesoTotalPaquete,
            "list_items":
                packingRequest.listItems.map((item) => item.toMap()).toList(),
          },
        },
        isLoadinDialog: true,
      );
      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Verifica si la respuesta contiene la clave 'result' y convierte la lista correctamente
        var resultData = jsonResponse['result'];

        return ResponseSendPack(
          jsonrpc: jsonResponse['jsonrpc'],
          id: jsonResponse['id'],
          result: resultData != null
              ? ResponseSendPackResult(
                  code: resultData['code'],
                  msg: resultData['msg'],
                  result: resultData['result'] != null
                      ? List<ResultElementPack>.from(resultData['result']
                          .map((x) => ResultElementPack.fromMap(x)))
                      : [], // Si no hay elementos en 'result', se retorna una lista vacía
                )
              : null, // Si 'result' no existe, asigna null a 'result'
        );
      } else {
        // Manejo de error si la respuesta no es exitosa
        // ...
      }
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
      return ResponseSendPack(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error en sendPackRequest: $e, $s');
      return ResponseSendPack(); // Retornamos un objeto vacío en caso de error de red
    }
    return ResponseSendPack(); // Retornamos un objeto vacío en caso de error de red
  }

  Future<bool> timePackingUser(int batchId, String time, String endpoint,
      String type, int userId) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
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
              "operation_type": "packing"
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
      debugPrint('Error de red: $e');
      return false;
    } catch (e, s) {
      // Manejo de otros errores

      debugPrint('Error timePackingUser: $e, $s');
    }
    return false;
  }

  Future<bool> timePackingBatch(int batchId, String time, String endpoint,
      String field, String type) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
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
      debugPrint('Error de red: $e');
      return false;
    } catch (e, s) {
      // Manejo de otros errores

      debugPrint('Error timePackingBatch: $e, $s');
    }
    return false;
  }

  Future<TemperatureIa> getTemperatureWithImage(File imageFile) async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return TemperatureIa();
    }

    try {
      final response = await ApiRequestService().postMultipartImage(
        endpoint: 'extract-temp-humidity',
        imageFile: imageFile,
        isLoadinDialog: true,
      );

      if (response.statusCode == 200) {
        return TemperatureIa.fromMap(jsonDecode(response.body));
      } else {
        return TemperatureIa.fromMap(jsonDecode(response.body));
      }
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
    } catch (e, s) {
      debugPrint('Error en getTemperatureWithImage: $e\n$s');
    }

    return TemperatureIa(); // Retorna vacío en caso de fallo
  }

  Future<ImageSendNovedad> sendImageNoved(
    int idMove,
    File imageFile,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return ImageSendNovedad(); // Si no hay conexión, terminamos la ejecución
    }

    try {
      final response = await ApiRequestService().postMultipartDynamic(
          endpoint: 'send_imagen_observation/batch',
          imageFile: imageFile,
          fields: {
            'move_line_id': idMove,
          },
          isLoadingDialog: true);

      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa

        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Verifica si la respuesta contiene la clave 'result' y convierte la lista correctamente

        if (jsonResponse['code'] == 400) {
          return ImageSendNovedad(
            msg: jsonResponse['msg'],
            code: jsonResponse['code'],
          );
        } else if (jsonResponse['code'] == 200) {
          return ImageSendNovedad(
            code: jsonResponse['code'],
            result: jsonResponse['result'],
            imageUrl: jsonResponse['image_url'],
            stockMoveLineId: jsonResponse['stock_move_line_id'],
            stockMoveId: jsonResponse['stock_move_id'],
            filename: jsonResponse['filename'],
          );
        } else {
          return ImageSendNovedad(); // Retornamos un objeto vacío en caso de error
        }
      } else {
        // Manejo de error si la respuesta no es exitosa
        debugPrint('Error al enviar la temperatura: ${response.statusCode}');
        return ImageSendNovedad(); // Retornamos un objeto vacío en caso de error
      }
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
      return ImageSendNovedad(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error en sendImageNoved: $e, $s');
      return ImageSendNovedad(); // Retornamos un objeto vacío en caso de error de red
    }
  }

  Future<TemperatureSend> sendTemperature(
    dynamic temperature,
    int idMoveLine,
    File imageFile,
    bool isLoadingDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return TemperatureSend(); // Si no hay conexión, terminamos la ejecución
    }

    try {
      final response = await ApiRequestService().postMultipart(
          endpoint: 'send_image_linea_recepcion/batch',
          imageFile: imageFile,
          idMoveLine: idMoveLine,
          temperature: temperature,
          isLoadinDialog: isLoadingDialog);

      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa

        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Verifica si la respuesta contiene la clave 'result' y convierte la lista correctamente

        if (jsonResponse['code'] == 400) {
          return TemperatureSend(
            msg: jsonResponse['msg'],
            code: jsonResponse['code'],
          );
        } else if (jsonResponse['code'] == 200) {
          return TemperatureSend(
            code: jsonResponse['code'],
            result: jsonResponse['result'],
            lineId: jsonResponse['line_id'],
            imageUrl: jsonResponse['image_url'],
          );
        } else {
          return TemperatureSend(); // Retornamos un objeto vacío en caso de error
        }
      } else {
        // Manejo de error si la respuesta no es exitosa
        debugPrint('Error al enviar la temperatura: ${response.statusCode}');
        return TemperatureSend(); // Retornamos un objeto vacío en caso de error
      }
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
      return TemperatureSend(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error en sendTemperature: $e, $s');
      return TemperatureSend(); // Retornamos un objeto vacío en caso de error de red
    }
  }

  Future<TemperatureSend> sendTemperatureManual(
    dynamic temperature,
    int idMoveLine,
    bool isLoadingDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return TemperatureSend(); // Si no hay conexión, terminamos la ejecución
    }

    try {
      final response = await ApiRequestService().postMultipartManual(
          endpoint: 'send_image_linea_recepcion/batch',
          idMoveLine: idMoveLine,
          temperature: temperature,
          isLoadinDialog: isLoadingDialog);

      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa

        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Verifica si la respuesta contiene la clave 'result' y convierte la lista correctamente

        if (jsonResponse['code'] == 400) {
          return TemperatureSend(
            msg: jsonResponse['msg'],
            code: jsonResponse['code'],
          );
        } else if (jsonResponse['code'] == 200) {
          return TemperatureSend(
            code: jsonResponse['code'],
            result: jsonResponse['result'],
            lineId: jsonResponse['line_id'],
            imageUrl: jsonResponse['image_url'],
          );
        } else {
          return TemperatureSend(); // Retornamos un objeto vacío en caso de error
        }
      } else {
        // Manejo de error si la respuesta no es exitosa
        debugPrint('Error al enviar la temperatura: ${response.statusCode}');
        return TemperatureSend(); // Retornamos un objeto vacío en caso de error
      }
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
      return TemperatureSend(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error en sendTemperature: $e, $s');
      return TemperatureSend(); // Retornamos un objeto vacío en caso de error de red
    }
  }
}
