import 'dart:convert';

class ResponseDevolucion {
  final String? jsonrpc;
  final dynamic id;
  final ResultDevolucion? result;

  ResponseDevolucion({this.jsonrpc, this.id, this.result});

  factory ResponseDevolucion.fromJson(String str) =>
      ResponseDevolucion.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ResponseDevolucion.fromMap(Map<String, dynamic> json) =>
      ResponseDevolucion(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null
            ? null
            : ResultDevolucion.fromMap(json["result"]),
      );

  Map<String, dynamic> toMap() => {
    "jsonrpc": jsonrpc,
    "id": id,
    "result": result?.toMap(),
  };
}

class ResultDevolucion {
  final int? code;
  final String? msg;
  final int? devolucionId;
  final String? nombreDevolucion;
  final String? estado;
  final DateTime? fechaCreacion;
  final int? almacenId;
  final String? almacenNombre;
  final int? ubicacionDestinoId;
  final String? ubicacionDestinoNombre;
  final int? responsableId;
  final int? proveedorId;
  final String? propietarioNombre;
  final String? proveedorNombre;
  final dynamic totalItems;
  final dynamic totalItemsOriginales;
  final List<ItemsProcesado>? itemsProcesados;

  ResultDevolucion({
    this.code,
    this.msg,
    this.devolucionId,
    this.nombreDevolucion,
    this.estado,
    this.fechaCreacion,
    this.propietarioNombre,
    this.almacenNombre,
    this.almacenId,
    this.ubicacionDestinoId,
    this.ubicacionDestinoNombre,
    this.responsableId,
    this.proveedorId,
    this.proveedorNombre,
    this.totalItems,
    this.totalItemsOriginales,
    this.itemsProcesados,
  });

  factory ResultDevolucion.fromJson(String str) =>
      ResultDevolucion.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ResultDevolucion.fromMap(Map<String, dynamic> json) =>
      ResultDevolucion(
        code: json["code"],
        msg: json["msg"],
        devolucionId: json["devolucion_id"],
        nombreDevolucion: json["nombre_devolucion"],
        estado: json["estado"],
        fechaCreacion: json["fecha_creacion"] == null
            ? null
            : DateTime.parse(json["fecha_creacion"]),
        almacenId: json["almacen_id"],
        almacenNombre: json["almacen_nombre"],
        propietarioNombre: json["propietario_nombre"],
        ubicacionDestinoId: json["ubicacion_destino_id"],
        ubicacionDestinoNombre: json["ubicacion_destino_nombre"],
        responsableId: json["responsable_id"],
        proveedorId: json["proveedor_id"],
        proveedorNombre: json["proveedor_nombre"],
        totalItems: json["total_items"],
        totalItemsOriginales: json["total_items_originales"],
        itemsProcesados: json["items_procesados"] == null
            ? []
            : List<ItemsProcesado>.from(
                json["items_procesados"]!.map((x) => ItemsProcesado.fromMap(x)),
              ),
      );

  Map<String, dynamic> toMap() => {
    "code": code,
    "msg": msg,
    "devolucion_id": devolucionId,
    "nombre_devolucion": nombreDevolucion,
    "estado": estado,
    "fecha_creacion": fechaCreacion?.toIso8601String(),
    "almacen_id": almacenId,
    "ubicacion_destino_id": ubicacionDestinoId,
    "ubicacion_destino_nombre": ubicacionDestinoNombre,
    "responsable_id": responsableId,
    "proveedor_id": proveedorId,
    "proveedor_nombre": proveedorNombre,
    "propietario_nombre": propietarioNombre,
    "almacen_nombre": almacenNombre,
    "total_items": totalItems,
    "total_items_originales": totalItemsOriginales,
    "items_procesados": itemsProcesados == null
        ? []
        : List<dynamic>.from(itemsProcesados!.map((x) => x.toMap())),
  };
}

class ItemsProcesado {
  final int? idProducto;
  final String? nombreProducto;
  final dynamic cantidadTotal;
  final dynamic cantidadItemsOriginales;
  final int? moveId;
  final dynamic lote;
  final String? loteNombre;
  final String? observacion;
  final String? claveUnica;
  final int? moveLineId;

  ItemsProcesado({
    this.idProducto,
    this.nombreProducto,
    this.cantidadTotal,
    this.cantidadItemsOriginales,
    this.moveId,
    this.lote,
    this.loteNombre,
    this.observacion,
    this.claveUnica,
    this.moveLineId,
  });

  factory ItemsProcesado.fromJson(String str) =>
      ItemsProcesado.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ItemsProcesado.fromMap(Map<String, dynamic> json) => ItemsProcesado(
    idProducto: json["id_producto"],
    nombreProducto: json["nombre_producto"],
    cantidadTotal: json["cantidad_total"],
    cantidadItemsOriginales: json["cantidad_items_originales"],
    moveId: json["move_id"],
    lote: json["lote"],
    loteNombre: json["lote_nombre"],
    observacion: json["observacion"],
    claveUnica: json["clave_unica"],
    moveLineId: json["move_line_id"],
  );

  Map<String, dynamic> toMap() => {
    "id_producto": idProducto,
    "nombre_producto": nombreProducto,
    "cantidad_total": cantidadTotal,
    "cantidad_items_originales": cantidadItemsOriginales,
    "move_id": moveId,
    "lote": lote,
    "lote_nombre": loteNombre,
    "observacion": observacion,
    "clave_unica": claveUnica,
    "move_line_id": moveLineId,
  };
}
