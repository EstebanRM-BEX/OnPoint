class PackingPackRequest {
  final int idTransferencia;
  final bool isSticker;
  final bool isCertificate;
  final double pesoCaja;
  final double pesoTotalPaquete;
  final int tipoEmpaque;
  final List<ListItemPack> listItems;

  PackingPackRequest({
    required this.idTransferencia,
    required this.isSticker,
    required this.isCertificate,
    required this.pesoCaja,
    required this.pesoTotalPaquete,
    required this.tipoEmpaque,
    required this.listItems,
  });

  Map<String, dynamic> toMap() {
    return {
      "id_transferencia": idTransferencia,
      "is_sticker": isSticker,
      "is_certificate": isCertificate,
      "tipo_paquete": tipoEmpaque,
      "peso_caja": pesoCaja,
      "peso_total_paquete": pesoTotalPaquete,
      "list_items": listItems.map((item) => item.toMap()).toList(),
    };
  }
}

class ListItemPack {
  final int idMove;
  final int idProducto;
  final dynamic cantidadEnviada;
  final int idUbicacionOrigen;
  final int idUbicacionDestino;
  final int idLote;
  final int idOperario;
  final String fechaTransaccion;
  final dynamic timeLine;
  final String observacion;

  ListItemPack({
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

  Map<String, dynamic> toMap() {
    return {
      "id_move": idMove,
      "id_producto": idProducto,
      "cantidad_enviada": cantidadEnviada,
      "id_ubicacion_origen": idUbicacionOrigen,
      "id_ubicacion_destino": idUbicacionDestino,
      "id_lote": idLote,
      "id_operario": idOperario,
      "fecha_transaccion": fechaTransaccion,
      "time_line": timeLine,
      "observacion": observacion,
    };
  }
}
