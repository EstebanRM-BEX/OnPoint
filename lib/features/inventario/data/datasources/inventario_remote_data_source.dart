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

/// Respuesta de `product_quants` ya parseada.
///
/// [full] = `data` es el catálogo completo (reemplazar todo). Con `false`,
/// `data` trae solo los productos cambiados, cada uno con TODAS sus filas.
/// Backend sin sincronización incremental: no manda `server_time`, se trata
/// como completa y [serverTime]/[scope] quedan en null.
class ProductosSyncResult {
  final List<ProductoInventarioModel> productos;
  final List<BarcodeProductoModel> barcodes;
  final bool full;
  final String? serverTime;
  final String? scope;
  final List<int> deletedProductIds;

  /// Todos los productos activos (solo en incremental): los locales que no
  /// estén acá se borran. null = no vino, no se depura.
  final List<int>? activeProductIds;

  const ProductosSyncResult({
    required this.productos,
    required this.barcodes,
    this.full = true,
    this.serverTime,
    this.scope,
    this.deletedProductIds = const [],
    this.activeProductIds,
  });
}

// ─── Función top-level para compute() ───────────────────────────────────────
// Debe ser top-level (no método de clase) para poder pasarse a compute().
// Las excepciones NO cruzan isolates: los errores vuelven como marcadores
// ('sessionExpired' / 'error') y el datasource lanza la excepción afuera.

List<int> _ids(dynamic v) => v is List
    ? [for (final e in v) if (e is num) e.toInt()]
    : const <int>[];

String? _texto(dynamic v) => v is String && v.isNotEmpty ? v : null;

Map<String, dynamic> _parseProductosIsolate(String responseBody) {
  final json = jsonDecode(responseBody) as Map<String, dynamic>;

  if (json.containsKey('error')) {
    final error = json['error'] as Map<String, dynamic>?;
    return {
      'sessionExpired': error?['code'] == 100,
      'error': '${error?['message'] ?? 'Error en la respuesta del servidor'}',
    };
  }

  final resultMap = json['result'];
  if (resultMap is! Map<String, dynamic>) {
    return {'error': 'Respuesta sin resultado'};
  }

  // Error de negocio: no se toca el catálogo local.
  final code = resultMap['code'];
  if (resultMap['status'] == 'error' ||
      (code != null && code != 200 && code != '200' && code != 'success')) {
    return {
      'error': '${resultMap['msg'] ?? resultMap['message'] ?? 'Error del servidor ($code)'}',
    };
  }

  final data = (resultMap['data'] as List<dynamic>?) ?? [];
  final productos = <ProductoInventarioModel>[];
  final barcodes = <BarcodeProductoModel>[];
  // Cada fila (ubicación/lote) repite los barcodes de su producto.
  final vistos = <String>{};

  void agregar(dynamic b) {
    if (b is! BarcodeProductoModel) return;
    if (vistos.add('${b.idProduct}|${b.barcode}')) barcodes.add(b);
  }

  for (final item in data) {
    final producto =
        ProductoInventarioModel.fromMap(item as Map<String, dynamic>);
    productos.add(producto);
    producto.otherBarcodes?.forEach(agregar);
    producto.productPacking?.forEach(agregar);
  }

  final serverTime = _texto(resultMap['server_time']);
  return {
    'productos': productos,
    'barcodes': barcodes,
    'serverTime': serverTime,
    'scope': _texto(resultMap['scope']),
    // Sin server_time es el backend anterior: siempre completo.
    'full': serverTime == null || resultMap['full'] != false,
    'deleted': _ids(resultMap['deleted_product_ids']),
    'active': resultMap['active_product_ids'] is List
        ? _ids(resultMap['active_product_ids'])
        : null,
  };
}

/// Solo para tests.
@visibleForTesting
Map<String, dynamic> parseProductosForTest(String body) =>
    _parseProductosIsolate(body);

// ─── Interfaz ────────────────────────────────────────────────────────────────

abstract class InventarioRemoteDataSource {
  /// product_quants — parsea productos y barcodes en un solo isolate.
  /// Con [since] y [scope] pide solo lo cambiado (el servidor puede igual
  /// responder completo: ver [ProductosSyncResult.full]).
  Future<ProductosSyncResult> syncProductos({String? since, String? scope});

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
  Future<ProductosSyncResult> syncProductos({
    String? since,
    String? scope,
  }) async {
    try {
      final response = await apiService.getInventario(
        endpoint: 'product_quants',
        isunecodePath: true,
        isLoadinDialog: false,
        params: since != null && scope != null
            ? {'since': since, 'scope': scope}
            : const {},
      );

      if (response.statusCode >= 400) {
        throw ServerException(
            'Error del servidor: ${response.statusCode}');
      }

      final result = await compute(_parseProductosIsolate, response.body);

      if (result['sessionExpired'] == true) {
        throw const SessionExpiredException('Sesión expirada');
      }
      if (result['error'] != null) {
        throw ServerException(result['error'] as String);
      }

      return ProductosSyncResult(
        productos: (result['productos'] as List).cast<ProductoInventarioModel>(),
        barcodes: (result['barcodes'] as List).cast<BarcodeProductoModel>(),
        // Si no se pidió incremental, la respuesta es completa sí o sí.
        full: since == null || result['full'] as bool,
        serverTime: result['serverTime'] as String?,
        scope: result['scope'] as String?,
        deletedProductIds: result['deleted'] as List<int>,
        activeProductIds: result['active'] as List<int>?,
      );
    } on SessionExpiredException {
      rethrow;
    } on ServerException {
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
