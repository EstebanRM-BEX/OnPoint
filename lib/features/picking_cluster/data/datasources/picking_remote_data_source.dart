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
    required int cantItemsSeparados,
    required List<Map<String, dynamic>> listItem,
    required String tipoPicking,
  });
  Future<String> viewProductImage(int idProduct, bool isLoadinDialog);
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
    required int cantItemsSeparados,
    required List<Map<String, dynamic>> listItem,
    required String tipoPicking,
  }) async {
    final response = await apiRequestService.postPicking(
      endpoint:
          tipoPicking == 'batch' ? 'send_batch' : 'send_batch/componentes',
      isunecodePath: true,
      body: {
        "params": {
          "id_batch": idBatch,
          "time_total": timeTotal,
          "cant_items_separados": cantItemsSeparados,
          "list_item": listItem,
        }
      },
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
}
