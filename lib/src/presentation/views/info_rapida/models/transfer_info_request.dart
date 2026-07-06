class TransferInfoRequest {
  final int idAlmacen;
  final int idMove;
  final int idProducto;
  final int idLote;
  final int idUbicacionOrigen;
  final int? idUbicacionDestino;
  final dynamic cantidadEnviada;
  final int? idOperario;
  final int? timeLine;
  final String? fechaTransaccion;
  final String observacion;
  final int? idPropietario;

  //tiempo de incio de la transferencia
  final String? dateStart;
  final String? dateEnd;

  TransferInfoRequest({
    required this.idAlmacen,
    required this.idMove,
    required this.idProducto,
    required this.idLote,
    required this.idUbicacionOrigen,
    this.idUbicacionDestino,
    this.cantidadEnviada,
    this.idOperario,
    this.timeLine,
    this.fechaTransaccion,
    required this.observacion,
    this.dateStart,
    this.dateEnd,
    this.idPropietario,
  });

  Map<String, dynamic> toMap() {
    return {
      "id_almacen": idAlmacen,
      "id_move": idMove,
      "id_producto": idProducto,
      "id_lote": idLote,
      "id_ubicacion_origen": idUbicacionOrigen,
      "id_ubicacion_destino": idUbicacionDestino,
      "cantidad_enviada": cantidadEnviada,
      "id_operario": idOperario,
      "time_line": timeLine,
      "fecha_transaccion": fechaTransaccion,
      "observacion": observacion,
      "date_start": dateStart,
      "date_end": dateEnd,
      "id_propietario" : idPropietario,
    };
  }
}
