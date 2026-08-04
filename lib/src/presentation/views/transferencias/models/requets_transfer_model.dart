class TransferRequest {
  final int idTransferencia;
  final List<ListItem> listItems;

  TransferRequest({
    required this.idTransferencia,
    required this.listItems,
  });

  Map<String, dynamic> toMap() {
    return {
      "id_transferencia": idTransferencia,
      "list_items": listItems.map((item) => item.toMap()).toList(),
    };
  }
}

class ListItem {
  final int idMove;
  final int idProducto;
  final int idLote;
  final int? idUbicacionOrigen;
  final int idUbicacionDestino;
  final dynamic cantidadEnviada;
  final int idOperario;
  final dynamic timeLine;
  final String fechaTransaccion;
  final String observacion;
  final bool dividida;
  final double quantitySegundaUnidad;

  ListItem({
    required this.idMove,
    required this.idProducto,
    required this.idLote,
    this.idUbicacionOrigen,
    required this.idUbicacionDestino,
    required this.cantidadEnviada,
    required this.idOperario,
    required this.timeLine,
    required this.fechaTransaccion,
    required this.observacion,
    required this.dividida,
    this.quantitySegundaUnidad = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      "id_move": idMove,
      "id_producto": idProducto,
      "id_lote": idLote,
      "id_ubicacion_origen": idUbicacionOrigen,
      "id_ubicacion_destino": idUbicacionDestino,
      // Nunca enviar null: Odoo hace float() sobre este campo y float(None)
      // revienta con "Error interno: float() argument must be a String or a
      // real number, not None type". Coaccionamos a número como última red.
      "cantidad_enviada": cantidadEnviada is num
          ? cantidadEnviada
          : (num.tryParse('$cantidadEnviada'.replaceAll(',', '.')) ?? 0),
      "id_operario": idOperario,
      "time_line": timeLine,
      "fecha_transaccion": fechaTransaccion,
      "observacion": observacion,
      "dividida": dividida,
      "quantity_segunda_unidad": quantitySegundaUnidad,
    };
  }
}
