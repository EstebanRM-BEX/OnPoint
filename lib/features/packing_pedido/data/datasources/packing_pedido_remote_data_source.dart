import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/features/packing_pedido/data/models/odoo_parse.dart';
import 'package:wms_app/features/packing_pedido/data/models/packing_api_models.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/paquete_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/pedido_pack.dart';
import 'package:wms_app/src/api/api_request_service.dart';

/// Resultado de `transferencias/pack`.
class PedidosPackApiResult {
  final List<PedidoPackApi> pedidos;
  final bool updateVersion;

  const PedidosPackApiResult({
    required this.pedidos,
    this.updateVersion = false,
  });
}

/// Línea que se manda a crear un paquete.
class ItemEmpaqueApi {
  final int idMove;
  final int idProducto;
  final double cantidadEnviada;
  final int idUbicacionOrigen;
  final int idUbicacionDestino;
  final int idLote;
  final int idOperario;
  final String fechaTransaccion;
  final double timeLine;
  final String observacion;

  const ItemEmpaqueApi({
    required this.idMove,
    required this.idProducto,
    required this.cantidadEnviada,
    required this.idUbicacionOrigen,
    required this.idUbicacionDestino,
    required this.idLote,
    required this.idOperario,
    required this.fechaTransaccion,
    required this.timeLine,
    required this.observacion,
  });

  Map<String, dynamic> toMap() => {
    'id_move': idMove,
    'id_producto': idProducto,
    'cantidad_enviada': cantidadEnviada,
    'id_ubicacion_origen': idUbicacionOrigen,
    'id_ubicacion_destino': idUbicacionDestino,
    'id_lote': idLote,
    'id_operario': idOperario,
    'fecha_transaccion': fechaTransaccion,
    'time_line': timeLine,
    'observacion': observacion,
  };
}

/// Endpoints de Odoo del packing por pedido. Mismos bodies que el módulo
/// legacy, pero sin diálogos: los errores salen como excepciones tipadas y
/// la presentación decide cómo mostrarlos.
abstract class PackingPedidoRemoteDataSource {
  Future<PedidosPackApiResult> fetchPedidos({required bool isLoadingDialog});

  Future<void> asignarResponsable({required int pedidoId, required int userId});

  /// [campo] = `start_time_transfer` o `end_time_transfer`.
  Future<void> enviarTiempo({
    required int pedidoId,
    required String campo,
    required String hora,
  });

  Future<PaqueteCreadoApi> crearPaquete({
    required PedidoPack pedido,
    required bool esCluster,
    required bool isSticker,
    required bool certificado,
    required double peso,
    required int tipoPaqueteId,
    required String tipoPaqueteNombre,
    required List<ItemEmpaqueApi> items,
  });

  Future<MovesDevueltosApi> desempacar({
    required int pedidoId,
    required int paqueteId,
    required int idMove,
    required int idOperario,
  });

  Future<MovesDevueltosApi> eliminarPaquete({
    required int pedidoId,
    required int paqueteId,
  });

  Future<String> asignarUbicacion({
    required int pedidoId,
    required List<int> paqueteIds,
    required int ubicacionId,
  });

  /// Lanza [VencidosException] si Odoo pide confirmar productos vencidos.
  Future<String> validarPedido({
    required int pedidoId,
    required bool crearBackorder,
    required bool aceptarVencidos,
  });

  Future<TemperaturaIa> leerTemperatura(String imagePath);

  /// Devuelve la URL de la imagen (vacía si fue manual).
  Future<String> enviarTemperatura({
    required int idMove,
    required double temperatura,
    String? imagePath,
  });

  Future<String> enviarImagenNovedad({
    required int idMove,
    required String imagePath,
  });
}

/// Odoo pide confirmar productos con fecha de caducidad alcanzada.
class VencidosException implements Exception {
  final String message;
  const VencidosException(this.message);

  @override
  String toString() => 'VencidosException: $message';
}

@LazySingleton(as: PackingPedidoRemoteDataSource)
class PackingPedidoRemoteDataSourceImpl
    implements PackingPedidoRemoteDataSource {
  PackingPedidoRemoteDataSourceImpl();

  ApiRequestService get _api => ApiRequestService();

  // ── Helpers de respuesta ──────────────────────────────────────────────────

  /// JSON de la respuesta; convierte los errores JSON-RPC en excepciones.
  static Map<String, dynamic> decode(http.Response response) {
    final dynamic json;
    try {
      json = jsonDecode(response.body);
    } catch (_) {
      throw ServerException(
        'Respuesta inválida del servidor (${response.statusCode})',
      );
    }
    if (json is! Map<String, dynamic>) {
      throw const ServerException('Respuesta inválida del servidor');
    }

    final error = json['error'];
    if (error is Map) {
      final code = error['code'];
      final data = error['data'];
      final msg = OdooParse.str(
        error['msg'] ??
            error['message'] ??
            (data is Map ? data['message'] : null),
      );
      if (code == 100) {
        throw const SessionExpiredException(
          'Sesión expirada, por favor inicie sesión nuevamente',
        );
      }
      if (data is Map && data['name'] == 'client_network_error') {
        throw NetworkException(msg.isEmpty ? 'Error de red' : msg);
      }
      throw ServerException(msg.isEmpty ? 'Error del servidor' : msg);
    }
    return json;
  }

  /// `result` de una respuesta JSON-RPC con `code` 200; si no, excepción.
  static Map<String, dynamic> result(Map<String, dynamic> json) {
    final r = json['result'];
    if (r is! Map<String, dynamic>) {
      throw const ServerException('Respuesta sin resultado del servidor');
    }
    final code = OdooParse.integer(r['code']);
    if (code == 200) return r;
    if (code == 403) {
      throw const ServerException(
        'Este dispositivo no está autorizado para usar la aplicación. '
        'Contacte con el administrador.',
      );
    }
    final msg = OdooParse.str(r['msg'] ?? r['mensaje']);
    throw ServerException(msg.isEmpty ? 'Error del servidor' : msg);
  }

  /// Respuestas planas (endpoints multipart): `{code, msg, ...}`.
  static Map<String, dynamic> plano(http.Response response) {
    final json = decode(response);
    final code = OdooParse.integer(json['code']);
    if (code == 200) return json;
    final msg = OdooParse.str(json['msg'] ?? json['detail']);
    throw ServerException(msg.isEmpty ? 'Error del servidor' : msg);
  }

  Future<http.Response> _post(String endpoint, Map<String, dynamic> params) =>
      _api.postPacking(
        endpoint: endpoint,
        body: {'params': params},
        isLoadinDialog: false,
      );

  // ── Endpoints ─────────────────────────────────────────────────────────────

  @override
  Future<PedidosPackApiResult> fetchPedidos({
    required bool isLoadingDialog,
  }) async {
    final response = await _api.getValidation(
      endpoint: 'transferencias/pack',
      isunecodePath: true,
      isLoadinDialog: isLoadingDialog,
    );
    final r = result(decode(response));
    return PedidosPackApiResult(
      pedidos: [
        for (final p in OdooParse.maps(r['result'])) PedidoPackApi.fromMap(p),
      ],
      updateVersion: OdooParse.boolean(r['update_version']),
    );
  }

  @override
  Future<void> asignarResponsable({
    required int pedidoId,
    required int userId,
  }) async {
    final response = await _post('transferencias/asignar', {
      'id_transferencia': pedidoId,
      'id_responsable': userId,
    });
    final json = decode(response);
    final r = json['result'];
    if (r is Map && OdooParse.integer(r['code']) != 200) {
      final msg = OdooParse.str(r['msg']);
      throw ServerException(
        msg.isEmpty ? 'El pedido ya tiene un responsable asignado' : msg,
      );
    }
    result(json);
  }

  @override
  Future<void> enviarTiempo({
    required int pedidoId,
    required String campo,
    required String hora,
  }) async {
    final response = await _post('update_time_transfer', {
      'transfer_id': pedidoId,
      'time': hora,
      'field_name': campo,
    });
    result(decode(response));
  }

  @override
  Future<PaqueteCreadoApi> crearPaquete({
    required PedidoPack pedido,
    required bool esCluster,
    required bool isSticker,
    required bool certificado,
    required double peso,
    required int tipoPaqueteId,
    required String tipoPaqueteNombre,
    required List<ItemEmpaqueApi> items,
  }) async {
    final response =
        await _post(esCluster ? 'send_cluster/pack' : 'send_transfer/pack', {
          'id_transferencia': pedido.id,
          'is_sticker': isSticker,
          'is_certificate': certificado,
          'tipo_paquete': tipoPaqueteId,
          'peso_caja': peso,
          'peso_total_paquete': peso,
          'list_items': items.map((i) => i.toMap()).toList(),
        });
    final r = result(decode(response));
    final elementos = OdooParse.maps(r['result']);
    if (elementos.isEmpty) {
      throw const ServerException('El servidor no devolvió el paquete creado');
    }
    final e = elementos.first;

    final paquete = PaquetePacking(
      id: OdooParse.integer(e['id_paquete']) ?? 0,
      pedidoId: pedido.id,
      batchId: OdooParse.integer(e['id_batch']) ?? pedido.batchId,
      name: OdooParse.str(e['name_paquete']),
      packingBarcode: OdooParse.str(e['packing_barcode']),
      consecutivo: OdooParse.str(e['consecutivo']),
      cantidadProductos:
          OdooParse.integer(e['cantidad_productos_en_el_paquete']) ??
          items.length,
      isSticker: isSticker,
      isCertificate: certificado,
      typePaquete: tipoPaqueteNombre,
      peso: peso,
      locationDestId: pedido.locationDestId,
      locationDestName: pedido.locationDestName,
      locationDestBarcode: pedido.locationDestBarcode,
    );
    if (paquete.id == 0) {
      throw const ServerException('El servidor no devolvió el id del paquete');
    }

    return PaqueteCreadoApi(
      paquete: paquete,
      filasEmpacadas: [
        for (final m in OdooParse.maps(e['list_item']))
          PedidoPackApi.productoFromApi(
            m,
            pedidoId: pedido.id,
            paquete: paquete,
            certificado: certificado,
          ),
      ],
    );
  }

  @override
  Future<MovesDevueltosApi> desempacar({
    required int pedidoId,
    required int paqueteId,
    required int idMove,
    required int idOperario,
  }) async {
    final response = await _post('transferencias/unpacking', {
      'id_transferencia': pedidoId,
      'id_paquete': paqueteId,
      'list_items': [
        {
          'id_move': idMove,
          'observacion': 'Desempacado',
          'id_operario': idOperario,
        },
      ],
    });
    final r = result(decode(response));

    // result.result mezcla moves (con id_move) y, si la caja quedó vacía,
    // un item {code, msg} sin id_move.
    final moves = <Map<String, dynamic>>[];
    var eliminado = false;
    var msg = OdooParse.str(r['msg']);
    for (final item in OdooParse.maps(r['result'])) {
      if (item['id_move'] != null) {
        moves.add(item);
      } else if (item['msg'] != null &&
          OdooParse.integer(item['code']) == 200) {
        eliminado = true;
        if (msg.isEmpty) msg = OdooParse.str(item['msg']);
      }
    }
    return MovesDevueltosApi(
      mensaje: msg.isEmpty ? 'Producto desempacado' : msg,
      moves: moves,
      paqueteEliminado: eliminado,
    );
  }

  @override
  Future<MovesDevueltosApi> eliminarPaquete({
    required int pedidoId,
    required int paqueteId,
  }) async {
    final response = await _post('transferencias/delete_pack', {
      'id_transferencia': pedidoId,
      'id_paquete': paqueteId,
    });
    final r = result(decode(response));
    final data = r['result'];
    return MovesDevueltosApi(
      mensaje: OdooParse.str(r['mensaje'] ?? r['msg']).isEmpty
          ? 'Paquete eliminado correctamente'
          : OdooParse.str(r['mensaje'] ?? r['msg']),
      moves: data is Map ? OdooParse.maps(data['items']) : const [],
      paqueteEliminado: true,
    );
  }

  @override
  Future<String> asignarUbicacion({
    required int pedidoId,
    required List<int> paqueteIds,
    required int ubicacionId,
  }) async {
    final response = await _post('cluster/packing/ubicacion', {
      'movimientos': [
        for (final id in paqueteIds)
          {
            'id_transferencia': pedidoId,
            'id_paquete': id,
            'id_ubicacion_destino': ubicacionId,
          },
      ],
    });
    final r = result(decode(response));
    final msg = OdooParse.str(r['msg']);
    return msg.isEmpty ? 'Ubicación asignada correctamente' : msg;
  }

  @override
  Future<String> validarPedido({
    required int pedidoId,
    required bool crearBackorder,
    required bool aceptarVencidos,
  }) async {
    final response = await _post(
      aceptarVencidos ? 'complete_transfer/expire' : 'complete_transfer',
      {'id_transferencia': pedidoId, 'crear_backorder': crearBackorder},
    );
    try {
      final r = result(decode(response));
      return OdooParse.str(r['msg']);
    } on ServerException catch (e) {
      if (e.message.contains('expiry.picking.confirmation')) {
        throw VencidosException(e.message);
      }
      rethrow;
    }
  }

  @override
  Future<TemperaturaIa> leerTemperatura(String imagePath) async {
    final response = await _api.postMultipartImage(
      endpoint: 'extract-temp-humidity',
      imageFile: File(imagePath),
      isLoadinDialog: false,
    );
    final json = decode(response);
    final temp = json['temperature'];
    if (temp is! num) {
      final detail = OdooParse.str(json['detail']);
      throw ServerException(
        detail.isEmpty ? 'No se pudo leer la temperatura' : detail,
      );
    }
    return TemperaturaIa(
      temperature: temp.toDouble(),
      unit: OdooParse.str(json['unit']),
      confidence: OdooParse.str(json['confidence']),
    );
  }

  @override
  Future<String> enviarTemperatura({
    required int idMove,
    required double temperatura,
    String? imagePath,
  }) async {
    final response = imagePath == null
        ? await _api.postMultipartManual(
            endpoint: 'send_image_linea_recepcion/batch',
            idMoveLine: idMove,
            temperature: temperatura,
            isLoadinDialog: false,
          )
        : await _api.postMultipart(
            endpoint: 'send_image_linea_recepcion/batch',
            imageFile: File(imagePath),
            idMoveLine: idMove,
            temperature: temperatura,
            isLoadinDialog: false,
          );
    return OdooParse.str(plano(response)['image_url']);
  }

  @override
  Future<String> enviarImagenNovedad({
    required int idMove,
    required String imagePath,
  }) async {
    final response = await _api.postMultipartDynamic(
      endpoint: 'send_imagen_observation/batch',
      imageFile: File(imagePath),
      fields: {'move_line_id': idMove},
    );
    return OdooParse.str(plano(response)['image_url']);
  }
}
