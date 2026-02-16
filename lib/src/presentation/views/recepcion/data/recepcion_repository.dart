// ignore_for_file: use_build_context_synchronously, unrelated_type_equality_checks

import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_app/src/api/api_request_service.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/recepcion_response_batch_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/recepcion_response_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/repcion_requets_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_deleted_product_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_image_send_novedad_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_lotes_product_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_new_lote_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_sen_temperature_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_send_recepcion_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_temp_ia_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_validate_model.dart';

class RecepcionRepository {
//metodo para obtener todas las ordenes de compra

  Future<Recepcionresponse> fetchAllReceptions(bool isLoadinDialog) async {
    final stopwatch = Stopwatch()..start(); // ⏱ Iniciar conteo

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        print("❌ Sin conexión a Internet.");
        return Recepcionresponse(
            result: RecepcionresponseResult(
                code: 0,
                msg: "Sin conexión a Internet",
                updateVersion: false,
                result: [])); // Retornar un objeto con código 0 y mensaje de error
      }

      final response = await ApiRequestService().getValidation(
        endpoint: 'recepciones',
        isunecodePath: true,
        isLoadinDialog: isLoadinDialog,
      );

      stopwatch.stop(); // ⏹ Finalizar conteo

      if (response.statusCode >= 400) {
        print("❌ Error HTTP: ${response.statusCode}");
        return Recepcionresponse();
      }

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse.containsKey('result')) {
        final result = jsonResponse['result'];

        if (jsonResponse['result']['code'] == 400) {
          return Recepcionresponse(
            jsonrpc: jsonResponse['jsonrpc'],
            id: jsonResponse['id'],
            result: RecepcionresponseResult(
              code: jsonResponse['result']['code'],
              msg: jsonResponse['result']['msg'],
              updateVersion: jsonResponse['result']['update_version'] ?? false,
              result: [],
            ),
          );
        } else if (result['code'] == 200 && result['result'] is List) {
          final List<ResultEntrada> ordenes = (result['result'] as List)
              .map((data) => ResultEntrada.fromMap(data))
              .toList();

          return Recepcionresponse(
            jsonrpc: jsonResponse['jsonrpc'],
            id: jsonResponse['id'],
            result: RecepcionresponseResult(
              code: result['code'],
              result: ordenes,
              updateVersion: result['update_version'] ?? false,
            ),
          );
        } else if (jsonResponse['result']['code'] == 403) {
          return Recepcionresponse(
            jsonrpc: jsonResponse['jsonrpc'],
            id: jsonResponse['id'],
            result: RecepcionresponseResult(
              code: result['code'],
              msg: result['msg'],
              updateVersion: result['update_version'] ?? false,
              result: [],
            ),
          );
        }
      } else if (jsonResponse.containsKey('error')) {
        final error = jsonResponse['error'];
        if (error['code'] == 100) {
          Get.defaultDialog(
            title: 'Alerta',
            titleStyle: const TextStyle(color: Colors.red, fontSize: 18),
            middleText: 'Sesión expirada, por favor inicie sesión nuevamente',
            middleTextStyle: const TextStyle(color: Colors.black, fontSize: 14),
            backgroundColor: Colors.white,
            radius: 10,
            actions: [
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColorApp,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Aceptar',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      }
    } on SocketException catch (e) {
      print('🌐 Error de red: $e');
    } catch (e, s) {
      print('❌ Error general en fetchAllReceptions: $e');
      print('📍 Stack: $s');
    }

    return Recepcionresponse(
        result: RecepcionresponseResult(
            code: 0,
            msg: "Ocurrió un error inesperado",
            updateVersion: false,
            result: [])); // Fallback en todos los casos
  }

  Future<Recepcionresponse> fetchAllDevolutions(bool isLoadinDialog) async {
    final stopwatch = Stopwatch()..start(); // ⏱ Iniciar conteo

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        print("❌ Sin conexión a Internet.");
        return Recepcionresponse(
            result: RecepcionresponseResult(
                code: 0,
                msg: "Sin conexión a Internet",
                updateVersion: false,
                result: [])); // Retornar un objeto con código 0 y mensaje de error
      }

      final response = await ApiRequestService().getValidation(
        endpoint: 'recepciones/devs',
        isunecodePath: true,
        isLoadinDialog: isLoadinDialog,
      );

      stopwatch.stop(); // ⏹ Finalizar conteo
      print(
          "⏱ fetchAllDevolutions completado en ${stopwatch.elapsedMilliseconds} ms");

      if (response.statusCode >= 400) {
        print("❌ Error HTTP: ${response.statusCode}");
        return Recepcionresponse();
      }

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse.containsKey('result')) {
        final result = jsonResponse['result'];

        if (jsonResponse['result']['code'] == 400) {
          return Recepcionresponse(
            jsonrpc: jsonResponse['jsonrpc'],
            id: jsonResponse['id'],
            result: RecepcionresponseResult(
              code: jsonResponse['result']['code'],
              msg: jsonResponse['result']['msg'],
              updateVersion: jsonResponse['result']['update_version'] ?? false,
              result: [],
            ),
          );
        } else if (result['code'] == 200 && result['result'] is List) {
          final List<ResultEntrada> ordenes = (result['result'] as List)
              .map((data) => ResultEntrada.fromMap(data))
              .toList();

          return Recepcionresponse(
            jsonrpc: jsonResponse['jsonrpc'],
            id: jsonResponse['id'],
            result: RecepcionresponseResult(
              code: result['code'],
              updateVersion: result['update_version'] ?? false,
              result: ordenes,
            ),
          );
        } else if (jsonResponse['result']['code'] == 403) {
          return Recepcionresponse(
            jsonrpc: jsonResponse['jsonrpc'],
            id: jsonResponse['id'],
            result: RecepcionresponseResult(
              code: result['code'],
              msg: result['msg'],
              updateVersion: result['update_version'] ?? false,
              result: [],
            ),
          );
        }
      } else if (jsonResponse.containsKey('error')) {
        final error = jsonResponse['error'];
        if (error['code'] == 100) {
          Get.defaultDialog(
            title: 'Alerta',
            titleStyle: const TextStyle(color: Colors.red, fontSize: 18),
            middleText: 'Sesión expirada, por favor inicie sesión nuevamente',
            middleTextStyle: const TextStyle(color: Colors.black, fontSize: 14),
            backgroundColor: Colors.white,
            radius: 10,
            actions: [
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColorApp,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Aceptar',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      }
    } on SocketException catch (e) {
      print('🌐 Error de red: $e');
    } catch (e, s) {
      print('❌ Error general en fetchAllDevolutions: $e');
      print('📍 Stack: $s');
    }

    return Recepcionresponse(
        result: RecepcionresponseResult(
            code: 0,
            msg: "Ocurrió un error inesperado",
            updateVersion: false,
            result: [])); // Fallback en todos los casos
  }

  Future<ResponseReceptionBatchs> fetchAllBatchReceptions(
    bool isLoadinDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
      return ResponseReceptionBatchs(
        jsonrpc: '2.0',
        id: 1,
        result: ResponseReceptionBatchsResult(
          code: 0,
          msg: "No hay conexión a Internet",
          updateVersion: false,
          result: [],
        ),
      ); // Si no hay conexión, retornar una lista vacía
    }

    try {
      var response = await ApiRequestService().getValidation(
        endpoint: 'recepciones/batchs',
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
            return ResponseReceptionBatchs(
              jsonrpc: jsonResponse['jsonrpc'],
              id: jsonResponse['id'],
              result: ResponseReceptionBatchsResult(
                code: jsonResponse['result']['code'],
                updateVersion:
                    jsonResponse['result']['update_version'] ?? false,
                msg: jsonResponse['result']['msg'],
                result: [],
              ),
            );
          } else if (jsonResponse['result']['code'] == 200) {
            List<dynamic> batches = jsonResponse['result']['result'];
            // Mapea los datos decodificados a una lista de BatchsModel
            List<ReceptionBatch> ordenes =
                batches.map((data) => ReceptionBatch.fromMap(data)).toList();
            return ResponseReceptionBatchs(
              jsonrpc: jsonResponse['jsonrpc'],
              id: jsonResponse['id'],
              result: ResponseReceptionBatchsResult(
                code: jsonResponse['result']['code'],
                updateVersion:
                    jsonResponse['result']['update_version'] ?? false,
                result: ordenes,
              ),
            );
          } else if (jsonResponse['result']['code'] == 403) {
            return ResponseReceptionBatchs(
              jsonrpc: jsonResponse['jsonrpc'],
              id: jsonResponse['id'],
              result: ResponseReceptionBatchsResult(
                code: jsonResponse['result']['code'],
                msg: jsonResponse['result']['msg'],
                updateVersion:
                    jsonResponse['result']['update_version'] ?? false,
                result: [],
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
            return ResponseReceptionBatchs(
              jsonrpc: jsonResponse['jsonrpc'],
              id: jsonResponse['id'],
              result: ResponseReceptionBatchsResult(
                code: 100,
                msg: 'Sesión expirada, por favor inicie sesión nuevamente',
                updateVersion: false,
                result: [],
              ),
            );
          }
        }
      } else {}
    } on SocketException catch (e) {
      print('Error de red: $e');
      return ResponseReceptionBatchs(
        jsonrpc: '2.0',
        id: 1,
        result: ResponseReceptionBatchsResult(
          code: 0,
          msg: "Error de red: No se pudo conectar al servidor.",
          updateVersion: false,
          result: [],
        ),
      );
    } catch (e, s) {
      // Manejo de otros errores
      print('Error fetchAllBatchReceptions: $e, $s');
    }
    return ResponseReceptionBatchs(
      jsonrpc: '2.0',
      id: 1,
      result: ResponseReceptionBatchsResult(
        code: 0,
        msg: "Ocurrió un error inesperado",
        updateVersion: false,
        result: [],
      ),
    );
  }

  Future<List<LotesProduct>> fetchAllLotesProduct(
      bool isLoadinDialog, int productId) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
      return []; // Si no hay conexión, retornar una lista vacía
    }

    try {
      var response = await ApiRequestService().get(
        endpoint: 'lotes/$productId',
        isunecodePath: true,
        isLoadinDialog: isLoadinDialog,
      );

      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Accede a la clave "data" y luego a "result"

        // Asegúrate de que 'result' exista y sea una lista
        if (jsonResponse.containsKey('result')) {
          List<dynamic> response = jsonResponse['result']['result'];
          // Mapea los datos decodificados a una lista de BatchsModel
          List<LotesProduct> lotes =
              response.map((data) => LotesProduct.fromMap(data)).toList();

          if (lotes.isNotEmpty) {
            return lotes;
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
      print('Error de red: $e');
      return [];
    } catch (e, s) {
      // Manejo de otros errores
      print('Error lotes de un producto: $e, $s');
    }
    return [];
  }

  //metodo para asignar un usuario a una orden de compra
  Future<bool> assignUserToOrder(
    bool isLoadinDialog,
    int idUser,
    int idRecepcion,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
      return false; // Si no hay conexión, retornar una lista vacía
    }

    try {
      var response = await ApiRequestService().postPacking(
          endpoint: 'asignar_responsable',
          isLoadinDialog: isLoadinDialog,
          body: {
            "params": {
              "id_recepcion": idRecepcion,
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
      print('Error de red: $e');
      return false;
    } catch (e, s) {
      // Manejo de otros errores
      print('Error assignUserToOrder: $e, $s');
    }
    return false;
  }

  Future<bool> assignUserToReceptionBatch(
    bool isLoadinDialog,
    int idUser,
    int idRecepcion,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
      return false; // Si no hay conexión, retornar una lista vacía
    }

    try {
      var response = await ApiRequestService().postPacking(
          endpoint: 'asignar_responsable/batch',
          isLoadinDialog: isLoadinDialog,
          body: {
            "params": {
              "id_batch": idRecepcion,
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
      print('Error de red: $e');
      return false;
    } catch (e, s) {
      // Manejo de otros errores
      print('Error assignUserToOrder: $e, $s');
    }
    return false;
  }
  //metodo para asignar un usuario a una orden de compra por batch

  Future<ResponseNewLote> createLote(
    bool isLoadinDialog,
    int idProduct,
    String nameLote,
    String dateLote,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
      return ResponseNewLote(); // Si no hay conexión, retornar una lista vacía
    }

    try {
      var response = await ApiRequestService().postPacking(
          endpoint: 'create_lote',
          isLoadinDialog: isLoadinDialog,
          body: {
            "params": {
              "id_producto": idProduct,
              "nombre_lote": nameLote,
              "fecha_vencimiento": dateLote,
            }
          });

      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Accede a la clave "data" y luego a "result"

        // Asegúrate de que 'result' exista y sea una lista
        if (jsonResponse.containsKey('result')) {
          if (jsonResponse['result']['code'] == 200) {
            return ResponseNewLote(
              jsonrpc: jsonResponse['jsonrpc'],
              id: jsonResponse['id'],
              result: jsonResponse['result'] != null
                  ? ResponseNewLoteResult.fromMap(jsonResponse['result'])
                  : null,
            );
          } else {
            return ResponseNewLote(
              jsonrpc: jsonResponse['jsonrpc'],
              id: jsonResponse['id'],
              result: jsonResponse['result'] != null
                  ? ResponseNewLoteResult.fromMap(jsonResponse['result'])
                  : null,
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

            return ResponseNewLote();
          }
        }
      }
    } on SocketException catch (e) {
      print('Error de red: $e');
      return ResponseNewLote();
    } catch (e, s) {
      // Manejo de otros errores
      print('Error resBatchsPacking: $e, $s');
    }
    return ResponseNewLote();
  }

  Future<ResponSendRecepcion> sendProductRecepcion(
    RecepcionRequest recepcionRequest,
    bool isLoadingDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("❌ Error: No hay conexión a Internet.");
      return ResponSendRecepcion(
        result: ResponSendRecepcionResult(
          code: 0,
          msg: "No hay conexión a Internet.",
          result: [],
        ),
      );
    }

    try {
      var response = await ApiRequestService().postPacking(
        endpoint: 'send_recepcion',
        body: {
          "params": {
            "id_recepcion": recepcionRequest.idRecepcion,
            "list_items":
                recepcionRequest.listItems.map((item) => item.toMap()).toList(),
          },
        },
        isLoadinDialog: isLoadingDialog,
      );

      if (response.statusCode < 400) {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        var resultData = jsonResponse['result'];

        return ResponSendRecepcion(
          jsonrpc: jsonResponse['jsonrpc'],
          id: jsonResponse['id'],
          result: resultData != null
              ? ResponSendRecepcionResult(
                  code: resultData['code'],
                  msg: resultData['msg'],
                  result: resultData['result'] != null
                      ? List<ResultElement>.from(resultData['result']
                          .map((x) => ResultElement.fromMap(x)))
                      : [],
                )
              : null,
        );
      } else {
        return ResponSendRecepcion(
          result: ResponSendRecepcionResult(
            code: response.statusCode,
            msg: "Error al enviar la recepción. Código: ${response.statusCode}",
            result: [],
          ),
        );
      }
    } on SocketException catch (e) {
      print('❌ Error de red: $e');
      return ResponSendRecepcion(
        result: ResponSendRecepcionResult(
          code: 0,
          msg: "Error de red: No se pudo conectar al servidor.",
          result: [],
        ),
      );
    } catch (e, s) {
      print('❌ Error inesperado: $e\n$s');
      return ResponSendRecepcion(
        result: ResponSendRecepcionResult(
          code: 0,
          msg: "Ocurrió un error inesperado. Error detallado: $e \n$s",
          result: [],
        ),
      );
    }
  }

  //metodo para eliminar una linea ya enviada
  Future<DeletedProduct> deleteProductInWms(
    int idRecepcion,
    List<int> idLineas,
    bool isLoadingDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
      return DeletedProduct(); // Si no hay conexión, terminamos la ejecución
    }

    try {
      final listItemsFormatted = idLineas.map((id) => {"id_move": id}).toList();

      var response = await ApiRequestService().postPacking(
        endpoint: 'update_recepcion',
        body: {
          "params": {
            "id_recepcion": idRecepcion,
            "list_items": listItemsFormatted,
          },
        },
        isLoadinDialog: true,
      );
      if (response.statusCode < 400) {
        print('Se elimino correctamente la linea');
        print('response: ${response.body}');
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Verifica si la respuesta contiene la clave 'result' y convierte la lista correctamente
        var resultData = jsonResponse['result'];

        return DeletedProduct(
          jsonrpc: jsonResponse['jsonrpc'],
          id: jsonResponse['id'],
          result: resultData != null
              ? DeletedProductResult(
                  code: resultData['code'],
                  mensaje: resultData['mensaje'],
                  result: resultData['result'] != null
                      ? List<ProductDeleted>.from(resultData['result']
                          .map((x) => ProductDeleted.fromMap(x)))
                      : [], // Si no hay elementos en 'result', se retorna una lista vacía
                )
              : null, // Si 'result' no existe, asigna null a 'result'
        );
      } else {
        // Manejo de error si la respuesta no es exitosa
        // ...
      }
    } on SocketException catch (e) {
      print('Error de red: $e');
      return DeletedProduct(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      print('Error en deleteProductInWms: $e, $s');
      return DeletedProduct(); // Retornamos un objeto vacío en caso de error de red
    }
    return DeletedProduct(); // Retornamos un objeto vacío en caso de error de red
  }

  Future<ResponSendRecepcion> sendProductRecepcionBatch(
    RecepcionRequest recepcionRequest,
    bool isLoadingDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
      return ResponSendRecepcion(); // Si no hay conexión, terminamos la ejecución
    }

    try {
      var response = await ApiRequestService().postPacking(
        endpoint:
            'send_recepcion/batch', // Cambiado para que sea el endpoint correspondiente
        body: {
          "params": {
            "id_batch": recepcionRequest.idRecepcion,
            "list_items":
                recepcionRequest.listItems.map((item) => item.toMap()).toList(),
          },
        },
        isLoadinDialog: true,
      );
      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Verifica si la respuesta contiene la clave 'result' y convierte la lista correctamente
        var resultData = jsonResponse['result'];

        return ResponSendRecepcion(
          jsonrpc: jsonResponse['jsonrpc'],
          id: jsonResponse['id'],
          result: resultData != null
              ? ResponSendRecepcionResult(
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
      print('Error de red: $e');
      return ResponSendRecepcion(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      print('Error en sendProductRecepcion: $e, $s');
      return ResponSendRecepcion(); // Retornamos un objeto vacío en caso de error de red
    }
    return ResponSendRecepcion(); // Retornamos un objeto vacío en caso de error de red
  }

  Future<bool> sendTime(
    int idRecepcion,
    String field,
    String date,
    bool isLoadingDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
      return true; // Si no hay conexión, terminamos la ejecución
    }

    try {
      var response = await ApiRequestService().postPacking(
        endpoint:
            'update_time_reception', // Cambiado para que sea el endpoint correspondiente
        body: {
          "params": {
            "reception_id": idRecepcion,
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
      print('Error de red: $e');
      return false; // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      print('Error en sendReceptionRequest: $e, $s');
      return false; // Retornamos un objeto vacío en caso de error de red
    }
    return false; // Retornamos un objeto vacío en caso de error de red
  }

  Future<ResponseValidate> validateRecepcion(
    int idRecepcion,
    bool isBackorder,
    bool isLoadingDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
      return ResponseValidate(); // Si no hay conexión, terminamos la ejecución
    }

    try {
      var response = await ApiRequestService().postPacking(
        endpoint:
            'complete_recepcion', // Cambiado para que sea el endpoint correspondiente
        body: {
          "params": {
            "id_recepcion": idRecepcion,
            "crear_backorder": isBackorder,
          }
        },
        isLoadinDialog: true,
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
      print('Error de red: $e');
      return ResponseValidate(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      print('Error en validateRecepcion: $e, $s');
      return ResponseValidate(); // Retornamos un objeto vacío en caso de error de red
    }
    return ResponseValidate(); // Retornamos un objeto vacío en caso de error de red
  }

  //metodo para enviar la temperatura de un lote

  Future<TemperatureSend> sendTemperature(
    dynamic temperature,
    int idMoveLine,
    File imageFile,
    bool isLoadingDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
      return TemperatureSend(); // Si no hay conexión, terminamos la ejecución
    }

    try {
      final response = await ApiRequestService().postMultipart(
          endpoint: 'send_image_linea_recepcion',
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
        print('Error al enviar la temperatura: ${response.statusCode}');
        return TemperatureSend(); // Retornamos un objeto vacío en caso de error
      }
    } on SocketException catch (e) {
      print('Error de red: $e');
      return TemperatureSend(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      print('Error en sendTemperature: $e, $s');
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
      print("Error: No hay conexión a Internet.");
      return TemperatureSend(); // Si no hay conexión, terminamos la ejecución
    }

    try {
      final response = await ApiRequestService().postMultipartManual(
          endpoint: 'send_image_linea_recepcion',
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
        print('Error al enviar la temperatura: ${response.statusCode}');
        return TemperatureSend(); // Retornamos un objeto vacío en caso de error
      }
    } on SocketException catch (e) {
      print('Error de red: $e');
      return TemperatureSend(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      print('Error en sendTemperature: $e, $s');
      return TemperatureSend(); // Retornamos un objeto vacío en caso de error de red
    }
  }

  Future<ImageSendNovedad> sendImageNoved(
    int idMove,
    File imageFile,
    bool isLoadingDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
      return ImageSendNovedad(); // Si no hay conexión, terminamos la ejecución
    }

    try {
      final response = await ApiRequestService().postMultipartDynamic(
        endpoint: 'send_imagen_observation',
        imageFile: imageFile,
        fields: {
          'id_move': idMove,
        },
      );

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
        print('Error al enviar la temperatura: ${response.statusCode}');
        return ImageSendNovedad(); // Retornamos un objeto vacío en caso de error
      }
    } on SocketException catch (e) {
      print('Error de red: $e');
      return ImageSendNovedad(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      print('Error en sendImageNoved: $e, $s');
      return ImageSendNovedad(); // Retornamos un objeto vacío en caso de error de red
    }
  }

  Future<TemperatureIa> getTemperatureWithImage(File imageFile) async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
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
      print('Error de red: $e');
    } catch (e, s) {
      print('Error en getTemperatureWithImage: $e\n$s');
    }

    return TemperatureIa(); // Retorna vacío en caso de fallo
  }
}
