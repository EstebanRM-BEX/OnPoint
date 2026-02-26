// To parse this JSON data, do
//
//     final responseReceptionBatchs = responseReceptionBatchsFromMap(jsonString);

import 'dart:convert';

import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';

ResponseReceptionBatchs responseReceptionBatchsFromMap(String str) =>
    ResponseReceptionBatchs.fromMap(json.decode(str));

String responseReceptionBatchsToMap(ResponseReceptionBatchs data) =>
    json.encode(data.toMap());

class ResponseReceptionBatchs {
  String? jsonrpc;
  dynamic id;
  ResponseReceptionBatchsResult? result;

  ResponseReceptionBatchs({
    this.jsonrpc,
    this.id,
    this.result,
  });

  factory ResponseReceptionBatchs.fromMap(Map<String, dynamic> json) =>
      ResponseReceptionBatchs(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null
            ? null
            : ResponseReceptionBatchsResult.fromMap(json["result"]),
      );

  Map<String, dynamic> toMap() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "result": result?.toMap(),
      };
}

class ResponseReceptionBatchsResult {
  int? code;
  List<ReceptionBatch>? result;
  String? msg;
  bool? updateVersion;

  ResponseReceptionBatchsResult({
    this.code,
    this.result,
    this.msg,
    this.updateVersion,
  });

  factory ResponseReceptionBatchsResult.fromMap(Map<String, dynamic> json) =>
      ResponseReceptionBatchsResult(
        code: json["code"],
        msg: json["msg"],
        updateVersion: json["update_version"] ?? false,
        result: json["result"] == null
            ? []
            : List<ReceptionBatch>.from(
                json["result"]!.map((x) => ReceptionBatch.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
        "code": code,
        "update_version": updateVersion,
        "result": result == null
            ? []
            : List<dynamic>.from(result!.map((x) => x.toMap())),
        "msg": msg,
      };
}

class ReceptionBatch {
  int? id;
  String? name;
  String? orderBy;
  String? orderPicking;
  String? fechaCreacion;
  String? state;
  int? pickingTypeId;
  String? pickingType;
  String? pickingTypeCode;
  String? observation;
  int? locationId;
  String? locationName;
  String? locationBarcode;
  int? warehouseId;
  String? warehouseName;
  dynamic numeroLineas;
  dynamic numeroItems;
  String? startTimeReception;
  String? endTimeReception;
  String? priority;
  String? zonaEntrega;
  // String? origin;
  int? responsableId;
  String? responsable;
  int? proveedorId;
  String? proveedor;
  int? locationDestId;
  String? locationDestName;
  int? purchaseOrderId;
  String? purchaseOrderName;
  dynamic showCheckAvailability;
  List<LineasRecepcionBatch>? lineasRecepcion;
  List<LineasRecepcionBatch>? lineasRecepcionEnviadas;

  dynamic isSelected;
  dynamic isStarted;
  dynamic isFinish;
  String? propietario;

  ReceptionBatch({
    this.id,
    this.name,
    this.orderBy,
    this.orderPicking,
    this.fechaCreacion,
    this.state,
    this.pickingTypeId,
    this.pickingType,
    this.pickingTypeCode,
    this.observation,
    this.locationId,
    this.locationName,
    this.locationBarcode,
    this.warehouseId,
    this.warehouseName,
    this.numeroLineas,
    this.numeroItems,
    this.startTimeReception,
    this.endTimeReception,
    this.priority,
    this.zonaEntrega,
    // this.origin,
    this.responsableId,
    this.responsable,
    this.proveedorId,
    this.proveedor,
    this.locationDestId,
    this.locationDestName,
    this.purchaseOrderId,
    this.purchaseOrderName,
    this.showCheckAvailability,
    this.lineasRecepcion,
    this.lineasRecepcionEnviadas,
    this.isSelected,
    this.isStarted,
    this.isFinish,
    this.propietario,
  });

  factory ReceptionBatch.fromMap(Map<String, dynamic> json) => ReceptionBatch(
        id: json["id"],
        name: json["name"],
        orderBy: json["order_by"],
        orderPicking: json["order_picking"],
        fechaCreacion: json["fecha_creacion"],
        state: json["state"],
        pickingTypeId: json["picking_type_id"],
        pickingType: json["picking_type"],
        pickingTypeCode: json["picking_type_code"],
        observation: json["observation"],
        locationId: json["location_id"],
        locationName: json["location_name"],
        locationBarcode: json["location_barcode"],
        warehouseId: json["warehouse_id"],
        warehouseName: json["warehouse_name"],
        numeroLineas: json["numero_lineas"],
        numeroItems: json["numero_items"],
        startTimeReception: json["start_time_reception"],
        endTimeReception: json["end_time_reception"],
        priority: json["priority"],
        zonaEntrega: json["zona_entrega"],
        // origin: json["origin"],
        responsableId: json["responsable_id"],
        responsable: json["responsable"],
        proveedorId: json["proveedor_id"],
        proveedor: json["proveedor"],
        locationDestId: json["location_dest_id"],
        locationDestName: json["location_dest_name"],
        purchaseOrderId: json["purchase_order_id"],
        purchaseOrderName: json["purchase_order_name"],
        showCheckAvailability: json["show_check_availability"],
        lineasRecepcion: json["lineas_recepcion"] == null
            ? []
            : List<LineasRecepcionBatch>.from(json["lineas_recepcion"]!
                .map((x) => LineasRecepcionBatch.fromMap(x))),
        lineasRecepcionEnviadas: json["lineas_recepcion_enviadas"] == null
            ? []
            : List<LineasRecepcionBatch>.from(json["lineas_recepcion_enviadas"]!
                .map((x) => LineasRecepcionBatch.fromMap(x))),
        isSelected: json["isSelected"],
        isStarted: json["isStarted"],
        isFinish: json["isFinish"],
        propietario: json["propietario"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "order_by": orderBy,
        "order_picking": orderPicking,
        "fecha_creacion": fechaCreacion,
        "state": state,
        "picking_type_id": pickingTypeId,
        "picking_type": pickingType,
        "picking_type_code": pickingTypeCode,
        "observation": observation,
        "location_id": locationId,
        "location_name": locationName,
        "location_barcode": locationBarcode,
        "warehouse_id": warehouseId,
        "warehouse_name": warehouseName,
        "numero_lineas": numeroLineas,
        "numero_items": numeroItems,
        "start_time_reception": startTimeReception,
        "end_time_reception": endTimeReception,
        "priority": priority,
        "zona_entrega": zonaEntrega,
        // "origin": origin,
        "responsable_id": responsableId,
        "responsable": responsable,
        "proveedor_id": proveedorId,
        "proveedor": proveedor,
        "location_dest_id": locationDestId,
        "location_dest_name": locationDestName,
        "purchase_order_id": purchaseOrderId,
        "purchase_order_name": purchaseOrderName,
        "show_check_availability": showCheckAvailability,
        "lineas_recepcion": lineasRecepcion == null
            ? []
            : List<dynamic>.from(lineasRecepcion!.map((x) => x.toMap())),
        "lineas_recepcion_enviadas": lineasRecepcionEnviadas == null
            ? []
            : List<dynamic>.from(
                lineasRecepcionEnviadas!.map((x) => x.toMap())),
        "isSelected": isSelected,
        "isStarted": isStarted,
        "isFinish": isFinish,
        "propietario": propietario,
      };
}

class LineasRecepcionBatch {
  int? id;
  int? idMove;
  int? idRecepcion;
  String? state;
  dynamic productId;
  String? productName;
  String? productCode;
  String? productBarcode;
  String? productTracking;
  String? fechaVencimiento;
  dynamic? diasVencimiento;
  List<Barcodes>? otherBarcodes;
  List<Barcodes>? productPacking;
  dynamic quantityOrdered;
  dynamic cantidadFaltante;
  dynamic quantityToReceive;
  dynamic quantityDone;

  String? uom;
  int? locationDestId;
  String? locationDestName;
  String? locationDestBarcode;
  int? locationId;
  String? locationName;
  dynamic? locationBarcode;
  double? weight;
  int? rimovalPriority;
  int? lotId;
  String? lotName;
  String? zonaEntrega;
  int? idZonaEntrega;
  int? pickingId;
  String? pickingName;
  String? origin;
  dynamic? observation;
  String? dateTransaction;
  dynamic time;
  dynamic isDoneItem;
  dynamic isSelected;
  dynamic isSeparate;
  dynamic isProductSplit;

  dynamic manejaTemperatura;
  dynamic temperatura;
  String? image;

  final dynamic dateStart;
  final dynamic dateEnd;
  final dynamic useExpirationDate;

  LineasRecepcionBatch({
    this.id,
    this.idMove,
    this.idRecepcion,
    this.state,
    this.productId,
    this.productName,
    this.productCode,
    this.productBarcode,
    this.productTracking,
    this.fechaVencimiento,
    this.diasVencimiento,
    this.otherBarcodes,
    this.productPacking,
    this.quantityOrdered,
    this.cantidadFaltante,
    this.quantityToReceive,
    this.uom,
    this.locationDestId,
    this.locationDestName,
    this.locationDestBarcode,
    this.locationId,
    this.locationName,
    this.locationBarcode,
    this.weight,
    this.rimovalPriority,
    this.lotId,
    this.lotName,
    this.zonaEntrega,
    this.idZonaEntrega,
    this.pickingId,
    this.pickingName,
    this.origin,
    this.observation,
    this.dateTransaction,
    this.time,
    this.isDoneItem,
    this.isSelected,
    this.isSeparate,
    this.isProductSplit,
    this.quantityDone,
    this.dateStart,
    this.dateEnd,
    this.manejaTemperatura,
    this.temperatura,
    this.image,
    this.useExpirationDate,
  });

  factory LineasRecepcionBatch.fromMap(Map<String, dynamic> json) =>
      LineasRecepcionBatch(
        id: json["id"],
        idMove: json["id_move"],
        idRecepcion: json["id_recepcion"],
        state: json["state"],
        productId: json["product_id"],
        productName: json["product_name"],
        productCode: json["product_code"],
        productBarcode: json["product_barcode"],
        productTracking: json["product_tracking"],
        fechaVencimiento:
            json["fecha_vencimiento"] == false ? "" : json["fecha_vencimiento"],
        diasVencimiento: json["dias_vencimiento"],
        otherBarcodes: json["other_barcodes"] == null
            ? []
            : List<Barcodes>.from(
                json["other_barcodes"]!.map((x) => Barcodes.fromMap(x))),
        productPacking: json["product_packing"] == null
            ? []
            : List<Barcodes>.from(
                json["product_packing"]!.map((x) => Barcodes.fromMap(x))),
        quantityOrdered: json["quantity_ordered"],
        cantidadFaltante: json["cantidad_faltante"],
        quantityToReceive: json["quantity_to_receive"],
        uom: json["uom"],
        locationDestId: json["location_dest_id"],
        locationDestName: json["location_dest_name"],
        locationDestBarcode: json["location_dest_barcode"],
        locationId: json["location_id"],
        locationName: json["location_name"],
        locationBarcode: json["location_barcode"],
        weight: json["weight"]?.toDouble(),
        rimovalPriority: json["rimoval_priority"],
        lotId: json["lot_id"],
        lotName: json["lot_name"],
        zonaEntrega: json["zona_entrega"] == false ? "" : json["zona_entrega"],
        idZonaEntrega: json["id_zona_entrega"],
        pickingId: json["picking_id"],
        pickingName: json["picking_name"],
        origin: json["origin"],
        observation: json["observation"],
        dateTransaction: json["date_transaction"],
        time: json["time"],
        isDoneItem: json["is_done_item"],
        isSelected: json["isSelected"],
        isSeparate: json["isSeparate"],
        isProductSplit: json["isProductSplit"],
        quantityDone: json["quantity_done"],
        dateStart: json["date_start"],
        dateEnd: json["date_end"],
        manejaTemperatura: json["maneja_temperatura"],
        temperatura: json["temperatura"],
        image: json["image"],
        useExpirationDate: json["use_expiration_date"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "id_move": idMove,
        "id_recepcion": idRecepcion,
        "state": state,
        "product_id": productId,
        "product_name": productName,
        "product_code": productCode,
        "product_barcode": productBarcode,
        "product_tracking": productTracking,
        "fecha_vencimiento": fechaVencimiento,
        "dias_vencimiento": diasVencimiento,
        "other_barcodes": otherBarcodes == null
            ? []
            : List<dynamic>.from(otherBarcodes!.map((x) => x)),
        "product_packing": productPacking == null
            ? []
            : List<dynamic>.from(productPacking!.map((x) => x)),
        "quantity_ordered": quantityOrdered,
        "cantidad_faltante": cantidadFaltante,
        "quantity_to_receive": quantityToReceive,
        "uom": uom,
        "location_dest_id": locationDestId,
        "location_dest_name": locationDestName,
        "location_dest_barcode": locationDestBarcode,
        "location_id": locationId,
        "location_name": locationName,
        "location_barcode": locationBarcode,
        "weight": weight,
        "rimoval_priority": rimovalPriority,
        "lot_id": lotId,
        "lot_name": lotName,
        "zona_entrega": zonaEntrega == false ? "" : zonaEntrega,
        "id_zona_entrega": idZonaEntrega,
        "picking_id": pickingId,
        "picking_name": pickingName,
        "origin": origin,
        "observation": observation,
        "date_transaction": dateTransaction,
        "time": time,
        "is_done_item": isDoneItem,
        "isSelected": isSelected,
        "isSeparate": isSeparate,
        "isProductSplit": isProductSplit,
        "quantity_done": quantityDone,
        "date_start": dateStart,
        "date_end": dateEnd,
        "maneja_temperatura": manejaTemperatura,
        "temperatura": temperatura,
        "image": image,
        "use_expiration_date": useExpirationDate,
      };
}

class Origin {
  String? name;
  int? id;
  int? idBatch;

  Origin({
    this.name,
    this.id,
    this.idBatch,
  });

  factory Origin.fromMap(Map<String, dynamic> json) => Origin(
        name: json["name"],
        id: json["id"],
        idBatch: json["id_batch"],
      );

  Map<String, dynamic> toMap() => {
        "name": name,
        "id": id,
        "id_batch": idBatch,
      };
}
