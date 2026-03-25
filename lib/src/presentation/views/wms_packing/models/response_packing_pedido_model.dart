import 'dart:convert';

import 'package:wms_app/src/presentation/views/wms_packing/models/lista_product_packing.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/packing_response_model.dart';

class PackingPedido {
  final String? jsonrpc;
  final dynamic id;
  final PackingPedidoResult? result;

  PackingPedido({
    this.jsonrpc,
    this.id,
    this.result,
  });

  factory PackingPedido.fromJson(String str) =>
      PackingPedido.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PackingPedido.fromMap(Map<String, dynamic> json) => PackingPedido(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null
            ? null
            : PackingPedidoResult.fromMap(json["result"]),
      );

  Map<String, dynamic> toMap() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "result": result?.toMap(),
      };
}

class PackingPedidoResult {
  final int? code;
  final String? msg;
  final bool? updateVersion;
  final List<PedidoPackingResult>? result;

  PackingPedidoResult({
    this.code,
    this.msg,
    this.updateVersion,
    this.result,
  });

  factory PackingPedidoResult.fromJson(String str) =>
      PackingPedidoResult.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PackingPedidoResult.fromMap(Map<String, dynamic> json) =>
      PackingPedidoResult(
        code: json["code"],
        msg: json["msg"],
        updateVersion: json["update_version"],
        result: json["result"] == null
            ? []
            : List<PedidoPackingResult>.from(
                json["result"]!.map((x) => PedidoPackingResult.fromMap(x))),
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

class PedidoPackingResult {
  final int? batchId;
  final int? id;
  final String? name;
  final String? observacion;
  final dynamic? fechaCreacion;
  final dynamic? configPacking;
  final int? locationId;
  final String? locationName;
  final String? locationNameCluster;
  final String? locationBarcodeCluster;
  final int? locationIdCluster;
  final String? locationBarcode;
  final int? locationDestId;
  final String? locationDestName;
  final String? locationDestBarcode;
  final String? proveedor;
  final String? numeroTransferencia;
  final int? pesoTotal;
  final int? numeroLineas;
  final dynamic numeroItems;
  final String? state;
  final String? referencia;
  final String? contacto;
  final String? contactoName;
  final int? cantidadProductos;
  final int? cantidadProductosTotal;
  final String? priority;
  final int? warehouseId;
  final String? warehouseName;
  final int? responsableId;
  final String? responsable;
  final String? pickingType;
  final String? startTimeTransfer;
  final String? endTimeTransfer;
  final int? backorderId;
  final String? backorderName;
  final dynamic showCheckAvailability;
  final String? orderTms;
  final String? zonaEntregaTms;
  final String? zonaEntrega;
  final int? numeroPaquetes;
  final dynamic isTerminate;
  final dynamic isSelected;
  final dynamic? isStarted;
  final String? createBackorder;

  final List<ProductoPedido>? listaProductos;
  final List<Paquete>? listaPaquetes;

  PedidoPackingResult({
    this.batchId,
    this.id,
    this.name,
    this.observacion,
    this.fechaCreacion,
    this.locationId,
    this.configPacking,
    this.locationName,
    this.locationNameCluster,
    this.locationBarcodeCluster,
    this.locationIdCluster,
    this.locationBarcode,
    this.locationDestId,
    this.locationDestName,
    this.locationDestBarcode,
    this.proveedor,
    this.numeroTransferencia,
    this.pesoTotal,
    this.numeroLineas,
    this.numeroItems,
    this.state,
    this.referencia,
    this.contacto,
    this.contactoName,
    this.cantidadProductos,
    this.cantidadProductosTotal,
    this.priority,
    this.warehouseId,
    this.warehouseName,
    this.responsableId,
    this.responsable,
    this.pickingType,
    this.startTimeTransfer,
    this.endTimeTransfer,
    this.backorderId,
    this.backorderName,
    this.showCheckAvailability,
    this.orderTms,
    this.zonaEntregaTms,
    this.zonaEntrega,
    this.numeroPaquetes,
    this.listaProductos,
    this.listaPaquetes,
    this.isTerminate,
    this.isSelected,
    this.isStarted,
    this.createBackorder,
  });

  factory PedidoPackingResult.fromJson(String str) =>
      PedidoPackingResult.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PedidoPackingResult.fromMap(Map<String, dynamic> json) =>
      PedidoPackingResult(
        batchId: json["batch_id"],
        id: json["id"],
        name: json["name"],
        observacion: json["observacion"],
        configPacking: json["config_packing"],
        fechaCreacion: json["fecha_creacion"] == null
            ? null
            : DateTime.parse(json["fecha_creacion"]),
        locationId: json["location_id"],
        locationName: json["location_name"],
        locationNameCluster: json["location_name_cluster"],
        locationBarcodeCluster: json["location_barcode_cluster"],
        locationIdCluster: json["location_id_cluster"],
        locationBarcode: json["location_barcode"],
        locationDestId: json["location_dest_id"],
        locationDestName: json["location_dest_name"],
        locationDestBarcode: json["location_dest_barcode"],
        proveedor: json["proveedor"],
        numeroTransferencia: json["numero_transferencia"],
        pesoTotal: json["peso_total"],
        numeroLineas: json["numero_lineas"],
        numeroItems: json["numero_items"],
        state: json["state"],
        referencia: json["referencia"],
        contacto: json["contacto"],
        contactoName: json["contacto_name"],
        cantidadProductos: json["cantidad_productos"],
        cantidadProductosTotal: json["cantidad_productos_total"],
        priority: json["priority"],
        warehouseId: json["warehouse_id"],
        warehouseName: json["warehouse_name"],
        responsableId: json["responsable_id"],
        responsable: json["responsable"],
        pickingType: json["picking_type"],
        startTimeTransfer: json["start_time_transfer"],
        endTimeTransfer: json["end_time_transfer"],
        backorderId: json["backorder_id"],
        backorderName: json["backorder_name"],
        showCheckAvailability: json["show_check_availability"],
        orderTms: json["order_tms"],
        zonaEntregaTms: json["zona_entrega_tms"],
        zonaEntrega: json["zona_entrega"],
        numeroPaquetes: json["numero_paquetes"],
        isTerminate: json["is_terminate"],
        isSelected: json["is_selected"],
        isStarted: json["is_started"],
        listaProductos: json["lista_productos"] == null
            ? []
            : List<ProductoPedido>.from(
                json["lista_productos"]!.map((x) => ProductoPedido.fromMap(x))),
        listaPaquetes: json["lista_paquetes"] == null
            ? []
            : List<Paquete>.from(
                json["lista_paquetes"]!.map((x) => Paquete.fromMap(x))),
        createBackorder: json["create_backorder"],
      );

  Map<String, dynamic> toMap() => {
        "batch_id": batchId,
        "id": id,
        "name": name,
        "observacion": observacion,
        "config_packing": configPacking,
        "fecha_creacion": fechaCreacion?.toIso8601String(),
        "location_id": locationId,
        "location_name": locationName,
        "location_name_cluster": locationNameCluster,
        "location_barcode_cluster": locationBarcodeCluster,
        "location_id_cluster": locationIdCluster,
        "location_barcode": locationBarcode,
        "location_dest_id": locationDestId,
        "location_dest_name": locationDestName,
        "location_dest_barcode": locationDestBarcode,
        "proveedor": proveedor,
        "numero_transferencia": numeroTransferencia,
        "peso_total": pesoTotal,
        "numero_lineas": numeroLineas,
        "numero_items": numeroItems,
        "state": state,
        "referencia": referencia,
        "contacto": contacto,
        "contacto_name": contactoName,
        "cantidad_productos": cantidadProductos,
        "cantidad_productos_total": cantidadProductosTotal,
        "priority": priority,
        "warehouse_id": warehouseId,
        "warehouse_name": warehouseName,
        "responsable_id": responsableId,
        "responsable": responsable,
        "picking_type": pickingType,
        "start_time_transfer": startTimeTransfer,
        "end_time_transfer": endTimeTransfer,
        "backorder_id": backorderId,
        "backorder_name": backorderName,
        "show_check_availability": showCheckAvailability,
        "order_tms": orderTms,
        "zona_entrega_tms": zonaEntregaTms,
        "zona_entrega": zonaEntrega,
        "numero_paquetes": numeroPaquetes,
        "is_terminate": isTerminate,
        "is_selected": isSelected,
        "is_started": isStarted,
        "lista_productos": listaProductos == null
            ? []
            : List<dynamic>.from(listaProductos!.map((x) => x.toMap())),
        "lista_paquetes": listaPaquetes == null
            ? []
            : List<dynamic>.from(listaPaquetes!.map((x) => x.toMap())),
        "create_backorder": createBackorder,
      };
}
