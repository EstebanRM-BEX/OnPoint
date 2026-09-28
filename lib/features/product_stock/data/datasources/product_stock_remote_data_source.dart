import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/src/api/api_request_service.dart';

import '../models/product_stock_info_model.dart';

abstract class ProductStockRemoteDataSource {
  Future<ProductStockInfoModel> getProductStockInfo(int productId);
}

@LazySingleton(as: ProductStockRemoteDataSource)
class ProductStockRemoteDataSourceImpl implements ProductStockRemoteDataSource {
  final ApiRequestService apiRequestService;

  ProductStockRemoteDataSourceImpl(this.apiRequestService);

  static const _tag = '[product/stock_info]';

  @override
  Future<ProductStockInfoModel> getProductStockInfo(int productId) async {
    final response = await apiRequestService.postPicking(
      endpoint: 'product/stock_info',
      body: {
        "params": {"product_id": productId},
      },
      isunecodePath: true,
      isLoadinDialog: false,
    );

    final body = response.body;
    debugPrint("📦 $_tag HTTP ${response.statusCode}: "
        "${body.length > 1500 ? '${body.substring(0, 1500)}…' : body}");

    if (response.statusCode >= 400) {
      throw ServerException(
          "Error HTTP ${response.statusCode} al consultar el stock");
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const ServerException("Respuesta inesperada del servidor");
    }

    if (decoded['error'] is Map) {
      final error = decoded['error'] as Map;
      if (error['code'] == 100) {
        throw const SessionExpiredException(
            'Sesión expirada, por favor inicie sesión nuevamente');
      }
      final data = error['data'];
      final detail = data is Map ? data['message'] : null;
      throw ServerException(
        "${error['message'] ?? 'Error del servidor'}${detail != null ? ': $detail' : ''}",
      );
    }

    // Con o sin wrapper JSON-RPC.
    final result = Map<String, dynamic>.from(
      decoded['result'] is Map ? decoded['result'] as Map : decoded,
    );
    final code = int.tryParse('${result['code']}');
    if (code != 200) {
      final msg = result['msg'];
      throw ServerException(
        (msg is String && msg.isNotEmpty)
            ? msg
            : "No se pudo consultar el stock (code=${result['code']})",
      );
    }

    return ProductStockInfoModel.fromJson(result);
  }
}
