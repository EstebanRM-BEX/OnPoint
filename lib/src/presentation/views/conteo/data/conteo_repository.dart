// ignore_for_file: unrelated_type_equality_checks

import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_app/src/api/api_request_service.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/conteo/models/conteo_response_model.dart';
import 'package:wms_app/src/presentation/views/conteo/models/request_send_product_model.dart';
import 'package:wms_app/src/presentation/views/conteo/models/response_delete_product_model.dart';
import 'package:wms_app/src/presentation/views/conteo/models/response_send_product_model.dart';

class ConteoRepository {
//metodo para traer todos los conteos
  Future<ResultConteo> fetchAllConteos(
    bool isLoadinDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
      return ResultConteo(
        code: 0,
        msg: "No hay conexión a Internet",
        data: [],
      ); // Si no hay conexión, retornar un ResultConteo vacío
    }

    try {
      var response = await ApiRequestService().getValidation(
        endpoint: 'inventory/all_orders',
        isunecodePath: true,
        isLoadinDialog: isLoadinDialog,
      );

      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Accede a la clave "data" y luego a "result"

        // Asegúrate de que 'result' exista y sea una lista
        if (jsonResponse.containsKey('result')) {
          List<dynamic> response = jsonResponse['result']['data'];
          // Mapea los datos decodificados a una lista de BatchsModel

          return ResultConteo(
            code: jsonResponse['result']['code'],
            msg: jsonResponse['result']['msg'],
            updateVersion: jsonResponse['result']['update_version'],
            data: response.map((item) => DatumConteo.fromMap(item)).toList(),
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
            return ResultConteo(
              code: 0,
              msg: "Sesion expirada, por favor inicie sesión nuevamente",
              data: [],
              updateVersion: false,
            ); //
          }
        }
      } else {}
    } on SocketException catch (e) {
      print('Error de red: $e');
      return ResultConteo();
    } catch (e, s) {
      // Manejo de otros errores
      print('Error conteo fisico: $e, $s');
    }
    return ResultConteo();
  }

  //metodo para enviar los productos del conteo al wms
  Future<ResponseSendProductConteo> sendProductConteo(
      bool isLoadinDialog, ConteoItem product) async {
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
      return ResponseSendProductConteo(); // Si no hay conexión, retornar un ResultConteo vacío
    }

    try {
      var response = await ApiRequestService().postPicking(
          endpoint: 'inventory/send_inventory',
          isunecodePath: true,
          isLoadinDialog: isLoadinDialog,
          body: {
            "params": {
              "order_id": product.orderId ?? 0,
              "list_items": [
                {
                  "line_id": product.lineId.toString(),
                  "quantity_counted": product.quantityCounted,
                  "observation":
                      // product.observation == null || product.observation.isEmpty
                      //     ? "Sin novedad"
                      //     : product.observation
                      "",
                  "time_line": product.timeLine,
                  "fecha_transaccion": product.fechaTransaccion,
                  "id_operario": product.idOperario,
                  "product_id": product.productId,
                  "location_id":
                      product.locationId == 0 ? "" : product.locationId,
                  "lote_id": product.loteId ?? "",
                }
              ]
            }
          });

      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Accede a la clave "data" y luego a "result"

        // Asegúrate de que 'result' exista y sea una lista
        if (jsonResponse.containsKey('result')) {
          return ResponseSendProductConteo(
            jsonrpc: jsonResponse['jsonrpc'],
            id: jsonResponse['id'],
            result: ResponseSendProductResult.fromMap(jsonResponse['result']),
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
            return ResponseSendProductConteo(
              jsonrpc: jsonResponse['jsonrpc'],
              id: jsonResponse['id'],
              result: ResponseSendProductResult.fromMap(jsonResponse['result']),
            );
          } else {
            return ResponseSendProductConteo(
              jsonrpc: jsonResponse['jsonrpc'],
              id: jsonResponse['id'],
              result: ResponseSendProductResult(
                code: jsonResponse['error']['code'],
                msg: jsonResponse['error']['message'],
                result: [],
                data: null,
              ),
            );
          }
        }
      } else {}
    } on SocketException catch (e) {
      print('Error de red: $e');
      return ResponseSendProductConteo();
    } catch (e, s) {
      // Manejo de otros errores
      print('Error conteo fisico: $e, $s');
    }
    return ResponseSendProductConteo();
  }

  Future<ResponseDeleteProduct> deleteInfoProductConteo(
      bool isLoadinDialog, int idMove) async {
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
      return ResponseDeleteProduct(); // Si no hay conexión, retornar un ResultConteo vacío
    }

    try {
      var response = await ApiRequestService().postPicking(
          endpoint: 'inventory/delete_line',
          isunecodePath: true,
          isLoadinDialog: isLoadinDialog,
          body: {
            "params": {"line_id": idMove}
          });

      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Accede a la clave "data" y luego a "result"
        // Asegúrate de que 'result' exista y sea una lista
        if (jsonResponse.containsKey('result')) {
          return ResponseDeleteProduct(
            jsonrpc: jsonResponse['jsonrpc'],
            id: jsonResponse['id'],
            result: ResponseDeleteProductResult.fromMap(jsonResponse['result']),
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
            return ResponseDeleteProduct(
              jsonrpc: jsonResponse['jsonrpc'],
              id: jsonResponse['id'],
              result:
                  ResponseDeleteProductResult.fromMap(jsonResponse['result']),
            );
          }
        }
      } else {}
    } on SocketException catch (e) {
      print('Error de red: $e');
      return ResponseDeleteProduct();
    } catch (e, s) {
      // Manejo de otros errores
      print('Error conteo fisico: $e, $s');
    }
    return ResponseDeleteProduct();
  }

  Future<ResponseDeleteProduct> deleteProductConteo(
      bool isLoadinDialog, int idMove) async {
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
      return ResponseDeleteProduct(); // Si no hay conexión, retornar un ResultConteo vacío
    }

    try {
      var response = await ApiRequestService().postPicking(
          endpoint: 'inventory/remove_line',
          isunecodePath: true,
          isLoadinDialog: isLoadinDialog,
          body: {
            "params": {"line_id": idMove}
          });

      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Accede a la clave "data" y luego a "result"
        // Asegúrate de que 'result' exista y sea una lista
        if (jsonResponse.containsKey('result')) {
          return ResponseDeleteProduct(
            jsonrpc: jsonResponse['jsonrpc'],
            id: jsonResponse['id'],
            result: ResponseDeleteProductResult.fromMap(jsonResponse['result']),
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
            return ResponseDeleteProduct(
              jsonrpc: jsonResponse['jsonrpc'],
              id: jsonResponse['id'],
              result:
                  ResponseDeleteProductResult.fromMap(jsonResponse['result']),
            );
          }
        }
      } else {}
    } on SocketException catch (e) {
      print('Error de red: $e');
      return ResponseDeleteProduct();
    } catch (e, s) {
      // Manejo de otros errores
      print('Error conteo fisico: $e, $s');
    }
    return ResponseDeleteProduct();
  }
}
