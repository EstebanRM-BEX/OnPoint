class RequestSendDevolucionModel {
  final int idAlmacen;
  final int idProveedor;
  final int idPropietario;
  final int idUbicacionDestino;
  final int idResponsable;
  final String fechaInicio;
  final String fechaFin;
  final List<ProductRequest> listItems;

  RequestSendDevolucionModel({
    required this.idAlmacen,
    required this.idProveedor,
    required this.idPropietario,
    required this.idUbicacionDestino,
    required this.idResponsable,
    required this.fechaInicio,
    required this.fechaFin,
    required this.listItems,
  });
  Map<String, dynamic> toJson() {
    return {
      'idAlmacen': idAlmacen,
      'idProveedor': idProveedor,
      'id_propietario': idPropietario,
      'idUbicacionDestino': idUbicacionDestino,
      'idResponsable': idResponsable,
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
      'listItems': listItems.map((item) => item.toJson()).toList(),
    };
  }

  factory RequestSendDevolucionModel.fromJson(Map<String, dynamic> json) {
    return RequestSendDevolucionModel(
      idAlmacen: json['idAlmacen'],
      idProveedor: json['idProveedor'],
      idPropietario: json['id_propietario'],
      idUbicacionDestino: json['idUbicacionDestino'],
      idResponsable: json['idResponsable'],
      fechaInicio: json['fechaInicio'],
      fechaFin: json['fechaFin'],
      listItems: (json['listItems'] as List)
          .map((item) => ProductRequest.fromJson(item))
          .toList(),
    );
  }
}

class ProductRequest {
  //

  final int idProducto;
  final dynamic idLote;
  final int ubicacionDestino;
  final dynamic cantidadEnviada;
  final int idOperario;
  final int timeLine;
  final String fechaTransaccion;
  final String observacion;
  final double quantitySegundaUnidad;

  ProductRequest({
    required this.idProducto,
    required this.idLote,
    required this.ubicacionDestino,
    required this.cantidadEnviada,
    required this.idOperario,
    required this.timeLine,
    required this.fechaTransaccion,
    required this.observacion,
    this.quantitySegundaUnidad = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_producto': idProducto,
      'id_lote': idLote,
      'ubicacion_destino': ubicacionDestino,
      'cantidad_enviada': cantidadEnviada,
      'id_operario': idOperario,
      'time_line': timeLine,
      'fecha_transaccion': fechaTransaccion,
      'observacion': observacion,
      'quantity_segunda_unidad': quantitySegundaUnidad,
    };
  }

  factory ProductRequest.fromJson(Map<String, dynamic> json) {
    return ProductRequest(
      idProducto: json['id_producto'],
      idLote: json['id_lote'],
      ubicacionDestino: json['ubicacion_destino'],
      cantidadEnviada: json['cantidad_enviada'],
      idOperario: json['id_operario'],
      timeLine: json['time_line'],
      fechaTransaccion: json['fecha_transaccion'],
      observacion: json['observacion'],
      quantitySegundaUnidad: (json['quantity_segunda_unidad'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
