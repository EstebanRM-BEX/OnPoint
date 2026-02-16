// ignore_for_file: unrelated_type_equality_checks

import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_app/src/api/api_request_service.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/src/presentation/views/devoluciones/models/request_send_devolucion_model.dart';
import 'package:wms_app/src/presentation/views/devoluciones/models/response_devolucion_model.dart';
import 'package:wms_app/src/presentation/views/devoluciones/models/response_terceros_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_lotes_product_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_new_lote_model.dart';

class DevolucionesRepository {
  Future<List<Terceros>> fetAllTerceros(
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
        endpoint: 'terceros',
        isunecodePath: true,
        isLoadinDialog: isLoadinDialog,
      );
      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Accede a la clave "data" y luego a "result"
        // Asegúrate de que 'result' exista y sea una lista
        if (jsonResponse.containsKey('result')) {
          List<dynamic> products = jsonResponse['result']['result'];
          // Mapea los datos decodificados a una lista de BatchsModel
          List<Terceros> productsResponse =
              products.map((data) => Terceros.fromMap(data)).toList();
          return productsResponse;
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
      print('Error fetAllTerceros: $e, $s');
    }
    return [];
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
              "nombre_lote": nameLote ?? "",
              "fecha_vencimiento": dateLote ?? "",
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
          }else{
            return ResponseNewLote(
              jsonrpc: jsonResponse['jsonrpc'],
              id: jsonResponse['id'],
              result: ResponseNewLoteResult(
                code: jsonResponse['result']['code'] ?? 500,
                msg: jsonResponse['result']['msg'] ?? 'Error desconocido',
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

  Future<ResponseDevolucion> sendDevolucion(
    RequestSendDevolucionModel request,
    bool isLoadingDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("Error: No hay conexión a Internet.");
      return ResponseDevolucion(); // Si no hay conexión, terminamos la ejecución
    }

    print("request ${request.toJson()}");

    //obtenemos la mac o el device id del dispositivo
    final mac = await PrefUtils.getMacPDA();
    final imei = await PrefUtils.getImeiPDA();
    try {
      var response = await ApiRequestService().postPacking(
        endpoint:
            'crear_devs', // Cambiado para que sea el endpoint correspondiente
        body: {
          "params": {
            "device_id": mac == "02:00:00:00:00:00" ? imei : mac,
            "id_almacen": request.idAlmacen,
            "id_proveedor": request.idProveedor,
            "id_ubicacion_destino": request.idUbicacionDestino,
            "id_responsable": request.idResponsable,
            "fecha_inicio": request.fechaInicio,
            "fecha_fin": request.fechaFin,
            "list_items":
                request.listItems.map((item) => item.toJson()).toList(),
          },
        },
        isLoadinDialog: true,
      );
      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Verifica si la respuesta contiene la clave 'result' y convierte la lista correctamente
        var resultData = jsonResponse['result'];

        return ResponseDevolucion(
          jsonrpc: jsonResponse['jsonrpc'],
          id: jsonResponse['id'],
          result: resultData != null
              ? ResultDevolucion.fromMap(
                  resultData) // Usa el fromMap del resultado
              : null, // Si 'result' no existe, asigna null a 'result'
        );
      } else {
        // Manejo de error si la respuesta no es exitosa
        print("Error en la respuesta: ${response.statusCode}");
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Verifica si la respuesta contiene la clave 'result' y convierte la lista correctamente
        var resultData = jsonResponse['result'];

        return ResponseDevolucion(
            jsonrpc: jsonResponse['jsonrpc'],
            id: jsonResponse['id'],
            result: ResultDevolucion(
              code: jsonResponse['code'] ?? 500,
              msg: jsonResponse['msg'] ?? 'Error desconocido',
            ));
      }
    } on SocketException catch (e) {
      print('Error de red: $e');
      return ResponseDevolucion(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      print('Error en sendDevolucion: $e, $s');
      return ResponseDevolucion(); // Retornamos un objeto vacío en caso de error de red
    }
  }
}
