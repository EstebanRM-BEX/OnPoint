import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/features/transferencia_multiusuario/data/models/transferencia_claim_model.dart';
import 'package:wms_app/features/transferencia_multiusuario/data/models/transferencia_lote_producto_model.dart';
import 'package:wms_app/features/transferencia_multiusuario/data/models/transferencia_pool_item_model.dart';
import 'package:wms_app/features/transferencia_multiusuario/data/models/transferencia_session_model.dart';
import 'package:wms_app/features/transferencia_multiusuario/data/models/transferencia_snapshot_model.dart';
import 'package:wms_app/src/api/api_request_service.dart';

abstract class TransferenciaMultiusuarioRemoteDataSource {
  Future<List<TransferenciaSessionModel>> fetchSessions({
    required bool isLoadinDialog,
  });

  /// POST /api/transfer/session/{sessionId}/pool: productos/tareas libres de
  /// una sesión en este momento. [verification] cambia qué trae el backend:
  /// en false (tab "Por hacer") solo lo realmente disponible para reclamar;
  /// en true (tab "Terminados") incluye tareas ya agotadas con historial de
  /// asignaciones — mismo criterio que recepción multiusuario.
  Future<List<TransferenciaPoolItemModel>> fetchPool({
    required int sessionId,
    required bool isLoadinDialog,
    required bool verification,
  });

  /// POST /api/transfer/claim: reclama ("toma") un producto libre del pool.
  /// Si el backend responde `status: "error"` (ej. otro operario ya lo
  /// tomó) lanza [ServerException] con el mensaje tal cual vino.
  Future<TransferenciaClaimModel> claimProduct({
    required int sessionId,
    required int productId,
  });

  /// POST /api/transfer/session/{sessionId}: estado actualizado de la
  /// sesión (progress_percent, pending_tasks, qty_asignada_total, etc.) —
  /// se llama al entrar al tab "Detalle" para refrescar lo que ya venía de
  /// /transfer/sessions (que puede estar desactualizado si otro operario
  /// avanzó la transferencia mientras tanto). Misma forma de objeto que un
  /// elemento de /transfer/sessions, así que se reusa
  /// [TransferenciaSessionModel]. A diferencia de recepción (que usa el
  /// picking_id: receipt/picking/{pickingId}), acá la ruta usa el propio
  /// id de la sesión.
  Future<TransferenciaSessionModel> fetchSessionDetail({
    required int sessionId,
    required bool isLoadinDialog,
  });

  /// POST /api/transfer/session/{sessionId}/my_claims: productos que el
  /// usuario actual ya reclamó y sigue trabajando en esta sesión. Mismo
  /// shape de item que el `data` de [claimProduct], así que se reusa
  /// [TransferenciaClaimModel].
  Future<List<TransferenciaClaimModel>> fetchMyClaims({
    required int sessionId,
    required bool isLoadinDialog,
  });

  /// POST /api/transfer/claim/{claimId}/release: libera una asignación
  /// (deja de estar reclamada por el usuario actual, vuelve al pool).
  Future<void> releaseClaim({required int claimId});

  /// POST /api/transfer/session/{sessionId}/snapshot: cabecera + pool + mis
  /// asignados en una sola llamada. Se usa solo en la carga inicial de la
  /// pantalla de detalle (ver TransferenciaSnapshotModel.fromJson para el
  /// porqué de no usarlo para "Por hacer").
  Future<TransferenciaSnapshotModel> fetchSnapshot({
    required int sessionId,
    required bool isLoadinDialog,
  });

  /// GET /api/lotes/{productId}: lotes existentes del producto (dato de
  /// producto, no de sesión — mismo endpoint genérico que recepción).
  Future<List<TransferenciaLoteProductoModel>> fetchLotesProduct({
    required int productId,
    required bool isLoadinDialog,
  });

  /// POST /api/create_lote: crea un lote nuevo para un producto. Si el
  /// backend responde `code: 202` (fecha de vencimiento anterior a hoy,
  /// pero el usuario tiene permiso de forzarla) lanza
  /// [ConfirmationRequiredException] para que la UI ofrezca reintentar con
  /// `priorityExpiration: true`.
  Future<TransferenciaLoteProductoModel> createLote({
    required int productId,
    required String nombreLote,
    required String fechaVencimiento,
    required bool priorityExpiration,
    required bool isLoadinDialog,
  });

  /// POST /api/transfer/claim/{claimId}/done: confirma [qtyDone] para este
  /// claim. Body confirmado por el doc/Postman real: `qty_done`,
  /// `location_dest_id`, `observation`, `time_line`, `lot_id` — nada de
  /// ubicación origen (el backend ya la conoce por el claim). Se le suma
  /// `quantity_segunda_unidad` (mismo nombre que usa `send_transfer` en el
  /// módulo legacy de transferencia interna). Devuelve el claim actualizado
  /// (`state: "done"`), misma forma que [claimProduct]/[fetchMyClaims].
  Future<TransferenciaClaimModel> finishClaim({
    required int claimId,
    required double qtyDone,
    required int lotId,
    required int locationDestId,
    required int timeLine,
    required String observation,
    double quantitySegundaUnidad = 0.0,
  });

  /// POST /api/transfer/claim/{claimId}/undo: deshace una transferencia ya
  /// terminada (state "done" → "released"), liberando la cantidad de
  /// vuelta al pool. Requiere `observacion` con el motivo. El response trae
  /// el claim actualizado (misma forma que finishClaim), pero se descarta —
  /// mismo criterio que recepción: el pool se refresca aparte.
  Future<void> undoClaim({required int claimId, required String observacion});

  /// POST /api/transfer/claim/{claimId}/heartbeat: renueva el bloqueo
  /// temporal del claim (`bloqueado_hasta`/`locked_until`, ver
  /// claim_ttl_minutes de la sesión) mientras el operario sigue en
  /// scan_product_screen.dart, para que no expire y vuelva solo al pool a
  /// mitad del proceso. Sin params confirmados (se asume `{}` como
  /// /release, que tampoco los necesita). Devuelve el claim actualizado,
  /// misma forma que finishClaim/claimProduct — se descarta, el heartbeat
  /// es solo un ping en background.
  Future<void> heartbeat({required int claimId});
}

@LazySingleton(as: TransferenciaMultiusuarioRemoteDataSource)
class TransferenciaMultiusuarioRemoteDataSourceImpl
    implements TransferenciaMultiusuarioRemoteDataSource {
  @override
  Future<List<TransferenciaSessionModel>> fetchSessions({
    required bool isLoadinDialog,
  }) async {
    // A diferencia de la mayoría de rutas /api/* de este backend (que
    // aceptan solo {"params": {...}}), /api/transfer/sessions espera el
    // sobre jsonrpc completo (jsonrpc/method/params) — confirmado por el
    // ejemplo real de la ruta. Mismo caso que receipt/claim/{id}/done.
    final response = await ApiRequestService().postPacking(
      endpoint: 'transfer/sessions',
      body: const {"jsonrpc": "2.0", "method": "call", "params": {}},
      isLoadinDialog: isLoadinDialog,
    );

    if (response.statusCode >= 400) {
      throw ServerException('Error de conexión (${response.statusCode})');
    }

    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    final result = jsonResponse['result'] as Map<String, dynamic>?;

    if (result == null || result['status'] != 'success') {
      throw ServerException(
        result?['message'] ?? 'Error al obtener las transferencias',
      );
    }

    final data = result['data'] as List? ?? [];
    return data
        .map(
          (json) =>
              TransferenciaSessionModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<List<TransferenciaPoolItemModel>> fetchPool({
    required int sessionId,
    required bool isLoadinDialog,
    required bool verification,
  }) async {
    // Mismo sobre jsonrpc completo que fetchSessions — confirmado que
    // /api/transfer/* lo requiere siempre, a diferencia de recepción donde
    // solo done/undo lo necesitan.
    final response = await ApiRequestService().postPacking(
      endpoint: 'transfer/session/$sessionId/pool',
      body: {
        "jsonrpc": "2.0",
        "method": "call",
        "params": verification ? {"verification": true} : {},
      },
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
          (json) => TransferenciaPoolItemModel.fromJson(
            json as Map<String, dynamic>,
            sessionId: sessionId,
          ),
        )
        .toList();
  }

  @override
  Future<TransferenciaClaimModel> claimProduct({
    required int sessionId,
    required int productId,
  }) async {
    // Mismo body que recepción (session_id + product_id), envuelto en el
    // sobre jsonrpc completo — confirmado que /api/transfer/* lo requiere
    // siempre.
    final response = await ApiRequestService().postPacking(
      endpoint: 'transfer/claim',
      body: {
        "jsonrpc": "2.0",
        "method": "call",
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
      // Rechazo de negocio (ej. "ya fue reclamado por otro operario"): el
      // mensaje del backend se propaga tal cual para mostrarlo al operario.
      throw ServerException(
        result?['message'] ?? 'No se pudo reclamar el producto',
      );
    }

    return TransferenciaClaimModel.fromJson(
      result['data'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  Future<TransferenciaSessionModel> fetchSessionDetail({
    required int sessionId,
    required bool isLoadinDialog,
  }) async {
    final response = await ApiRequestService().postPacking(
      endpoint: 'transfer/session/$sessionId',
      body: const {"jsonrpc": "2.0", "method": "call", "params": {}},
      isLoadinDialog: isLoadinDialog,
    );

    if (response.statusCode >= 400) {
      throw ServerException('Error de conexión (${response.statusCode})');
    }

    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    final result = jsonResponse['result'] as Map<String, dynamic>?;

    if (result == null || result['status'] != 'success') {
      throw ServerException(
        result?['message'] ?? 'Error al obtener el detalle de la transferencia',
      );
    }

    return TransferenciaSessionModel.fromJson(
      result['data'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  Future<List<TransferenciaClaimModel>> fetchMyClaims({
    required int sessionId,
    required bool isLoadinDialog,
  }) async {
    final response = await ApiRequestService().postPacking(
      endpoint: 'transfer/session/$sessionId/my_claims',
      body: const {"jsonrpc": "2.0", "method": "call", "params": {}},
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
          (json) =>
              TransferenciaClaimModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<void> releaseClaim({required int claimId}) async {
    final response = await ApiRequestService().postPacking(
      endpoint: 'transfer/claim/$claimId/release',
      body: const {"jsonrpc": "2.0", "method": "call", "params": {}},
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
  Future<TransferenciaSnapshotModel> fetchSnapshot({
    required int sessionId,
    required bool isLoadinDialog,
  }) async {
    final response = await ApiRequestService().postPacking(
      endpoint: 'transfer/session/$sessionId/snapshot',
      body: const {"jsonrpc": "2.0", "method": "call", "params": {}},
      isLoadinDialog: isLoadinDialog,
    );

    if (response.statusCode >= 400) {
      throw ServerException('Error de conexión (${response.statusCode})');
    }

    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    final result = jsonResponse['result'] as Map<String, dynamic>?;

    if (result == null || result['status'] != 'success') {
      throw ServerException(
        result?['message'] ?? 'Error al obtener la transferencia',
      );
    }

    return TransferenciaSnapshotModel.fromJson(
      result['data'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  Future<List<TransferenciaLoteProductoModel>> fetchLotesProduct({
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
        .map(
          (json) => TransferenciaLoteProductoModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  @override
  Future<TransferenciaLoteProductoModel> createLote({
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
      return TransferenciaLoteProductoModel.fromJson(
        result?['result'] as Map<String, dynamic>? ?? {},
      );
    }

    final message = result?['msg']?.toString() ?? 'Error al crear el lote';
    if (code == 202) {
      throw ConfirmationRequiredException(message);
    }
    throw ServerException(message);
  }

  @override
  Future<TransferenciaClaimModel> finishClaim({
    required int claimId,
    required double qtyDone,
    required int lotId,
    required int locationDestId,
    required int timeLine,
    required String observation,
    double quantitySegundaUnidad = 0.0,
  }) async {
    // Body confirmado con Postman real: qty_done, location_dest_id,
    // observation, time_line, lot_id — sin ubicación origen (el backend ya
    // la conoce por el claim). quantity_segunda_unidad se suma con el
    // mismo nombre que usa send_transfer en transferencia interna (legacy);
    // sin confirmar todavía por Postman contra este endpoint. Mismo sobre
    // jsonrpc completo que el resto de /api/transfer/*.
    final response = await ApiRequestService().postPacking(
      endpoint: 'transfer/claim/$claimId/done',
      body: {
        "jsonrpc": "2.0",
        "method": "call",
        "params": {
          "qty_done": qtyDone,
          "location_dest_id": locationDestId,
          "observation": observation,
          "time_line": timeLine,
          "lot_id": lotId,
          "quantity_segunda_unidad": quantitySegundaUnidad,
        },
      },
      isLoadinDialog: false,
    );

    if (response.statusCode >= 400) {
      throw ServerException('Error de conexión (${response.statusCode})');
    }

    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    final result = jsonResponse['result'] as Map<String, dynamic>?;

    if (result == null || result['status'] != 'success') {
      throw ServerException(
        result?['message'] ?? 'No se pudo confirmar la transferencia',
      );
    }

    return TransferenciaClaimModel.fromJson(
      result['data'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  Future<void> undoClaim({
    required int claimId,
    required String observacion,
  }) async {
    // Mismo sobre jsonrpc completo que /done — confirmado con Postman real.
    final response = await ApiRequestService().postPacking(
      endpoint: 'transfer/claim/$claimId/undo',
      body: {
        "jsonrpc": "2.0",
        "method": "call",
        "params": {"observacion": observacion},
      },
      isLoadinDialog: false,
    );

    if (response.statusCode >= 400) {
      throw ServerException('Error de conexión (${response.statusCode})');
    }

    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    final result = jsonResponse['result'] as Map<String, dynamic>?;

    if (result == null || result['status'] != 'success') {
      throw ServerException(
        result?['message'] ?? 'No se pudo deshacer la transferencia',
      );
    }
  }

  @override
  Future<void> heartbeat({required int claimId}) async {
    final response = await ApiRequestService().postPacking(
      endpoint: 'transfer/claim/$claimId/heartbeat',
      body: const {"jsonrpc": "2.0", "method": "call", "params": {}},
      isLoadinDialog: false,
    );

    if (response.statusCode >= 400) {
      throw ServerException('Error de conexión (${response.statusCode})');
    }

    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    final result = jsonResponse['result'] as Map<String, dynamic>?;

    if (result == null || result['status'] != 'success') {
      throw ServerException(
        result?['message'] ?? 'No se pudo renovar el bloqueo del claim',
      );
    }
  }
}
