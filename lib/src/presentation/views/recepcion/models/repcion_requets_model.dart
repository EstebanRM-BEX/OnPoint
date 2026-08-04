class RecepcionRequest {
  final int idRecepcion;
  final List<ListItem> listItems;

  RecepcionRequest({
    required this.idRecepcion,
    required this.listItems,
  });

  Map<String, dynamic> toMap() {
    return {
      "id_recepcion": idRecepcion,
      "list_items": listItems.map((item) => item.toMap()).toList(),
    };
  }
}

class ListItem {
  final int idProducto;
  final int idMove;
  final int loteProducto;

  final int ubicacionDestino;
  final dynamic cantidadSeparada;
  final String observacion;
  final int idOperario;
  final String fechaTransaccion;
  final int timeLine;
  final double quantitySegundaUnidad;

  ListItem({
    required this.idProducto,
    required this.idMove,
    required this.loteProducto,
    required this.ubicacionDestino,
    required this.cantidadSeparada,
    required this.observacion,
    required this.idOperario,
    required this.fechaTransaccion,
    required this.timeLine,
    this.quantitySegundaUnidad = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      "id_producto": idProducto,
      "id_move": idMove,
      "lote_producto": loteProducto,
      "ubicacion_destino": ubicacionDestino,
      // Nunca enviar null: Odoo hace float() sobre este campo y float(None)
      // revienta con "Error interno: float() argument must be a String or a
      // real number, not None type". Coaccionamos a número como última red.
      "cantidad_separada": cantidadSeparada is num
          ? cantidadSeparada
          : (num.tryParse('$cantidadSeparada'.replaceAll(',', '.')) ?? 0),
      "id_operario": idOperario,
      "fecha_transaccion": fechaTransaccion,
      "observacion": observacion,
      "time_line": timeLine,
      "quantity_segunda_unidad": quantitySegundaUnidad,
    };
  }
}
