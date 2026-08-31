import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/features/recepcion_multiusuario/data/models/lote_producto_model.dart';
import 'package:wms_app/features/recepcion_multiusuario/data/models/recepcion_claim_model.dart';
import 'package:wms_app/features/recepcion_multiusuario/data/models/recepcion_pool_item_model.dart';
import 'package:wms_app/features/recepcion_multiusuario/data/models/recepcion_session_model.dart';
import 'package:wms_app/src/api/api_request_service.dart';

abstract class RecepcionMultiusuarioRemoteDataSource {
  Future<List<RecepcionSessionModel>> fetchSessions({
    required bool isLoadinDialog,
  });

  /// POST /api/receipt/session/{sessionId}/pool: productos/tareas libres de
  /// una sesión en este momento. Se va a llamar seguido (cada refresco de la
  /// pantalla de detalle), así que sin isLoadinDialog por defecto.
  Future<List<RecepcionPoolItemModel>> fetchPool({
    required int sessionId,
    required bool isLoadinDialog,
  });

  /// POST /api/receipt/claim: reclama ("toma") un producto libre del pool.
  /// Si el backend responde `status: "error"` (ej. otro operario ya lo tomó)
  /// lanza [ServerException] con el mensaje tal cual vino, para que la UI lo
  /// muestre y NO navegue a scan_product.
  Future<RecepcionClaimModel> claimProduct({
    required int sessionId,
    required int productId,
  });

  /// POST /api/receipt/session/{sessionId}/my_claims: productos que el
  /// usuario actual ya reclamó y sigue trabajando en esta sesión. Mismo
  /// shape de item que el `data` de [claimProduct], así que se reusa
  /// [RecepcionClaimModel] para parsear la lista.
  Future<List<RecepcionClaimModel>> fetchMyClaims({
    required int sessionId,
    required bool isLoadinDialog,
  });

  /// POST /api/receipt/claim/{claimId}/release: libera una asignación
  /// (deja de estar reclamada por el usuario actual, vuelve al pool).
  Future<void> releaseClaim({required int claimId});

  /// GET /api/lotes/{productId}: lotes existentes de un producto. Mismo
  /// endpoint que usa recepción individual — los lotes son un dato de
  /// producto, no algo propio de multiusuario.
  Future<List<LoteProductoModel>> fetchLotesProduct({
    required int productId,
    required bool isLoadinDialog,
  });

  /// POST /api/create_lote: crea un lote nuevo para un producto. Si el
  /// backend responde `code: 202` (fecha de vencimiento anterior a hoy, pero
  /// el usuario tiene permiso de forzarla) lanza
  /// [ConfirmationRequiredException] para que la UI ofrezca reintentar con
  /// `priorityExpiration: true`.
  Future<LoteProductoModel> createLote({
    required int productId,
    required String nombreLote,
    required String fechaVencimiento,
    required bool priorityExpiration,
    required bool isLoadinDialog,
  });
}

@LazySingleton(as: RecepcionMultiusuarioRemoteDataSource)
class RecepcionMultiusuarioRemoteDataSourceImpl
    implements RecepcionMultiusuarioRemoteDataSource {
  @override
  Future<List<RecepcionSessionModel>> fetchSessions({
    required bool isLoadinDialog,
  }) async {
    // /api/receipt/sessions es una ruta JSON-RPC de Odoo (responde con el
    // sobre {"jsonrpc", "result": {...}}), que solo acepta POST — un GET
    // (getValidation) devuelve 405 Method Not Allowed.
    final response = await ApiRequestService().postPacking(
      endpoint: 'receipt/sessions',
      body: const {"params": {}},
      isLoadinDialog: isLoadinDialog,
    );

    if (response.statusCode >= 400) {
      throw ServerException('Error de conexión (${response.statusCode})');
    }

    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    final result = jsonResponse['result'] as Map<String, dynamic>?;

    if (result == null || result['status'] != 'success') {
      throw ServerException(
        result?['message'] ?? 'Error al obtener las recepciones',
      );
    }

    final data = result['data'] as List? ?? [];
    return data
        .map(
          (json) =>
              RecepcionSessionModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<List<RecepcionPoolItemModel>> fetchPool({
    required int sessionId,
    required bool isLoadinDialog,
  }) async {
    final response = await ApiRequestService().postPacking(
      endpoint: 'receipt/session/$sessionId/pool',
      body: const {"params": {}},
      isLoadinDialog: isLoadinDialog,
    );

    if (response.statusCode >= 400) {
      throw ServerException('Error de conexión (${response.statusCode})');
    }

    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    final result = jsonResponse['result'] as Map<String, dynamic>?;

    if (result == null || result['status'] != 'success') {
      throw ServerException(
        result?['message'] ?? 'Error al obtener el pool de la sesión',
      );
    }

    final data = result['data'] as List? ?? [];
    return data
        .map(
          (json) => RecepcionPoolItemModel.fromJson(
            json as Map<String, dynamic>,
            sessionId: sessionId,
          ),
        )
        .toList();
  }

  @override
  Future<RecepcionClaimModel> claimProduct({
    required int sessionId,
    required int productId,
  }) async {
    final response = await ApiRequestService().postPacking(
      endpoint: 'receipt/claim',
      body: {
        "params": {"session_id": sessionId, "product_id": productId},
      },
      isLoadinDialog: false,
    );

    if (response.statusCode >= 400) {
      throw ServerException('Error de conexión (${response.statusCode})');
    }

    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    final result = jsonResponse['result'] as Map<String, dynamic>?;

    if (result == null || result['status'] != 'success') {
      // Rechazo de negocio (ej. "no está pendiente en esta sesión"): el
      // mensaje del backend se propaga tal cual para mostrarlo al operario.
      throw ServerException(
        result?['message'] ?? 'No se pudo reclamar el producto',
      );
    }

    return RecepcionClaimModel.fromJson(
      result['data'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  Future<List<RecepcionClaimModel>> fetchMyClaims({
    required int sessionId,
    required bool isLoadinDialog,
  }) async {
    final response = await ApiRequestService().postPacking(
      endpoint: 'receipt/session/$sessionId/my_claims',
      body: const {"params": {}},
      isLoadinDialog: isLoadinDialog,
    );

    if (response.statusCode >= 400) {
      throw ServerException('Error de conexión (${response.statusCode})');
    }

    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    final result = jsonResponse['result'] as Map<String, dynamic>?;

    if (result == null || result['status'] != 'success') {
      throw ServerException(
        result?['message'] ?? 'Error al obtener mis productos asignados',
      );
    }

    final data = result['data'] as List? ?? [];
    return data
        .map(
          (json) => RecepcionClaimModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<void> releaseClaim({required int claimId}) async {
    final response = await ApiRequestService().postPacking(
      endpoint: 'receipt/claim/$claimId/release',
      body: const {"params": {}},
      isLoadinDialog: false,
    );

    if (response.statusCode >= 400) {
      throw ServerException('Error de conexión (${response.statusCode})');
    }

    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    final result = jsonResponse['result'] as Map<String, dynamic>?;

    if (result == null || result['status'] != 'success') {
      throw ServerException(
        result?['message'] ?? 'No se pudo liberar la asignación',
      );
    }
  }

  @override
  Future<List<LoteProductoModel>> fetchLotesProduct({
    required int productId,
    required bool isLoadinDialog,
  }) async {
    final response = await ApiRequestService().get(
      endpoint: 'lotes/$productId',
      isunecodePath: true,
      isLoadinDialog: isLoadinDialog,
    );

    if (response.statusCode >= 400) {
      throw ServerException('Error de conexión (${response.statusCode})');
    }

    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    final result = jsonResponse['result'] as Map<String, dynamic>?;
    if (result == null) {
      throw ServerException('Error al obtener los lotes del producto');
    }

    final data = result['result'] as List? ?? [];
    return data
        .map((json) => LoteProductoModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LoteProductoModel> createLote({
    required int productId,
    required String nombreLote,
    required String fechaVencimiento,
    required bool priorityExpiration,
    required bool isLoadinDialog,
  }) async {
    final response = await ApiRequestService().postPacking(
      endpoint: 'create_lote',
      isLoadinDialog: isLoadinDialog,
      body: {
        "params": {
          "id_producto": productId,
          "nombre_lote": nombreLote,
          "fecha_vencimiento": fechaVencimiento,
          "priority_expiration": priorityExpiration,
        },
      },
    );

    if (response.statusCode >= 400) {
      throw ServerException('Error de conexión (${response.statusCode})');
    }

    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    final result = jsonResponse['result'] as Map<String, dynamic>?;
    final code = result?['code'];

    if (code == 200) {
      return LoteProductoModel.fromJson(
        result?['result'] as Map<String, dynamic>? ?? {},
      );
    }

    final message = result?['msg']?.toString() ?? 'Error al crear el lote';
    if (code == 202) {
      throw ConfirmationRequiredException(message);
    }
    throw ServerException(message);
  }
}
