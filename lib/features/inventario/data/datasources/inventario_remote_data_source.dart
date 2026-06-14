// lib/features/inventario/data/datasources/inventario_remote_data_source.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/features/inventario/data/models/barcode_producto_model.dart';
import 'package:wms_app/features/inventario/data/models/lote_producto_inventario_model.dart';
import 'package:wms_app/features/inventario/data/models/producto_inventario_model.dart';
import 'package:wms_app/features/inventario/data/models/resultado_crear_lote_model.dart';
import 'package:wms_app/features/inventario/data/models/resultado_envio_inventario_model.dart';
import 'package:wms_app/src/api/api_request_service.dart';

// ─── Clases de resultado ────────────────────────────────────────────────────

/// Agrupa los resultados del parse en el isolate (productos + barcodes).
class ProductosSyncResult {
  final List<ProductoInventarioModel> productos;
  final List<BarcodeProductoModel> barcodes;

  const ProductosSyncResult({
    required this.productos,
    required this.barcodes,
  });
}

// ─── Función top-level para compute() ───────────────────────────────────────
// Debe ser top-level (no método de clase) para poder pasarse a compute().
// Las excepciones NO cruzan isolates: si error.code == 100, se retorna
// 'sessionExpired: true' como marcador; el datasource lo detecta y lanza
// SessionExpiredException fuera del isolate.

Map<String, dynamic> _parseProductosIsolate(String responseBody) {
  final json = jsonDecode(responseBody) as Map<String, dynamic>;

  if (json.containsKey('error')) {
    final errorCode =
        (json['error'] as Map<String, dynamic>?)?['code'];
    return {
      'sessionExpired': errorCode == 100,
      'productos': <ProductoInventarioModel>[],
      'barcodes': <BarcodeProductoModel>[],
    };
  }

  if (json.containsKey('result')) {
    final resultMap = json['result'] as Map<String, dynamic>?;
    final data = (resultMap?['data'] as List<dynamic>?) ?? [];
    final productos = <ProductoInventarioModel>[];
    final barcodes = <BarcodeProductoModel>[];

    for (final item in data) {
      final producto =
          ProductoInventarioModel.fromMap(item as Map<String, dynamic>);
      productos.add(producto);

      // Extracción inmediata de barcodes — mismo pase, sin loop extra
      if (producto.otherBarcodes != null) {
        for (final b in producto.otherBarcodes!) {
          if (b is BarcodeProductoModel) barcodes.add(b);
        }
      }
      if (producto.productPacking != null) {
        for (final b in producto.productPacking!) {
          if (b is BarcodeProductoModel) barcodes.add(b);
        }
      }
    }

    return {
      'sessionExpired': false,
      'productos': productos,
      'barcodes': barcodes,
    };
  }

  return {
    'sessionExpired': false,
    'productos': <ProductoInventarioModel>[],
    'barcodes': <BarcodeProductoModel>[],
  };
}

// ─── Interfaz ────────────────────────────────────────────────────────────────

abstract class InventarioRemoteDataSource {
  /// GET product_quants — parsea productos y barcodes en un solo isolate.
  Future<ProductosSyncResult> syncProductos();

  /// GET lotes/$productId
  Future<List<LoteProductoInventarioModel>> getLotes(int productId);

  /// POST quant_post
  Future<ResultadoEnvioInventarioModel> enviarProducto({
    required dynamic locationId,
    required dynamic productId,
    required dynamic lotId,
    required dynamic quantity,
  });

  /// POST create_lote (vía postPacking)
  Future<ResultadoCrearLoteModel> crearLote({
    required int productId,
    required String nameLote,
    required String fechaCaducidad,
    required bool priorityExpiration,
  });

  /// GET get_imagen_product/$productId — URL de la imagen del producto.
  Future<String> getUrlImagenProducto(int productId);
}

// ─── Implementación ──────────────────────────────────────────────────────────

@LazySingleton(as: InventarioRemoteDataSource)
class InventarioRemoteDataSourceImpl implements InventarioRemoteDataSource {
  final ApiRequestService apiService;

  InventarioRemoteDataSourceImpl(this.apiService);

  @override
  Future<ProductosSyncResult> syncProductos() async {
    try {
      final response = await apiService.getInventario(
        endpoint: 'product_quants',
        isunecodePath: true,
        isLoadinDialog: false,
      );

      if (response.statusCode >= 400) {
        throw ServerException(
            'Error del servidor: ${response.statusCode}');
      }

      final result = await compute(_parseProductosIsolate, response.body);

      if (result['sessionExpired'] == true) {
        throw const SessionExpiredException('Sesión expirada');
      }

      return ProductosSyncResult(
        productos: (result['productos'] as List).cast<ProductoInventarioModel>(),
        barcodes: (result['barcodes'] as List).cast<BarcodeProductoModel>(),
      );
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      throw ServerException('Error al sincronizar productos: $e');
    }
  }

  @override
  Future<List<LoteProductoInventarioModel>> getLotes(int productId) async {
    try {
      final response = await apiService.get(
        endpoint: 'lotes/$productId',
        isunecodePath: true,
        isLoadinDialog: false,
      );

      if (response.statusCode >= 400) {
        throw ServerException(
            'Error del servidor: ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json.containsKey('error')) {
        if ((json['error'] as Map<String, dynamic>?)?['code'] == 100) {
          throw const SessionExpiredException('Sesión expirada');
        }
        throw ServerException('Error en respuesta: ${json['error']}');
      }

      if (json.containsKey('result')) {
        final data = json['result']['result'] as List<dynamic>;
        return data
            .map((e) => LoteProductoInventarioModel.fromMap(
                e as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      throw ServerException('Error al obtener lotes: $e');
    }
  }

  @override
  Future<ResultadoEnvioInventarioModel> enviarProducto({
    required dynamic locationId,
    required dynamic productId,
    required dynamic lotId,
    required dynamic quantity,
  }) async {
    final userId = await PrefUtils.getUserId();

    final requestBody = {
      'params': {
        'location_id': locationId,
        'product_id': productId,
        'lot_id': lotId,
        'quantity': quantity,
        'user_id': userId,
      }
    };
    debugPrint('📤 [enviarProducto] REQUEST: $requestBody');

    try {
      final response = await apiService.postInventario(
        endpoint: 'quant_post',
        isunecodePath: true,
        isLoadinDialog: false,
        body: requestBody,
      );

      debugPrint('📥 [enviarProducto] STATUS: ${response.statusCode}');
      debugPrint('📥 [enviarProducto] RESPONSE: ${response.body}');

      if (response.statusCode >= 400) {
        throw ServerException(
            'Error del servidor: ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json.containsKey('error')) {
        if ((json['error'] as Map<String, dynamic>?)?['code'] == 100) {
          throw const SessionExpiredException('Sesión expirada');
        }
        throw ServerException('Error en respuesta: ${json['error']}');
      }

      if (json.containsKey('result')) {
        return ResultadoEnvioInventarioModel.fromMap(json);
      }

      return const ResultadoEnvioInventarioModel();
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      throw ServerException('Error al enviar producto: $e');
    }
  }

  @override
  Future<ResultadoCrearLoteModel> crearLote({
    required int productId,
    required String nameLote,
    required String fechaCaducidad,
    required bool priorityExpiration,
  }) async {
    try {
      final response = await apiService.postPacking(
        endpoint: 'create_lote',
        isLoadinDialog: false,
        body: {
          'params': {
            'id_producto': productId,
            'nombre_lote': nameLote,
            'fecha_vencimiento': fechaCaducidad,
            'priority_expiration': priorityExpiration,
          }
        },
      );

      if (response.statusCode >= 400) {
        throw ServerException(
            'Error del servidor: ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json.containsKey('error')) {
        if ((json['error'] as Map<String, dynamic>?)?['code'] == 100) {
          throw const SessionExpiredException('Sesión expirada');
        }
        throw ServerException('Error en respuesta: ${json['error']}');
      }

      if (json.containsKey('result')) {
        return ResultadoCrearLoteModel.fromMap(json);
      }

      return const ResultadoCrearLoteModel();
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      throw ServerException('Error al crear lote: $e');
    }
  }

  @override
  Future<String> getUrlImagenProducto(int productId) async {
    try {
      // isLoadinDialog: true preserva la UX legacy: el servicio muestra el
      // diálogo de carga mientras se consulta la imagen (los 12 módulos
      // consumidores dependen de ese comportamiento).
      final response = await apiService.get(
        endpoint: 'get_imagen_product/$productId',
        isunecodePath: true,
        isLoadinDialog: true,
      );

      if (response.statusCode >= 400) {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final result = json['result'] as Map<String, dynamic>?;

      if (result?['code'] == 200) {
        final url = (result?['result'] as Map<String, dynamic>?)?['url'];
        if (url is String && url.isNotEmpty) {
          return url;
        }
      }

      throw const ServerException('Imagen no disponible');
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Error al obtener imagen del producto: $e');
    }
  }
}
