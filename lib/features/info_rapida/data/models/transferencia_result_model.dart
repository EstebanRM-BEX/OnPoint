import 'package:wms_app/features/info_rapida/domain/entities/transfer_results.dart';
import 'package:wms_app/features/packing_pedido/data/models/odoo_parse.dart';

/// Mapeadores de respuesta JSON a resultados tipados de transferencias.
class TransferenciaResultModel {
  const TransferenciaResultModel._();

  /// Parsea la respuesta del endpoint `crear_transferencia` individual.
  static TransferenciaIndividualResult fromIndividualMap(Map<String, dynamic> json) {
    return TransferenciaIndividualResult(
      transferenciaId: OdooParse.integer(json['transferencia_id']),
      nombreTransferencia: OdooParse.str(json['nombre_transferencia']).isEmpty
          ? null
          : OdooParse.str(json['nombre_transferencia']),
      lineaId: OdooParse.integer(json['linea_id']),
      cantidadEnviada: json['cantidad_enviada'] != null
          ? OdooParse.dbl(json['cantidad_enviada'])
          : null,
      idProducto: OdooParse.integer(json['id_producto']),
      nombreProducto: OdooParse.str(json['nombre_producto']).isEmpty
          ? null
          : OdooParse.str(json['nombre_producto']),
      ubicacionOrigen: OdooParse.str(json['ubicacion_origen']).isEmpty
          ? null
          : OdooParse.str(json['ubicacion_origen']),
      ubicacionDestino: OdooParse.str(json['ubicacion_destino']).isEmpty
          ? null
          : OdooParse.str(json['ubicacion_destino']),
      fechaTransaccion: OdooParse.str(json['fecha_transaccion']).isEmpty
          ? null
          : OdooParse.str(json['fecha_transaccion']),
      observacion: OdooParse.str(json['observacion']).isEmpty
          ? null
          : OdooParse.str(json['observacion']),
    );
  }

  /// Parsea la respuesta del endpoint `transferencias/create_trasferencia` masivo.
  static TransferenciaMasivaResult fromMasivaMap(Map<String, dynamic> json) {
    final rawItems = json['items_procesados'];
    final items = <ItemTransferido>[];

    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          final itemMap = Map<String, dynamic>.from(item);
          items.add(
            ItemTransferido(
              lineaId: OdooParse.integer(itemMap['linea_id']),
              productoId: OdooParse.integer(itemMap['producto_id']),
              productoNombre: OdooParse.str(itemMap['producto_nombre']).isEmpty
                  ? null
                  : OdooParse.str(itemMap['producto_nombre']),
              cantidad: itemMap['cantidad'] != null
                  ? OdooParse.dbl(itemMap['cantidad'])
                  : null,
              loteId: OdooParse.integer(itemMap['lote_id']),
              observacion: OdooParse.str(itemMap['observacion']).isEmpty
                  ? null
                  : OdooParse.str(itemMap['observacion']),
            ),
          );
        }
      }
    }

    return TransferenciaMasivaResult(
      transferenciaId: OdooParse.integer(json['transferencia_id']),
      nombreTransferencia: OdooParse.str(json['nombre_transferencia']).isEmpty
          ? null
          : OdooParse.str(json['nombre_transferencia']),
      totalItems: OdooParse.integer(json['total_items']),
      ubicacionOrigenId: OdooParse.integer(json['ubicacion_origen_id']),
      ubicacionDestinoId: OdooParse.integer(json['ubicacion_destino_id']),
      itemsProcesados: List.unmodifiable(items),
    );
  }
}
