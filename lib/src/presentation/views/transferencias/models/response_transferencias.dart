// To parse this JSON data, do
//
//     final responseTransferencias = responseTransferenciasFromMap(jsonString);

import 'dart:convert';

import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';

ResponseTransferencias responseTransferenciasFromMap(String str) =>
    ResponseTransferencias.fromMap(json.decode(str));

String responseTransferenciasToMap(ResponseTransferencias data) =>
    json.encode(data.toMap());

class ResponseTransferencias {
  String? jsonrpc;
  dynamic id;
  ResponseTransferenciasResult? result;

  ResponseTransferencias({
    this.jsonrpc,
    this.id,
    this.result,
  });

  factory ResponseTransferencias.fromMap(Map<String, dynamic> json) =>
      ResponseTransferencias(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null
            ? null
            : ResponseTransferenciasResult.fromMap(json["result"]),
      );

  Map<String, dynamic> toMap() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "result": result?.toMap(),
      };
}

class ResponseTransferenciasResult {
  int? code;
  String ?msg;
  bool? updateVersion;
  List<ResultTransFerencias>? result;

  ResponseTransferenciasResult({
    this.code,
    this.msg,
    this.updateVersion,
    this.result,
  });

  factory ResponseTransferenciasResult.fromMap(Map<String, dynamic> json) =>
      ResponseTransferenciasResult(
        code: json["code"],
        msg: json["msg"],
        updateVersion: json["update_version"] ?? false,
        result: json["result"] == null
            ? []
            : List<ResultTransFerencias>.from(
                json["result"]!.map((x) => ResultTransFerencias.fromMap(x))),
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

class ResultTransFerencias {
  int? id;
  String? name;
  String? fechaCreacion;
  int? locationId;
  String? locationName;
  int? locationDestId;
  String? locationDestName;
  String? numeroTransferencia;
  double? pesoTotal;
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

  dynamic startTimeTransfer;
  dynamic endTimeTransfer;
  dynamic isSelected;
  dynamic isStarted;
  dynamic isFinish;

  dynamic proveedor;
  String? type;
  

  List<LineasTransferenciaTrans>? lineasTransferencia;
  List<LineasTransferenciaTrans>? lineasTransferenciaEnviadas;

  final dynamic backorderName;
  final dynamic backorderId;
  final dynamic showCheckAvailability;
  final String? createBackorder;

  String? propietario;
  dynamic? manejoPropietario;


  ResultTransFerencias({
    this.id,
    this.name,
    this.fechaCreacion,
    this.locationId,
    this.locationName,
    this.locationDestId,
    this.locationDestName,
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
    this.lineasTransferencia,
    this.lineasTransferenciaEnviadas,
    this.startTimeTransfer,
    this.endTimeTransfer,
    this.isSelected,
    this.isStarted,
    this.isFinish,
    this.backorderName,
    this.backorderId,
    this.showCheckAvailability,
    this.proveedor,
    this.type,
    this.createBackorder,
    this.propietario,
    this.manejoPropietario,
  });

  factory ResultTransFerencias.fromMap(Map<String, dynamic> json) =>
      ResultTransFerencias(
        id: json["id"],
        name: json["name"],
        fechaCreacion: json["fecha_creacion"],
        locationId: json["location_id"],
        locationName: json["location_name"],
        locationDestId: json["location_dest_id"],
        locationDestName: json["location_dest_name"],
        numeroTransferencia: json["numero_transferencia"],
        pesoTotal: json["peso_total"]?.toDouble(),
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
        isSelected: json["is_selected"],
        isStarted: json["is_started"],
        isFinish: json["is_finish"],
        lineasTransferencia: json["lineas_transferencia"] == null
            ? []
            : List<LineasTransferenciaTrans>.from(json["lineas_transferencia"]!
                .map((x) => LineasTransferenciaTrans.fromMap(x))),
        lineasTransferenciaEnviadas:
            json["lineas_transferencia_enviadas"] == null
                ? []
                : List<LineasTransferenciaTrans>.from(
                    json["lineas_transferencia_enviadas"]
                        .map((x) => LineasTransferenciaTrans.fromMap(x))),
        backorderName: json["backorder_name"],
        backorderId: json["backorder_id"],
        showCheckAvailability: json["show_check_availability"],
        proveedor: json["proveedor"],
        type: json["type"],
        createBackorder: json["create_backorder"],
        propietario: json["propietario"],
        manejoPropietario: json["manejo_propietario"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "fecha_creacion": fechaCreacion,
        "location_id": locationId,
        "location_name": locationName,
        "location_dest_id": locationDestId,
        "location_dest_name": locationDestName,
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
        "responsable": responsable,
        "picking_type": pickingType,
        "start_time_transfer": startTimeTransfer,
        "end_time_transfer": endTimeTransfer,
        "is_selected": isSelected,
        "is_started": isStarted,
        "is_finish": isFinish,
        "lineas_transferencia": lineasTransferencia == null
            ? []
            : List<dynamic>.from(lineasTransferencia!.map((x) => x.toMap())),
        "lineas_transferencia_enviadas": lineasTransferenciaEnviadas == null
            ? []
            : List<dynamic>.from(lineasTransferenciaEnviadas!.map((x) => x)),
        "backorder_name": backorderName,
        "backorder_id": backorderId,
        "show_check_availability": showCheckAvailability,
        "proveedor": proveedor,
        "type": type,
        "create_backorder": createBackorder,
         "propietario": propietario,
        "manejo_propietario": manejoPropietario
      };
}

class LineasTransferenciaTrans {
  int? idMove;
  int? idTransferencia;
  dynamic productId;
  String? productName;
  String? productCode;
  String? productBarcode;
  String? productTracking;
  dynamic diasVencimiento;
  List<Barcodes>? otherBarcodes;
  List<Barcodes>? productPacking;
  dynamic quantityOrdered;
  dynamic quantityToTransfer;
  dynamic quantityDone;
  String? uom;
  dynamic locationDestId;
  String? locationDestName;
  String? locationDestBarcode;
  dynamic locationId;
  String? locationName;
  String? locationBarcode;
  double? weight;
  dynamic lotId;
  String? lotName;
  String? fechaVencimiento;
  dynamic observation;

  late dynamic
      isLocationIsOk; // Variable para si la ubicación es leída correctamente
  late dynamic
      productIsOk; // Variable para si el producto es leído correctamente
  late dynamic
      locationDestIsOk; // Variable para si la ubicación destino está leída
  late dynamic
      isQuantityIsOk; // Variable para si la cantidad es leída correctamente
  dynamic isProductSplit;
  dynamic isSeparate;
  dynamic isSelected;
  final dynamic time;
  final dynamic isDoneItem;
  final dynamic dateTransaction;
  final dynamic dateStart;
  final dynamic dateEnd;
  final dynamic cantidadFaltante;
  final String? type;
  final dynamic manejaSegundaUnidad;
  final String? uomSegundaUnidad;
  final double? quantitySegundaUnidad;

  LineasTransferenciaTrans({
    this.idMove,
    this.idTransferencia,
    this.productId,
    this.productName,
    this.productCode,
    this.productBarcode,
    this.productTracking,
    this.diasVencimiento,
    this.otherBarcodes,
    this.productPacking,
    this.quantityOrdered,
    this.quantityToTransfer,
    this.quantityDone,
    this.uom,
    this.locationDestId,
    this.locationDestName,
    this.locationDestBarcode,
    this.locationId,
    this.locationName,
    this.locationBarcode,
    this.weight,
    this.lotId,
    this.lotName,
    this.fechaVencimiento,
    this.isLocationIsOk,
    this.isQuantityIsOk,
    this.locationDestIsOk,
    this.productIsOk,
    this.isProductSplit,
    this.isSeparate,
    this.isSelected,
    this.observation,
    this.time,
    this.isDoneItem,
    this.dateTransaction,
    this.dateStart,
    this.dateEnd,
    this.cantidadFaltante,
    this.type,
    this.manejaSegundaUnidad,
    this.uomSegundaUnidad,
    this.quantitySegundaUnidad,
  });

  factory LineasTransferenciaTrans.fromMap(Map<String, dynamic> json) =>
      LineasTransferenciaTrans(
        idMove: json["id_move"],
        idTransferencia: json["id_transferencia"],
        productId: json["product_id"],
        productName: json["product_name"],
        productCode: json["product_code"],
        productBarcode: json["product_barcode"],
        productTracking: json["product_tracking"],
        diasVencimiento: json["dias_vencimiento"],
        otherBarcodes: json["other_barcodes"] == null
            ? []
            : List<Barcodes>.from(
                json["other_barcodes"].map((x) => Barcodes.fromMap(x))),
        productPacking: json["product_packing"] == null
            ? []
            : List<Barcodes>.from(
                json["product_packing"].map((x) => Barcodes.fromMap(x))),
        quantityOrdered: json["quantity_ordered"],
        quantityToTransfer: json["quantity_to_transfer"],
        quantityDone: json["quantity_done"],
        uom: json["uom"],
        locationDestId: json["location_dest_id"],
        locationDestName: json["location_dest_name"],
        locationDestBarcode: json["location_dest_barcode"],
        locationId: json["location_id"],
        locationName: json["location_name"],
        locationBarcode: json["location_barcode"],
        weight: json["weight"]?.toDouble(),
        lotId: json["lot_id"],
        lotName: json["lot_name"],
        fechaVencimiento: json["fecha_vencimiento"],
        isLocationIsOk: json["is_location_is_ok"] ?? false,
        productIsOk: json["product_is_ok"] ?? false,
        locationDestIsOk: json["location_dest_is_ok"] ?? false,
        isQuantityIsOk: json["is_quantity_is_ok"] ?? false,
        isProductSplit: json['is_product_split'],
        isSeparate: json['is_separate'],
        isSelected: json['is_selected'],
        observation: json['observation'],
        time: json["time"],
        isDoneItem: json["is_done_item"],
        dateTransaction: json["date_transaction"],
        dateStart: json["date_start"],
        dateEnd: json["date_end"],
        cantidadFaltante: json["cantidad_faltante"],
        type: json["type"],
        manejaSegundaUnidad: json["maneja_segunda_unidad"],
        uomSegundaUnidad: json["uom_segunda_unidad"],
        quantitySegundaUnidad: json["quantity_segunda_unidad"]?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        "id_move": idMove,
        "id_transferencia": idTransferencia,
        "product_id": productId,
        "product_name": productName,
        "product_code": productCode,
        "product_barcode": productBarcode,
        "product_tracking": productTracking,
        "dias_vencimiento": diasVencimiento,
        "other_barcodes": otherBarcodes == null
            ? []
            : List<dynamic>.from(otherBarcodes!.map((x) => x)),
        "product_packing": productPacking == null
            ? []
            : List<dynamic>.from(productPacking!.map((x) => x)),
        "quantity_ordered": quantityOrdered,
        "quantity_to_transfer": quantityToTransfer,
        "quantity_done": quantityDone,
        "uom": uom,
        "location_dest_id": locationDestId,
        "location_dest_name": locationDestName,
        "location_dest_barcode": locationDestBarcode,
        "location_id": locationId,
        "location_name": locationName,
        "location_barcode": locationBarcode,
        "weight": weight,
        "lot_id": lotId,
        "lot_name": lotName,
        "fecha_vencimiento": fechaVencimiento,
        "is_location_is_ok": isLocationIsOk,
        "product_is_ok": productIsOk,
        "location_dest_is_ok": locationDestIsOk,
        "is_quantity_is_ok": isQuantityIsOk,
        "is_product_split": isProductSplit,
        "is_separate": isSeparate,
        "is_selected": isSelected,
        "observation": observation,
        "time": time,
        "is_done_item": isDoneItem,
        "date_transaction": dateTransaction,
        "date_start": dateStart,
        "date_end": dateEnd,
        "cantidad_faltante": cantidadFaltante,
        "type": type,
        "maneja_segunda_unidad": manejaSegundaUnidad,
        "uom_segunda_unidad": uomSegundaUnidad,
        "quantity_segunda_unidad": quantitySegundaUnidad,
      };
}
