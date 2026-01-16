// To parse this JSON data, do
//
//     final responsePick = responsePickFromMap(jsonString);

import 'dart:convert';

import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';

ResponsePick responsePickFromMap(String str) =>
    ResponsePick.fromMap(json.decode(str));

String responsePickToMap(ResponsePick data) => json.encode(data.toMap());

class ResponsePick {
  String? jsonrpc;
  dynamic id;
  ResponsePickResult? result;

  ResponsePick({
    this.jsonrpc,
    this.id,
    this.result,
  });

  factory ResponsePick.fromMap(Map<String, dynamic> json) => ResponsePick(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null
            ? null
            : ResponsePickResult.fromMap(json["result"]),
      );

  Map<String, dynamic> toMap() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "result": result?.toMap(),
      };
}

class ResponsePickResult {
  int? code;
  List<ResultPick>? result;
  bool? updateVersion;
  String? msg;

  ResponsePickResult({
    this.code,
    this.result,
    this.updateVersion,
    this.msg,
  });

  factory ResponsePickResult.fromMap(Map<String, dynamic> json) =>
      ResponsePickResult(
        code: json["code"],
        result: json["result"] == null
            ? []
            : List<ResultPick>.from(
                json["result"]!.map((x) => ResultPick.fromMap(x))),
        msg: json["msg"],
        updateVersion: json["update_version"],
      );

  Map<String, dynamic> toMap() => {
        "code": code,
        "result": result == null
            ? []
            : List<dynamic>.from(result!.map((x) => x.toMap())),
        "msg": msg,
        "update_version": updateVersion,
      };
}

class ResultPick {
  int? id;
  String? name;
  String? observacion;
  String? fechaCreacion;
  int? locationId;
  String? locationName;
  String? locationBarcode;
  int? locationDestId;
  String? locationDestName;
  String? locationDestBarcode;
  String? proveedor;
  String? numeroTransferencia;
  int? pesoTotal;
  dynamic numeroLineas;
  dynamic numeroItems;
  String? state;
  String? origin;
  String? priority;
  int? warehouseId;
  String? warehouseName;
  int? responsableId;
  String? responsable;
  String? pickingType;
  String? startTimeTransfer;
  String? endTimeTransfer;
  int? backorderId;
  String? backorderName;
  dynamic showCheckAvailability;

  String? createBackorder;

  String? typePick;
  String? referencia; //dato solo para pick done

  //valores para el pick
  dynamic isSeparate;
  dynamic isSelected;
  String? zonaEntrega;
  String? muelle;
  final int? indexList;
  final String? barcodeMuelle;
  final dynamic muelleId;
  final dynamic idMuellePadre;
  final String? isSendOdoo;
  final String? isSendOdooDate;
  final String? observation;
  final dynamic orderBy;
  final dynamic orderPicking;

  String? productoFinalNombre;
  String? productoFinalReferencia;

  List<ProductsBatch>? lineasTransferencia;

  List<ProductsBatch>? lineasTransferenciaEnviadas;

  final dynamic quantityDone;
  final dynamic quantityOrdered;

  ResultPick(
      {this.id,
      this.name,
      this.observacion,
      this.fechaCreacion,
      this.locationId,
      this.locationName,
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
      this.origin,
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
      this.lineasTransferencia,
      this.lineasTransferenciaEnviadas,
      this.isSeparate,
      this.isSelected,
      this.zonaEntrega,
      this.muelle,
      this.barcodeMuelle,
      this.muelleId,
      this.idMuellePadre,
      this.indexList,
      this.isSendOdoo,
      this.isSendOdooDate,
      this.observation,
      this.orderBy,
      this.orderPicking,
      this.typePick,
      this.productoFinalNombre,
      this.productoFinalReferencia,
      this.createBackorder,
      this.quantityDone,
      this.referencia, //dato solo para pick done
      this.quantityOrdered});

  factory ResultPick.fromMap(Map<String, dynamic> json) => ResultPick(
        id: json["id"],
        name: json["name"],
        observacion: json["observacion"],
        fechaCreacion: json["fecha_creacion"],
        locationId: json["location_id"],
        locationName: json["location_name"],
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
        origin: json["origin"],
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
        lineasTransferencia: json["lineas_transferencia"] == null
            ? []
            : List<ProductsBatch>.from(json["lineas_transferencia"]!
                .map((x) => ProductsBatch.fromMap(x))),
        lineasTransferenciaEnviadas: json["lineas_transferencia_enviadas"] ==
                null
            ? []
            : List<ProductsBatch>.from(json["lineas_transferencia_enviadas"]!
                .map((x) => ProductsBatch.fromMap(x))),
        isSeparate: json["is_separate"],
        isSelected: json["is_selected"],
        zonaEntrega: json["zona_entrega"],
        muelle: json["muelle"],
        barcodeMuelle: json["barcode_muelle"],
        muelleId: json["muelle_id"],
        idMuellePadre: json["id_muelle_padre"],
        indexList: json["index_list"],
        isSendOdoo: json["is_send_odoo"],
        isSendOdooDate: json["is_send_odoo_date"],
        observation: json["observation"],
        referencia: json["referencia"], //dato solo para pick done
        orderBy: json["order_by"],
        orderPicking: json["order_picking"],
        typePick: json["type_pick"],
        productoFinalNombre: json["producto_final_nombre"],
        productoFinalReferencia: json["producto_final_referencia"],
        createBackorder: json["create_backorder"],
        quantityDone: json["quantity_done"],
        quantityOrdered: json["quantity_ordered"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "observacion": observacion,
        "fecha_creacion": fechaCreacion,
        "location_id": locationId,
        "location_name": locationName,
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
        "origin": origin,
        "priority": priority,
        "warehouse_id": warehouseId,
        "warehouse_name": warehouseName,
        "responsable_id": responsableId,
        "referencia": referencia, //dato solo para pick done
        "responsable": responsable,
        "picking_type": pickingType,
        "start_time_transfer": startTimeTransfer,
        "end_time_transfer": endTimeTransfer,
        "backorder_id": backorderId,
        "backorder_name": backorderName,
        "show_check_availability": showCheckAvailability,
        "lineas_transferencia": lineasTransferencia == null
            ? []
            : List<dynamic>.from(lineasTransferencia!.map((x) => x.toMap())),
        "lineas_transferencia_enviadas": lineasTransferenciaEnviadas == null
            ? []
            : List<dynamic>.from(
                lineasTransferenciaEnviadas!.map((x) => x.toMap())),
        "is_separate": isSeparate,
        "is_selected": isSelected,
        "zona_entrega": zonaEntrega,
        "muelle": muelle,
        "barcode_muelle": barcodeMuelle,
        "muelle_id": muelleId,
        "id_muelle_padre": idMuellePadre,
        "index_list": indexList,
        "is_send_odoo": isSendOdoo,
        "is_send_odoo_date": isSendOdooDate,
        "observation": observation,
        "order_by": orderBy,
        "order_picking": orderPicking,
        "type_pick": typePick,
        "producto_final_nombre": productoFinalNombre,
        "producto_final_referencia": productoFinalReferencia,
        "create_backorder": createBackorder,
        "quantity_done": quantityDone,
        "quantity_ordered": quantityOrdered,
      };
}
