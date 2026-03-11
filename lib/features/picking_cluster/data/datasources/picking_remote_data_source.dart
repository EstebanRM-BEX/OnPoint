import 'dart:convert';
import 'package:injectable/injectable.dart';
import '../../../../src/api/api_request_service.dart';
import '../models/picking_cluster_model.dart';
import '../models/lote_producto_model.dart';

abstract class PickingClusterRemoteDataSource {
  Future<List<ResultElementModel>> getPickingBatches();

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
  Future<List<LotesProduct>> getLotesProducto(int productId) async {
    final response = await apiRequestService.get(
      endpoint: 'api/lotes/$productId',
      isLoadinDialog: true,
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
}
