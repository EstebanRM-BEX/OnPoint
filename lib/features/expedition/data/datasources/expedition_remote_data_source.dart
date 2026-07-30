import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/features/expedition/data/models/expedicion_response_model.dart';
import 'package:wms_app/src/api/api_request_service.dart';

abstract class ExpeditionRemoteDataSource {
  Future<ExpedicionResponseModel> fetchExpediciones({
    required bool isLoadinDialog,
  });

  Future<bool> validarPaquete({
    required int expeditionId,
    required int packingId,
  });

  Future<bool> validarItemSuelto({
    required int expeditionId,
    required int packingId,
  });

  /// Valida varios paquetes y/o productos sueltos de una misma expedición en
  /// una sola llamada: send_out ya recibe packing_id como lista.
  Future<bool> validarMultiple({
    required int expeditionId,
    required List<int> packingIds,
  });

  /// POST api/complete_out: confirma (cierra) el pedido de expedición
  /// completo. Reemplaza al complete_transfer de TransferenciasRepository.
  Future<void> confirmarPedido({
    required int expeditionId,
    bool crearBackorder = false,
  });

  Future<bool> deshacerPaquete({
    required int expeditionId,
    required int packingId,
  });

  Future<bool> deshacerItemSuelto({
    required int expeditionId,
    required int packingId,
  });
}

@LazySingleton(as: ExpeditionRemoteDataSource)
class ExpeditionRemoteDataSourceImpl implements ExpeditionRemoteDataSource {
  @override
  Future<ExpedicionResponseModel> fetchExpediciones({
    required bool isLoadinDialog,
  }) async {
    final response = await ApiRequestService().getValidation(
      endpoint: 'transferencias/out',
      isunecodePath: true,
      isLoadinDialog: isLoadinDialog,
    );

    if (response.statusCode >= 400) {
      throw ServerException('Error de conexión (${response.statusCode})');
    }

    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    final parsed = ExpedicionResponseModel.fromJson(jsonResponse);

    if (parsed.code != 200) {
      throw ServerException(parsed.msg ?? 'Error desconocido al obtener expediciones');
    }

    return parsed;
  }

  @override
  Future<bool> validarPaquete({
    required int expeditionId,
    required int packingId,
  }) {
    return _postExpeditionAction(
        endpoint: 'send_out', expeditionId: expeditionId, packingIds: [packingId]);
  }

  @override
  Future<bool> validarItemSuelto({
    required int expeditionId,
    required int packingId,
  }) {
    return _postExpeditionAction(
        endpoint: 'send_out', expeditionId: expeditionId, packingIds: [packingId]);
  }

  @override
  Future<bool> validarMultiple({
    required int expeditionId,
    required List<int> packingIds,
  }) {
    return _postExpeditionAction(
        endpoint: 'send_out',
        expeditionId: expeditionId,
        packingIds: packingIds);
  }

  /// Mismo body que el viejo complete_transfer (id_transferencia +
  /// crear_backorder), pero contra api/complete_out. [crearBackorder] llega
  /// en true cuando el usuario confirmó con paquetes o productos sueltos
  /// pendientes en "Por hacer" y eligió crear backorder para lo pendiente.
  ///
  /// El `msg` del backend se propaga tal cual en la excepción porque la UI
  /// lo inspecciona: si contiene `expiry.picking.confirmation` ofrece el
  /// reintento forzando productos vencidos.
  @override
  Future<void> confirmarPedido({
    required int expeditionId,
    bool crearBackorder = false,
  }) async {
    final response = await ApiRequestService().postPacking(
      endpoint: 'complete_out',
      body: {
        "params": {
          "id_transferencia": expeditionId,
          "crear_backorder": crearBackorder,
        }
      },
      isLoadinDialog: false,
    );

    if (response.statusCode >= 400) {
      throw ServerException('Error de conexión (${response.statusCode})');
    }

    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    if (jsonResponse['result'] != null &&
        jsonResponse['result']['code'] == 200) {
      return;
    }

    throw ServerException(jsonResponse['result']?['msg'] ??
        jsonResponse['error']?['message'] ??
        'Error al confirmar la expedición');
  }

  @override
  Future<bool> deshacerPaquete({
    required int expeditionId,
    required int packingId,
  }) {
    return _postExpeditionAction(
        endpoint: 'out_return', expeditionId: expeditionId, packingIds: [packingId]);
  }

  @override
  Future<bool> deshacerItemSuelto({
    required int expeditionId,
    required int packingId,
  }) {
    return _postExpeditionAction(
        endpoint: 'out_return', expeditionId: expeditionId, packingIds: [packingId]);
  }

  /// POST send_out (validar) / out_return (deshacer): ambos reciben el mismo
  /// body {"params": {"device_id", "expedition_id", "packing_id": [...]}}.
  /// La validación de a uno manda una lista de 1 elemento; la múltiple manda
  /// todos los packing_id seleccionados en la misma llamada.
  Future<bool> _postExpeditionAction({
    required String endpoint,
    required int expeditionId,
    required List<int> packingIds,
  }) async {
    final mac = await PrefUtils.getMacPDA();
    final imei = await PrefUtils.getImeiPDA();

    final response = await ApiRequestService().postPacking(
      endpoint: endpoint,
      body: {
        "params": {
          "device_id": mac == "02:00:00:00:00:00" ? imei : mac,
          "expedition_id": expeditionId,
          "packing_id": packingIds,
        }
      },
      isLoadinDialog: false,
    );

    if (response.statusCode >= 400) {
      throw ServerException('Error de conexión (${response.statusCode})');
    }

    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    if (jsonResponse['result'] != null &&
        jsonResponse['result']['code'] == 200) {
      return true;
    }

    throw ServerException(jsonResponse['result']?['msg'] ??
        jsonResponse['error']?['msg'] ??
        'Error al confirmar la expedición');
  }
}
