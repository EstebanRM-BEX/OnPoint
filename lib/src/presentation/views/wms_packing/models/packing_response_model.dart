import 'dart:convert';

import 'package:wms_app/src/presentation/views/wms_packing/models/lista_product_packing.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';

class PackingModelResponse {
  final String? jsonrpc;
  final dynamic id;
  final PackingModelResponseResult? result;

  PackingModelResponse({
    this.jsonrpc,
    this.id,
    this.result,
  });

  factory PackingModelResponse.fromJson(String str) =>
      PackingModelResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PackingModelResponse.fromMap(Map<String, dynamic> json) =>
      PackingModelResponse(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null
            ? null
            : PackingModelResponseResult.fromMap(json["result"]),
      );

  Map<String, dynamic> toMap() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "result": result?.toMap(),
      };
}

class PackingModelResponseResult {
  final int? code;
  final String? msg;
  final bool? updateVersion;
  final List<BatchPackingModel>? result;

  PackingModelResponseResult({
    this.code,
    this.result,
    this.msg,
    this.updateVersion,
  });

  factory PackingModelResponseResult.fromJson(String str) =>
      PackingModelResponseResult.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PackingModelResponseResult.fromMap(Map<String, dynamic> json) =>
      PackingModelResponseResult(
        code: json["code"],
        msg: json["msg"],
        updateVersion: json["update_version"],
        result: json["result"] == null
            ? []
            : List<BatchPackingModel>.from(
                json["result"]!.map((x) => BatchPackingModel.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
        "code": code,
        "msg": msg,
        "update_version": updateVersion,
        "result": result == null
            ? []
            : List<dynamic>.from(result!.map((x) => x.toMap())),
      };
}

class BatchPackingModel {
  final int? id;
  final String? name;
  final dynamic scheduleddate;
  final dynamic pickingTypeId;
  final String? state;
  final dynamic userId;
  final List<PedidoPacking>? listaPedidos;
  final int? cantidadPedidos;

  final int? isSeparate;
  final dynamic isSelected;
  final dynamic isPacking;
  final String? userName;

  final int? pedidoSeparateQty; //cantidad que se lleva separada

  final double? timeSeparateTotal;
  final String? timeSeparateStart;
  final String? timeSeparateEnd;
  final String? zonaEntrega;
  final String? zonaEntregaTms;
  final dynamic startTimePack;
  final dynamic endTimePack;
  final List<Origin>? origin;
  final String? origins;
  // cantidad_total_pedidos
  // cantidad_total_productos
  final dynamic cantidadTotalPedidos;
  final dynamic cantidadTotalProductos;
  //unidades_productos
  final dynamic unidadesProductos;

  dynamic manejaTemperatura;
  dynamic temperatura;

  BatchPackingModel({
    this.id,
    this.name,
    this.scheduleddate,
    this.cantidadPedidos,
    this.state,
    this.userId,
    this.userName,
    this.pickingTypeId,
    this.listaPedidos,
    this.isSeparate,
    this.isSelected,
    this.isPacking,
    this.pedidoSeparateQty,
    this.timeSeparateTotal,
    this.timeSeparateStart,
    this.timeSeparateEnd,
    this.zonaEntrega,
    this.zonaEntregaTms,
    this.startTimePack,
    this.endTimePack,
    this.manejaTemperatura,
    this.temperatura,
    this.origin,
    this.origins,
    this.cantidadTotalPedidos,
    this.cantidadTotalProductos,
    this.unidadesProductos,
  });

  factory BatchPackingModel.fromJson(String str) =>
      BatchPackingModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory BatchPackingModel.fromMap(Map<String, dynamic> json) =>
      BatchPackingModel(
        id: json["id"],
        name: json["name"],
        scheduleddate: json["scheduleddate"],
        cantidadPedidos: json["cantidad_pedidos"],
        userName: json['user_name'],
        state: json["state"],
        userId: json["user_id"],
        pickingTypeId: json["picking_type_id"],
        listaPedidos: json["lista_pedidos"] == null
            ? []
            : List<PedidoPacking>.from(
                json["lista_pedidos"]!.map((x) => PedidoPacking.fromMap(x))),
        isSeparate: json["is_separate"],
        isSelected: json["is_selected"],
        pedidoSeparateQty: json["pedido_separate_qty"],
        timeSeparateTotal: json["time_separate_total"],
        timeSeparateStart: json["time_separate_start"],
        timeSeparateEnd: json["time_separate_end"],
        zonaEntrega: json["zona_entrega"],
        zonaEntregaTms: json["zona_entrega_tms"],
        startTimePack: json["start_time_pack"],
        endTimePack: json["end_time_pack"],
        manejaTemperatura: json["maneja_temperatura"],
        temperatura: json["temperatura"],
        origins: json["origins"],
        cantidadTotalPedidos: json["cantidad_total_pedidos"],
        cantidadTotalProductos: json["cantidad_total_productos"],
        unidadesProductos: json["unidades_productos"],
        origin: json["origin"] == null
            ? []
            : List<Origin>.from(json["origin"]!.map((x) => Origin.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "scheduleddate": scheduleddate,
        "cantidad_pedidos": cantidadPedidos,
        "state": state,
        "user_id": userId,
        "picking_type_id": pickingTypeId,
        "lista_pedidos": listaPedidos == null
            ? []
            : List<dynamic>.from(listaPedidos!.map((x) => x.toMap())),
        "is_separate": isSeparate,
        "is_selected": isSelected,
        "pedido_separate_qty": pedidoSeparateQty,
        "time_separate_total": timeSeparateTotal,
        "time_separate_start": timeSeparateStart,
        "time_separate_end": timeSeparateEnd,
        "zona_entrega": zonaEntrega,
        "zona_entrega_tms": zonaEntregaTms,
        'start_time_pack': startTimePack,
        'end_time_pack': endTimePack,
        "maneja_temperatura": manejaTemperatura,
        "temperatura": temperatura,
        "origins": origins,
        "cantidad_total_pedidos": cantidadTotalPedidos,
        "cantidad_total_productos": cantidadTotalProductos,
        "unidades_productos": unidadesProductos,
        "origin": origin == null
            ? []
            : List<dynamic>.from(origin!.map((x) => x.toMap())),
      };
}

class PedidoPacking {
  final int? id;
  final int? batchId;
  final String? name;
  final dynamic referencia;
  final DateTime? fecha;
  final int? isSelected;
  final int? isPacking;
  final dynamic contacto;
  final String? tipoOperacion;
  final String? contactoName;
  final dynamic isTerminate;
  final dynamic? cantidadProductos;
  final int? numeroPaquetes;
  final List<ProductoPedido>? listaProductos;
  final List<Paquete>? listaPaquetes;
  final String? zonaEntrega;
  final String? zonaEntregaTms;
  final String? orderTms;
  final String? type;
  final String? pedidos;

  PedidoPacking({
    this.id,
    this.isSelected,
    this.isPacking,
    this.batchId,
    this.name,
    this.referencia,
    this.fecha,
    this.contacto,
    this.tipoOperacion,
    this.cantidadProductos,
    this.numeroPaquetes,
    this.listaProductos,
    this.listaPaquetes,
    this.isTerminate,
    this.contactoName,
    this.zonaEntrega,
    this.zonaEntregaTms,
    this.orderTms,
    this.type,
    this.pedidos,
  });

  factory PedidoPacking.fromJson(String str) =>
      PedidoPacking.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PedidoPacking.fromMap(Map<String, dynamic> json) => PedidoPacking(
        id: json["id"],
        isSelected: json["is_selected"],
        batchId: json["batch_id"],
        name: json["name"],
        referencia: json["referencia"],
        fecha: json["fecha"] == null
            ? DateTime.now()
            : DateTime.parse(json["fecha"]),
        contacto: json["contacto"],
        contactoName: json["contacto_name"],
        tipoOperacion: json["tipo_operacion"],
        cantidadProductos: json["cantidad_productos"],
        numeroPaquetes: json["numero paquetes"],
        listaProductos: json["lista_productos"] == null
            ? []
            : List<ProductoPedido>.from(
                json["lista_productos"]!.map((x) => ProductoPedido.fromMap(x))),
        listaPaquetes: json["lista_paquetes"] == null
            ? []
            : List<Paquete>.from(
                json["lista_paquetes"]!.map((x) => Paquete.fromMap(x))),
        isTerminate: json["is_terminate"],
        zonaEntrega: json["zona_entrega"],
        zonaEntregaTms: json["zona_entrega_tms"],
        orderTms: json["order_tms"],
        type: json["type"],
        pedidos: json["pedidos"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "is_selected": isSelected,
        "batch_id": batchId,
        "name": name,
        "referencia": referencia,
        "fecha": fecha?.toIso8601String(),
        "contacto": contacto,
        "contacto_name": contactoName,
        "tipo_operacion": tipoOperacion,
        "cantidad_productos": cantidadProductos,
        "numero paquetes": numeroPaquetes,
        "lista_productos": listaProductos == null
            ? []
            : List<dynamic>.from(listaProductos!.map((x) => x.toMap())),
        "lista_paquetes": listaPaquetes == null
            ? []
            : List<dynamic>.from(listaPaquetes!.map((x) => x.toMap())),
        "is_terminate": isTerminate,
        "zona_entrega": zonaEntrega,
        "zona_entrega_tms": zonaEntrega,
        "order_tms": orderTms,
        "type": type,
        "pedidos": pedidos,
      };
}

class Paquete {
  final int? id;
  final String? name;
  final int? batchId;
  final int? pedidoId;
  final dynamic cantidadProductos;
  //packing_barcode
  final String? packingBarcode;
  final int? locationDestId;
  final String? locationDestName;
  final String? locationDestBarcode;
  final List<ProductoPedido>? listaProductosInPacking;
  final bool? isSticker;
  final bool? isCertificate;
  final String? type;
  final dynamic consecutivo;
  final String? typePaquete;
  final dynamic peso;

  Paquete({
    this.id,
    this.name,
    this.packingBarcode,
    this.locationDestId,
    this.locationDestName,
    this.locationDestBarcode,
    this.batchId,
    this.pedidoId,
    this.cantidadProductos,
    this.listaProductosInPacking,
    this.isSticker,
    this.isCertificate,
    this.type,
    this.consecutivo,
    this.typePaquete,
    this.peso,
  });

  factory Paquete.fromJson(String str) => Paquete.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Paquete.fromMap(Map<String, dynamic> json) => Paquete(
        id: json["id"],
        name: json["name"],
        batchId: json["batch_id"],
        packingBarcode: json["packing_barcode"],
        locationDestId: json["location_dest_id"],
        locationDestName: json["location_dest_name"],
        locationDestBarcode: json["location_dest_barcode"],
        pedidoId: json["pedido_id"],
        cantidadProductos: json["cantidad_productos"],
        listaProductosInPacking: json["lista_productos_in_packing"] == null
            ? []
            : List<ProductoPedido>.from(json["lista_productos_in_packing"]!
                .map((x) => ProductoPedido.fromMap(x))),
        isSticker: json["is_sticker"],
        isCertificate: json["is_certificate"],
        type: json["type"],
        consecutivo: json["consecutivo"],
        typePaquete: json["type_paquete"],
        peso: json["peso"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "batch_id": batchId,
        "packing_barcode": packingBarcode,
        "location_dest_id": locationDestId,
        "location_dest_name": locationDestName,
        "location_dest_barcode": locationDestBarcode,
        "pedido_id": pedidoId,
        "cantidad_productos": cantidadProductos,
        "lista_productos_in_packing": listaProductosInPacking == null
            ? []
            : List<dynamic>.from(
                listaProductosInPacking!.map((x) => x.toMap())),
        "is_sticker": isSticker,
        "is_certificate": isCertificate,
        "type": type,
        "consecutivo": consecutivo,
        "type_paquete": typePaquete,
        "peso": peso,
      };

  Paquete copyWith({
    int? id,
    String? name,
    int? batchId,
    int? pedidoId,
    dynamic? cantidadProductos,
    String? packingBarcode,
    int? locationDestId,
    String? locationDestName,
    String? locationDestBarcode,
    List<ProductoPedido>? listaProductosInPacking,
    bool? isSticker,
    bool? isCertificate,
    String? type,
    dynamic? consecutivo,
    String? typePaquete,
    dynamic? peso,
  }) {
    return Paquete(
      id: id ?? this.id,
      name: name ?? this.name,
      batchId: batchId ?? this.batchId,
      pedidoId: pedidoId ?? this.pedidoId,
      cantidadProductos: cantidadProductos ?? this.cantidadProductos,
      packingBarcode: packingBarcode ?? this.packingBarcode,
      locationDestId: locationDestId ?? this.locationDestId,
      locationDestName: locationDestName ?? this.locationDestName,
      locationDestBarcode: locationDestBarcode ?? this.locationDestBarcode,
      listaProductosInPacking:
          listaProductosInPacking ?? this.listaProductosInPacking,
      isSticker: isSticker ?? this.isSticker,
      isCertificate: isCertificate ?? this.isCertificate,
      type: type ?? this.type,
      consecutivo: consecutivo ?? this.consecutivo,
      typePaquete: typePaquete ?? this.typePaquete,
      peso: peso ?? this.peso,
    );
  }
}
