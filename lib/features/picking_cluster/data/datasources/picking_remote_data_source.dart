import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../src/api/api_request_service.dart';
import '../models/picking_cluster_model.dart';
import '../models/lote_producto_model.dart';

abstract class PickingClusterRemoteDataSource {
  Future<List<ResultElementModel>> getPickingBatches();

  /// POST api/cluster/picking_batchs: asigna al usuario las zonas del batch y
  /// devuelve ese batch (mismo formato del GET, pero un solo elemento).
  Future<ResultElementModel> assignZonasBatch(int batchId);

  /// POST api/cluster/release_zone: libera las zonas del usuario en el batch.
  /// Devuelve el `msg` del servidor.
  Future<String> releaseZonasBatch(int batchId, List<int> zoneIds);

  Future<List<LotesProduct>> getLotesProducto(int productId);

  Future<LotesProduct> crearLoteProducto(
      int productId, String name, String? expirationDate);
  Future<String> sendPickingProduct({
    required int idBatch,
    required double timeTotal,
    required List<Map<String, dynamic>> listItem,
    required String tipoPicking,
  });
  Future<String> viewProductImage(int idProduct, bool isLoadinDialog);
  Future<bool> timePickingUser(
      int batchId, String time, String endpoint, String field, int userid);
  Future<bool> timePickingBatch(
      int batchId, String time, String endpoint, String field, String field2);
  Future<bool> validatePedido(int idPedido, int idLocation, List<int> listItems);
}

@LazySingleton(as: PickingClusterRemoteDataSource)
class PickingClusterRemoteDataSourceImpl
    implements PickingClusterRemoteDataSource {
  final ApiRequestService apiRequestService;

  PickingClusterRemoteDataSourceImpl(this.apiRequestService);

  @override
  Future<List<ResultElementModel>> getPickingBatches() async {
    final response = await apiRequestService.get(
      endpoint: 'api/cluster/picking_batchs',
      isLoadinDialog: false,
      isunecodePath: false,
    );

    if (response.statusCode == 200) {
      final model = PickingClusterModel.fromJson(json.decode(response.body));
      return model.result?.result ?? [];
    } else {
      throw Exception('Failed to load picking batches: ${response.statusCode}');
    }
  }

  @override
  Future<ResultElementModel> assignZonasBatch(int batchId) async {
    final packageInfo = await PackageInfo.fromPlatform();
    // postPicking envía la cookie de sesión; `post` no la manda y el servidor
    // responde 404 a las rutas que requieren usuario.
    final response = await apiRequestService.postPicking(
      endpoint: 'api/cluster/picking_batchs',
      body: {
        "params": {
          "version_app": packageInfo.version,
          "id_batch": batchId,
        },
      },
      isLoadinDialog: false,
      isunecodePath: false,
    );

    // Odoo responde los rechazos (p. ej. 409 "batch ya asignado") con un JSON
    // que trae `result.msg`: se intenta leer aunque el HTTP no sea 200 para
    // mostrar ese mensaje y no solo el código.
    dynamic decoded;
    try {
      decoded = json.decode(response.body);
    } catch (_) {
      decoded = null;
    }
    if (response.statusCode != 200 && decoded is! Map) {
      throw Exception('Error al asignar zonas: ${response.statusCode}');
    }

    final error = decoded is Map ? decoded['error'] : null;
    if (error != null) {
      throw Exception(error is Map
          ? (error['data']?['message'] ?? error['message'] ?? 'Error del servidor')
          : 'Error del servidor');
    }

    final result = decoded is Map ? decoded['result'] : null;
    if (result is! Map) {
      throw Exception('Respuesta inválida al asignar zonas');
    }
    if (result['code'] != 200) {
      throw Exception(result['msg']?.toString() ?? 'No se pudieron asignar las zonas');
    }

    // El servidor devuelve un solo batch (objeto); por si viniera como lista.
    final data = result['result'];
    final batchJson = data is List ? (data.isEmpty ? null : data.first) : data;
    if (batchJson is! Map<String, dynamic>) {
      throw Exception('El servidor no devolvió el batch');
    }
    return ResultElementModel.fromJson(batchJson);
  }

  @override
  Future<String> releaseZonasBatch(int batchId, List<int> zoneIds) async {
    final response = await apiRequestService.postPicking(
      endpoint: 'api/cluster/release_zone',
      body: {
        "params": {
          "id_batch": batchId,
          "zone_ids": zoneIds,
        },
      },
      isLoadinDialog: false,
      isunecodePath: false,
    );

    dynamic decoded;
    try {
      decoded = json.decode(response.body);
    } catch (_) {
      decoded = null;
    }
    if (response.statusCode != 200 && decoded is! Map) {
      throw Exception('Error al liberar zonas: ${response.statusCode}');
    }

    final error = decoded is Map ? decoded['error'] : null;
    if (error != null) {
      throw Exception(error is Map
          ? (error['data']?['message'] ?? error['message'] ?? 'Error del servidor')
          : 'Error del servidor');
    }

    final result = decoded is Map ? decoded['result'] : null;
    if (result is! Map) {
      throw Exception('Respuesta inválida al liberar zonas');
    }
    if (result['code'] != 200) {
      throw Exception(result['msg']?.toString() ?? 'No se pudieron liberar las zonas');
    }
    return result['msg']?.toString() ?? 'Zonas liberadas';
  }

  @override
  Future<List<LotesProduct>> getLotesProducto(int productId) async {
    final response = await apiRequestService.get(
      endpoint: 'api/lotes/$productId',
      isLoadinDialog: false,
      isunecodePath: false,
    );

    if (response.statusCode == 200) {
      final model = LoteProductoResponse.fromJson(json.decode(response.body));
      return model.result?.result ?? [];
    } else {
      throw Exception(
          'Failed to load lotes de un producto: ${response.statusCode}');
    }
  }

  @override
  Future<LotesProduct> crearLoteProducto(
      int productId, String name, String? expirationDate) async {
    final Map<String, dynamic> params = {
      "id_producto": productId,
      "nombre_lote": name,
    };

    if (expirationDate != null) {
      params["fecha_vencimiento"] = expirationDate;
    }

    final requestBody = {
      "params": params,
    };

    final response = await apiRequestService.post(
      endpoint: 'api/create_lote',
      body: requestBody,
      isLoadinDialog: true,
      isunecodePath: false,
    );

    if (response.statusCode == 200) {
      final model = LoteProductoResponse.fromJson(json.decode(response.body));

      if (model.result?.result != null && model.result!.result!.isNotEmpty) {
        return model.result!.result!.first;
      }

      return LotesProduct(
        productId: productId,
        name: name,
        expirationDate:
            expirationDate != null ? DateTime.tryParse(expirationDate) : null,
      );
    } else {
      throw Exception(
          'Failed to create lote de producto: ${response.statusCode}');
    }
  }

  @override
  Future<String> sendPickingProduct({
    required int idBatch,
    required double timeTotal,
    required List<Map<String, dynamic>> listItem,
    required String tipoPicking,
  }) async {
    String endpoint;
    Map<String, dynamic> params;
    endpoint = 'cluster/send_picking';
    params = {
      "id_batch": idBatch,
      "list_item": listItem,
    };
    final response = await apiRequestService.postPicking(
      endpoint: endpoint,
      isunecodePath: true,
      body: {"params": params},
      isLoadinDialog: false,
    );
    // We expect the result directly since ApiRequestService returns the HTTP response.
    return response.body;
  }

  @override
  Future<String> viewProductImage(int idProduct, bool isLoadinDialog) async {
    final response = await apiRequestService.get(
      endpoint: 'get_imagen_product/$idProduct',
      isunecodePath: true,
      isLoadinDialog: isLoadinDialog,
    );

    if (response.statusCode < 400) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['result']?['code'] == 200) {
        final url = jsonResponse['result']?['result']?['url'];
        if (url != null && url.toString().isNotEmpty) {
          return url.toString();
        } else {
          throw Exception('Imagen no disponible');
        }
      } else {
        throw Exception(
            jsonResponse['result']?['msg'] ?? 'Imagen no disponible');
      }
    } else {
      throw Exception('Failed to load product image: ${response.statusCode}');
    }
  }

  @override
  Future<bool> timePickingUser(int batchId, String time, String endpoint,
      String field, int userid) async {
    final response = await apiRequestService.postPicking(
        endpoint: endpoint,
        isunecodePath: true,
        isLoadinDialog: false,
        body: {
          "params": {
            "id_batch": "$batchId",
            "user_id": "$userid",
            field: time,
            "operation_type": "picking"
          }
        });
    if (response.statusCode < 400) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      if (jsonResponse.containsKey('result')) {
        if (jsonResponse['result']['code'] == 200) return true;
        return false;
      }
    }
    throw Exception('Failed timePickingUser');
  }

  @override
  Future<bool> timePickingBatch(int batchId, String time, String endpoint,
      String field, String field2) async {
    final response = await apiRequestService.postPicking(
        endpoint: endpoint,
        isunecodePath: true,
        isLoadinDialog: false,
        body: {
          "params": {
            "picking_id": "$batchId",
            field2: time,
            "field_name": field,
          }
        });
    if (response.statusCode < 400) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      if (jsonResponse.containsKey('result')) {
        if (jsonResponse['result']['code'] == 200) return true;
        return false;
      }
    }
    throw Exception('Failed timePickingBatch');
  }

  @override
  Future<bool> validatePedido(
      int idPedido, int idLocation, List<int> listItems) async {
    final Map<String, dynamic> params = {
      "id_pedido": idPedido,
      "id_location": idLocation,
      "list_items": listItems.map((id) => {"id": id}).toList(),
    };

    final requestBody = {
      "params": params,
    };

    debugPrint('requestBody: $requestBody');

    final response = await apiRequestService.postPicking(
      endpoint: 'cluster/validate_pedido/id',
      body: requestBody,
      isLoadinDialog: true,
      isunecodePath: true,
    );

    try {
      final jsonResponse = jsonDecode(response.body);

      // JSON-RPC returns a 'result' object for success
      if (jsonResponse.containsKey('result')) {
        final resultData = jsonResponse['result'];
        if (resultData['code'] == 200) {
          return true;
        } else {
          throw Exception(resultData['msg'] ?? 'Error validando pedido');
        }
      }

      // JSON-RPC returns an 'error' object when it fails
      if (jsonResponse.containsKey('error')) {
        throw Exception(jsonResponse['error']['message'] ??
            'Error desconocido del servidor');
      }

      return false;
    } catch (e) {
      if (response.body.contains('404')) {
        throw Exception(
            'Error 404: La ruta /api/cluster/validate_pedido/id no se encontró en Odoo. (Comprueba el backend).');
      }
      throw Exception(
          'Error en respuesta: ${response.statusCode} - ${response.body}');
    }
  }
}
