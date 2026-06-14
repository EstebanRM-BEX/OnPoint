import 'dart:convert';

// Clase para la petición principal
class CreateTransferRequest {
  final String dateStart;
  final String dateEnd;
  final int idAlmacen;
  final int idUbicacionOrigen;
  final int idUbicacionDestino;
  final int idOperario;
  final String fechaTransaccion;
  final List<ListItem> listItems;

  CreateTransferRequest({
    required this.dateStart,
    required this.dateEnd,
    required this.idAlmacen,
    required this.idUbicacionOrigen,
    required this.idUbicacionDestino,
    required this.idOperario,
    required this.fechaTransaccion,
    required this.listItems,
  });

  // Método para convertir el objeto a un Map (estructura JSON)
  Map<String, dynamic> toMap() => {
        "date_start": dateStart,
        "date_end": dateEnd,
        "id_almacen": idAlmacen,
        "id_ubicacion_origen": idUbicacionOrigen,
        "id_ubicacion_destino": idUbicacionDestino,
        "id_operario": idOperario,
        "fecha_transaccion": fechaTransaccion,
        "list_items": List<dynamic>.from(listItems.map((x) => x.toMap())),
      };

  // Método de ayuda para serializar el objeto a una cadena JSON
  String toJson() => json.encode(toMap());
}

// Clase para los ítems individuales dentro de la lista
class ListItem {
  final int idProducto;
  final double cantidadEnviada;
  final int idLote;
  final int timeLine;
  final int idPropietario;

  ListItem({
    required this.idProducto,
    required this.cantidadEnviada,
    required this.idLote,
    required this.timeLine,
    required this.idPropietario,
  });

  // Método para convertir el objeto a un Map (estructura JSON)
  Map<String, dynamic> toMap() => {
        "id_producto": idProducto,
        "cantidad_enviada": cantidadEnviada,
        "id_lote": idLote,
        "time_line": timeLine,
        "id_propietario" : idPropietario,
      };
}
