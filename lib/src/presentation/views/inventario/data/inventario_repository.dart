// ignore_for_file: unrelated_type_equality_checks

import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:wms_app/src/api/api_request_service.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/inventario/models/request_sendProducr_model.dart';
import 'package:wms_app/src/presentation/views/inventario/models/response_products_model.dart';
import 'package:wms_app/src/presentation/views/inventario/models/response_senProduct_mode.dart';
import 'package:wms_app/src/presentation/views/inventario/models/send_img_product_model.dart';
import 'package:wms_app/src/presentation/views/inventario/models/view_url_product_mode.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_lotes_product_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_new_lote_model.dart';

class InventarioRepository {
  Future<SendImgProduct> sendImageProduct(
    int idProduct,
    File imageFile,
    bool isLoadingDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return SendImgProduct(); // Si no hay conexión, terminamos la ejecución
    }

    try {
      final response = await ApiRequestService().postMultipartDynamic(
        endpoint: 'send_image_product',
        imageFile: imageFile,
        fields: {
          'product_id': idProduct,
        },
      );

      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa

        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Verifica si la respuesta contiene la clave 'result' y convierte la lista correctamente

        if (jsonResponse['code'] == 400) {
          return SendImgProduct(
            msg: jsonResponse['msg'],
            code: jsonResponse['code'],
          );
        } else if (jsonResponse['code'] == 200) {
          return SendImgProduct(
            code: jsonResponse['code'],
            result: jsonResponse['result'],
            imageUrl: jsonResponse['image_url'],
            filename: jsonResponse['filename'],
            productName: jsonResponse['product_name'],
            productCode: jsonResponse['product_code'],
            imageSize: jsonResponse['image_size'],
          );
        } else {
          return SendImgProduct(); // Retornamos un objeto vacío en caso de error
        }
      } else {
        // Manejo de error si la respuesta no es exitosa
        debugPrint(
            'Error al enviar la imagen del producto: ${response.statusCode}');
        return SendImgProduct(); // Retornamos un objeto vacío en caso de error
      }
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
      return SendImgProduct(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error en sendImageProduct: $e, $s');
      return SendImgProduct(); // Retornamos un objeto vacío en caso de error de red
    }
  }

  Future<ViewUrlImgProduct> viewUrlImageProduct(
    int idProduct,
    bool isLoadingDialog,
  ) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return ViewUrlImgProduct(); // Si no hay conexión, terminamos la ejecución
    }

    try {
      final response = await ApiRequestService().get(
        endpoint: 'get_imagen_product/$idProduct',
        isunecodePath: true,
        isLoadinDialog: isLoadingDialog,
      );

      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa

        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Verifica si la respuesta contiene la clave 'result' y convierte la lista correctamente

        if (jsonResponse['result']['code'] == 200) {
          return ViewUrlImgProduct(
              jsonrpc: jsonResponse['jsonrpc'],
              id: jsonResponse['id'],
              result: ViewUrlImgProductResult(
                code: jsonResponse['result']['code'],
                msg: jsonResponse['result']['msg'],
                result: ResultResult(
                  url: jsonResponse['result']['result']['url'],
                ),
              ));
        } else {
          return ViewUrlImgProduct(
              jsonrpc: jsonResponse['jsonrpc'],
              id: jsonResponse['id'],
              result: ViewUrlImgProductResult(
                code: jsonResponse['result']['code'],
                msg: jsonResponse['result']['msg'],
              ));
        }
      } else {
        // Manejo de error si la respuesta no es exitosa
        debugPrint(
            'Error al enviar la imagen del producto: ${response.statusCode}');
        return ViewUrlImgProduct(); // Retornamos un objeto vacío en caso de error
      }
    } on SocketException catch (e) {
      debugPrint('Error de red: $e');
      return ViewUrlImgProduct(); // Retornamos un objeto vacío en caso de error de red
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error en sendImageProduct: $e, $s');
      return ViewUrlImgProduct(); // Retornamos un objeto vacío en caso de error de red
    }
  }

  // ✅ Función para procesar y aislar el json gigantesco y extraer barcodes en un SOLO paso.
  // Al hacer todo en un solo Isolate, evitamos copiar 60,000 objetos de memoria dos veces por el canal de Flutter.
  static Map<String, dynamic> _parseProductsAndBarcodesIsolate(
      String responseBody) {
    Map<String, dynamic> jsonResponse = jsonDecode(responseBody);

    if (jsonResponse.containsKey('result')) {
      final List<dynamic> data = jsonResponse['result']['data'];
      final List<Product> products = [];
      final List<BarcodeInventario> barcodes = [];

      for (final item in data) {
        final product = Product.fromMap(item);
        products.add(product);

        // Extracción inmediata de barcodes para ahorrar un loop extra en el futuro
        if (product.otherBarcodes != null) {
          barcodes.addAll(product.otherBarcodes!);
        }
        if (product.productPacking != null) {
          barcodes.addAll(product.productPacking!);
        }
      }

      return {
        'products': products,
        'barcodes': barcodes,
      };
    }
    return {
      'error': jsonResponse['error'] ?? 'Unknown error',
      'products': <Product>[],
      'barcodes': <BarcodeInventario>[]
    };
  }

  Future<Map<String, dynamic>> fetAllProductsCombined(
    bool isLoadinDialog,
  ) async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return {'products': <Product>[], 'barcodes': <BarcodeInventario>[]};
    }

    try {
      var response = await ApiRequestService().getInventario(
        endpoint: 'product_quants',
        isunecodePath: true,
        isLoadinDialog: isLoadinDialog,
      );

      if (response.statusCode < 400) {
        // Un solo compute para TODO el procesamiento pesado
        return await compute(_parseProductsAndBarcodesIsolate, response.body);
      }
    } catch (e, s) {
      debugPrint('Error fetAllProductsCombined: $e, $s');
    }
    return {'products': <Product>[], 'barcodes': <BarcodeInventario>[]};
  }

  // Mantenemos la firma original por compatibilidad si otros blocs la usan,
  // pero internamente llamamos a la optimizada.
  Future<List<Product>> fetAllProducts(bool isLoadinDialog) async {
    final res = await fetAllProductsCombined(isLoadinDialog);
    return res['products'] as List<Product>;
  }

  Future<List<LotesProduct>> fetchAllLotesProduct(
      bool isLoadinDialog, int productId) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
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
      debugPrint('Error de red: $e');
      return [];
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error lotes de un producto: $e, $s');
    }
    return [];
  }

  Future<ResponseSendProduct> sendProduct(
      SendProductInventario request, bool isLoadinDialog) async {
    // Verificar si el dispositivo tiene acceso a Internet
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("Error: No hay conexión a Internet.");
      return ResponseSendProduct();
    }

    try {
      debugPrint(request.toMap().toString());

      var response = await ApiRequestService().postInventario(
          endpoint: 'quant_post',
          isunecodePath: true,
          isLoadinDialog: isLoadinDialog,
          body: {
            "params": {
              "location_id": request.locationId,
              "product_id": request.productId,
              "lot_id": request.lotId,
              "quantity": request.quantity,
              'user_id': request.userId,
            }
          });
      if (response.statusCode < 400) {
        // Decodifica la respuesta JSON a un mapa
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Accede a la clave "data" y luego a "result"
        // Asegúrate de que 'result' exista y sea una lista
        if (jsonResponse.containsKey('result')) {
          return ResponseSendProduct.fromMap(jsonResponse);
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
            return ResponseSendProduct();
          }
        }
      }
      return ResponseSendProduct();
    } catch (e, s) {
      debugPrint("Error en el senProduct inventario : $e =>$s");
      return ResponseSendProduct();
    }
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
      debugPrint("Error: No hay conexión a Internet.");
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
      debugPrint('Error de red: $e');
      return ResponseNewLote();
    } catch (e, s) {
      // Manejo de otros errores
      debugPrint('Error resBatchsPacking: $e, $s');
    }
    return ResponseNewLote();
  }
}
