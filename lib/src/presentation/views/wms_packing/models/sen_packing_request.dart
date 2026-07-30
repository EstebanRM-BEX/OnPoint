class PackingRequest {
  final int idBatch;
  final bool isSticker;
  final bool isCertificate;
  final double pesoCaja;
  final double pesoTotalPaquete;
  final int tipoEmpaque;
  final List<ListItem> listItem;

  PackingRequest({
    required this.idBatch,
    required this.isSticker,
    required this.isCertificate,
    required this.pesoCaja,
    required this.pesoTotalPaquete,
    required this.tipoEmpaque,
    required this.listItem,
  });

  Map<String, dynamic> toMap() {
    return {
      "id_batch": idBatch,
      "is_sticker": isSticker,
      "is_certificate": isCertificate,
      "peso_total_paquete": pesoTotalPaquete,
      "tipo_paquete": tipoEmpaque,
      "peso_caja": pesoCaja,
      "list_item": listItem.map((item) => item.toMap()).toList(),
    };
  }
}

class ListItem {
  final int idMove;
  final int productId;
  final int locationId;
  final String lote;
  final dynamic cantidadSeparada;
  final String observacion;
  final String unidadMedida;
  final int idOperario;
  final String fechaTransaccion;
  final dynamic timeLine;
  final bool dividir;

  ListItem({
    required this.idMove,
    required this.productId,
    required this.lote,
    required this.locationId,
    required this.cantidadSeparada,
    required this.observacion,
    required this.unidadMedida,
    required this.idOperario,
    required this.fechaTransaccion,
    required this.timeLine,
    this.dividir = false,
  });

  Map<String, dynamic> toMap() {
    return {
      "id_move": idMove,
      "product_id": productId,
      "lote": lote,
      "location_id": locationId,
      "cantidad_separada": cantidadSeparada,
      "observacion": observacion,
      "unidad_medida": unidadMedida,
      "id_operario": idOperario,
      "fecha_transaccion": fechaTransaccion,
      "time_line": timeLine,
      "dividir": dividir,
    };
  }
}
