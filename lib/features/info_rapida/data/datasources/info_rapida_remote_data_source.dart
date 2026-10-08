import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/features/info_rapida/data/models/info_rapida_remote_model.dart';
import 'package:wms_app/features/info_rapida/data/models/transferencia_result_model.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida_params.dart';
import 'package:wms_app/features/info_rapida/domain/entities/transfer_results.dart';
import 'package:wms_app/features/packing_pedido/data/models/odoo_parse.dart';
import 'package:wms_app/src/api/api_request_service.dart';

/// Contrato del origen de datos remoto para Información Rápida.
abstract class InfoRapidaRemoteDataSource {
  /// Consulta información por código de barras.
  Future<InfoRapida> getInfoQuick({
    required String barcode,
    required String deviceId,
    required String versionApp,
    bool isLoadingDialog = false,
  });

  /// Consulta información manual por ID (producto o ubicación).
  Future<InfoRapida> getInfoQuickManual({
    required int id,
    required bool isProduct,
    required String deviceId,
    required String versionApp,
    bool isLoadingDialog = false,
  });

  /// Actualiza los atributos de un producto en el backend.
  Future<ProductoInfo> updateProduct(
    ActualizarProductoParams params, {
    bool isLoadingDialog = false,
  });

  /// Actualiza el nombre y código de barras de una ubicación en el backend.
  Future<UbicacionInfo> updateLocation(
    ActualizarUbicacionParams params, {
    bool isLoadingDialog = false,
  });

  /// Crea una transferencia directa individual de un producto.
  Future<TransferenciaIndividualResult> crearTransferenciaIndividual(
    CrearTransferenciaIndividualParams params, {
    bool isLoadingDialog = false,
  });

  /// Crea una transferencia masiva de múltiples productos.
  Future<TransferenciaMasivaResult> crearTransferenciaMasiva(
    CrearTransferenciaMasivaParams params, {
    bool isLoadingDialog = false,
  });
}

/// Implementación del origen de datos remoto utilizando [ApiRequestService].
@LazySingleton(as: InfoRapidaRemoteDataSource)
class InfoRapidaRemoteDataSourceImpl implements InfoRapidaRemoteDataSource {
  final ApiRequestService _apiService;

  InfoRapidaRemoteDataSourceImpl() : _apiService = ApiRequestService();

  @visibleForTesting
  InfoRapidaRemoteDataSourceImpl.test(this._apiService);

  Map<String, dynamic> _decodeResponse(dynamic response) {
    if (response == null || response.statusCode >= 500) {
      throw ServerException(
        'Error del servidor (${response?.statusCode ?? 500})',
      );
    }

    final dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw ServerException(
        'Respuesta inválida del servidor (${response.statusCode})',
      );
    }

    if (body is! Map<String, dynamic>) {
      throw const ServerException('Respuesta inválida del servidor');
    }

    final error = body['error'];
    if (error is Map) {
      final code = OdooParse.integer(error['code']);
      final msg = OdooParse.str(error['message'] ?? error['msg']);
      if (code == 100) {
        throw const SessionExpiredException(
          'Sesión expirada, por favor inicie sesión nuevamente',
        );
      }
      throw ServerException(msg.isEmpty ? 'Error del servidor' : msg);
    }

    return body;
  }

  @override
  Future<InfoRapida> getInfoQuick({
    required String barcode,
    required String deviceId,
    required String versionApp,
    bool isLoadingDialog = false,
  }) async {
    try {
      final response = await _apiService.getInfo(
        endpoint: 'transferencias/quickinfo',
        body: {
          'params': {
            'device_id': deviceId,
            'barcode': barcode,
            'version_app': versionApp,
          },
        },
        isLoadinDialog: isLoadingDialog,
      );

      final json = _decodeResponse(response);
      return InfoRapidaRemoteModel.fromJsonRpc(json);
    } on SocketException catch (e) {
      throw NetworkException('Error de conexión a la red: $e');
    }
  }

  @override
  Future<InfoRapida> getInfoQuickManual({
    required int id,
    required bool isProduct,
    required String deviceId,
    required String versionApp,
    bool isLoadingDialog = false,
  }) async {
    try {
      final response = await _apiService.getInfo(
        endpoint: 'transferencias/quickinfo/id',
        body: {
          'params': isProduct
              ? {
                  'device_id': deviceId,
                  'id_product': id.toString(),
                  'version_app': versionApp,
                }
              : {
                  'device_id': deviceId,
                  'id_location': id.toString(),
                  'version_app': versionApp,
                },
        },
        isLoadinDialog: isLoadingDialog,
      );

      final json = _decodeResponse(response);
      return InfoRapidaRemoteModel.fromJsonRpc(json);
    } on SocketException catch (e) {
      throw NetworkException('Error de conexión a la red: $e');
    }
  }

  @override
  Future<ProductoInfo> updateProduct(
    ActualizarProductoParams params, {
    bool isLoadingDialog = false,
  }) async {
    try {
      final response = await _apiService.postPacking(
        endpoint: 'update_product',
        body: {
          'params': {
            'product_id': params.productId,
            'default_code': params.defaultCode,
            'name': params.name,
            'barcode': params.barcode,
            'list_price': params.listPrice,
            'weight': params.weight,
            'volume': params.volume,
          },
        },
        isLoadinDialog: isLoadingDialog,
      );

      final json = _decodeResponse(response);
      final info = InfoRapidaRemoteModel.fromJsonRpc(json);
      if (info is! ProductoInfo) {
        throw const ServerException(
          'La respuesta de actualización no devolvió un producto válido',
        );
      }
      return info;
    } on SocketException catch (e) {
      throw NetworkException('Error de conexión a la red: $e');
    }
  }

  @override
  Future<UbicacionInfo> updateLocation(
    ActualizarUbicacionParams params, {
    bool isLoadingDialog = false,
  }) async {
    try {
      final response = await _apiService.postPacking(
        endpoint: 'update_location',
        body: {
          'params': {
            'location_id': params.locationId,
            'name': params.name,
            'barcode': params.barcode,
          },
        },
        isLoadinDialog: isLoadingDialog,
      );

      final json = _decodeResponse(response);
      final info = InfoRapidaRemoteModel.fromJsonRpc(json);
      if (info is! UbicacionInfo) {
        throw const ServerException(
          'La respuesta de actualización no devolvió una ubicación válida',
        );
      }
      return info;
    } on SocketException catch (e) {
      throw NetworkException('Error de conexión a la red: $e');
    }
  }

  @override
  Future<TransferenciaIndividualResult> crearTransferenciaIndividual(
    CrearTransferenciaIndividualParams params, {
    bool isLoadingDialog = false,
  }) async {
    try {
      final response = await _apiService.postPacking(
        endpoint: 'crear_transferencia',
        body: {
          'params': {
            'id_almacen': params.idAlmacen,
            'id_move': params.idMove,
            'id_producto': params.idProducto,
            'id_propietario': params.idPropietario,
            'id_lote': params.idLote,
            'id_ubicacion_origen': params.idUbicacionOrigen,
            'id_ubicacion_destino': params.idUbicacionDestino,
            'cantidad_enviada': params.cantidadEnviada,
            'id_operario': params.idOperario,
            'time_line': params.timeLine,
            'fecha_transaccion': params.fechaTransaccion,
            'observacion': params.observacion,
            'date_start': params.dateStart,
            'date_end': params.dateEnd,
          },
        },
        isLoadinDialog: isLoadingDialog,
      );

      final json = _decodeResponse(response);
      final resultMap = json['result'];
      if (resultMap is! Map<String, dynamic>) {
        throw const ServerException(
          'El servidor respondió sin resultado. Verifique si la transferencia se aplicó.',
        );
      }

      final code = OdooParse.integer(resultMap['code']) ?? 200;
      if (code != 200) {
        final msg = OdooParse.str(resultMap['msg']);
        throw ServerException(
          msg.isEmpty ? 'Error al crear la transferencia ($code)' : msg,
        );
      }

      return TransferenciaResultModel.fromIndividualMap(resultMap);
    } on SocketException catch (e) {
      throw NetworkException('Error de conexión a la red: $e');
    }
  }

  @override
  Future<TransferenciaMasivaResult> crearTransferenciaMasiva(
    CrearTransferenciaMasivaParams params, {
    bool isLoadingDialog = false,
  }) async {
    try {
      final response = await _apiService.postPacking(
        endpoint: 'transferencias/create_trasferencia',
        body: {
          'params': {
            'date_start': params.dateStart,
            'date_end': params.dateEnd,
            'id_almacen': params.idAlmacen,
            'id_ubicacion_origen': params.idUbicacionOrigen,
            'id_ubicacion_destino': params.idUbicacionDestino,
            'id_operario': params.idOperario,
            'fecha_transaccion': params.fechaTransaccion,
            'list_items': params.listItems
                .map(
                  (item) => {
                    'id_producto': item.idProducto,
                    'cantidad_enviada': item.cantidadEnviada,
                    'id_lote': item.idLote,
                    'time_line': item.timeLine,
                    'id_propietario': item.idPropietario,
                    'quantity_segunda_unidad': item.quantitySegundaUnidad,
                  },
                )
                .toList(),
          },
        },
        isLoadinDialog: isLoadingDialog,
      );

      final json = _decodeResponse(response);
      final resultMap = json['result'];
      if (resultMap is! Map<String, dynamic>) {
        throw const ServerException(
          'El servidor respondió sin resultado en la transferencia masiva.',
        );
      }

      final code = OdooParse.integer(resultMap['code']) ?? 200;
      if (code != 200) {
        final msg = OdooParse.str(resultMap['msg']);
        throw ServerException(
          msg.isEmpty ? 'Error al crear la transferencia masiva ($code)' : msg,
        );
      }

      return TransferenciaResultModel.fromMasivaMap(resultMap);
    } on SocketException catch (e) {
      throw NetworkException('Error de conexión a la red: $e');
    }
  }
}
