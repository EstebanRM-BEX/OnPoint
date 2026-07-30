// To parse this JSON data, do
//
//     final recepcionresponse = recepcionresponseFromMap(jsonString);

import 'dart:convert';

import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';

Recepcionresponse recepcionresponseFromMap(String str) =>
    Recepcionresponse.fromMap(json.decode(str));

String recepcionresponseToMap(Recepcionresponse data) =>
    json.encode(data.toMap());

// Odoo devuelve `false` (no null/0) en campos numéricos vacíos (many2one sin
// valor, floats sin configurar). Sin este guard, asignarlo directo a un campo
// int?/double? revienta con un type error y tumba el parseo de toda la lista.
int? _asIntOrNull(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

double? _asDoubleOrNull(dynamic value) {
  if (value is num) return value.toDouble();
  return null;
}

class Recepcionresponse {
  String? jsonrpc;
  dynamic id;
  RecepcionresponseResult? result;

  Recepcionresponse({this.jsonrpc, this.id, this.result});

  factory Recepcionresponse.fromMap(Map<String, dynamic> json) =>
      Recepcionresponse(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null
            ? null
            : RecepcionresponseResult.fromMap(json["result"]),
      );

  Map<String, dynamic> toMap() => {
    "jsonrpc": jsonrpc,
    "id": id,
    "result": result?.toMap(),
  };
}

class RecepcionresponseResult {
  int? code;
  String? msg;
  bool? updateVersion;
  List<ResultEntrada>? result;

  RecepcionresponseResult({
    this.code,
    this.msg,
    this.updateVersion,
    this.result,
  });

  factory RecepcionresponseResult.fromMap(Map<String, dynamic> json) =>
      RecepcionresponseResult(
        code: json["code"],
        msg: json["msg"],
        updateVersion: json["update_version"] ?? false,
        result: json["result"] == null
            ? []
            : List<ResultEntrada>.from(
                json["result"]!.map((x) => ResultEntrada.fromMap(x)),
              ),
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

class ResultEntrada {
  int? id;
  String? name;
  String? fechaCreacion;
  dynamic proveedorId;
  dynamic proveedor;
  int? locationDestId;
  String? locationDestName;
  String? locationDestBarode;
  int? purchaseOrderId;
  String? purchaseOrderName;
  String? numeroEntrada;
  double? pesoTotal;
  dynamic numeroLineas;
  dynamic numeroItems;
  String? state;
  String? origin;
  String? priority;
  int? warehouseId;
  String? warehouseName;
  int? locationId;
  String? locationName;
  int? responsableId;
  String? responsable;
  String? pickingType;

  dynamic manejaTemperatura;
  dynamic temperatura;

  dynamic startTimeReception;
  dynamic endTimeReception;
  dynamic isSelected;
  dynamic isStarted;
  dynamic isFinish;
  String? type;
  String? createBackorder;

  String? propietario;
  dynamic? manejoPropietario;

  List<LineasTransferencia>? lineasRecepcion;
  List<LineasTransferencia>? lineasRecepcionEnviadas;

  final dynamic backorderName;
  final dynamic backorderId;

  ResultEntrada({
    this.id,
    this.name,
    this.fechaCreacion,
    this.proveedorId,
    this.proveedor,
    this.locationDestId,
    this.locationDestName,
    this.locationDestBarode,
    this.purchaseOrderId,
    this.purchaseOrderName,
    this.numeroEntrada,
    this.pesoTotal,
    this.numeroLineas,
    this.numeroItems,
    this.state,
    this.origin,
    this.priority,
    this.warehouseId,
    this.warehouseName,
    this.locationId,
    this.locationName,
    this.responsableId,
    this.responsable,
    this.pickingType,
    this.startTimeReception,
    this.endTimeReception,
    this.isSelected,
    this.isStarted,
    this.isFinish,
    this.lineasRecepcion,
    this.lineasRecepcionEnviadas,
    this.backorderName,
    this.backorderId,
    this.manejaTemperatura,
    this.temperatura,
    this.type,
    this.propietario,
    this.manejoPropietario,
    this.createBackorder,
  });

  factory ResultEntrada.fromMap(Map<String, dynamic> json) => ResultEntrada(
    id: _asIntOrNull(json["id"]),
    name: json["name"],
    fechaCreacion: json["fecha_creacion"],
    proveedorId: json["proveedor_id"],
    proveedor: json["proveedor"],
    locationDestId: _asIntOrNull(json["location_dest_id"]),
    locationDestName: json["location_dest_name"],
    locationDestBarode: json["location_dest_barode"],
    purchaseOrderId: _asIntOrNull(json["purchase_order_id"]),
    purchaseOrderName: json["purchase_order_name"],
    numeroEntrada: json["numero_entrada"],
    pesoTotal: _asDoubleOrNull(json["peso_total"]),
    numeroLineas: json["numero_lineas"],
    numeroItems: json["numero_items"],
    state: json["state"],
    origin: json["origin"],
    priority: json["priority"],
    warehouseId: _asIntOrNull(json["warehouse_id"]),
    warehouseName: json["warehouse_name"],
    locationId: _asIntOrNull(json["location_id"]),
    locationName: json["location_name"],
    responsableId: _asIntOrNull(json["responsable_id"]),
    responsable: json["responsable"],
    pickingType: json["picking_type"],
    startTimeReception: json["start_time_reception"],
    endTimeReception: json["end_time_reception"],
    isSelected: json["is_selected"],
    isStarted: json["is_started"],
    isFinish: json["is_finish"],
    lineasRecepcion: json["lineas_recepcion"] == null
        ? []
        : List<LineasTransferencia>.from(
            json["lineas_recepcion"]!.map(
              (x) => LineasTransferencia.fromMap(x),
            ),
          ),
    lineasRecepcionEnviadas: json["lineas_recepcion_enviadas"] == null
        ? []
        : List<LineasTransferencia>.from(
            json["lineas_recepcion_enviadas"]!.map(
              (x) => LineasTransferencia.fromMap(x),
            ),
          ),
    backorderName: json["backorder_name"],
    backorderId: json["backorder_id"],
    manejaTemperatura: json["maneja_temperatura"],
    temperatura: json["temperatura"],
    type: json["type"],
    propietario: json["propietario"],
    manejoPropietario: json["manejo_propietario"],
    createBackorder: json["create_backorder"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "name": name,
    "fecha_creacion": fechaCreacion,
    "proveedor_id": proveedorId,
    "proveedor": proveedor,
    "location_dest_id": locationDestId,
    "location_dest_name": locationDestName,
    "location_dest_barode": locationDestBarode,
    "purchase_order_id": purchaseOrderId,
    "purchase_order_name": purchaseOrderName,
    "numero_entrada": numeroEntrada,
    "peso_total": pesoTotal,
    "numero_lineas": numeroLineas,
    "numero_items": numeroItems,
    "state": state,
    "origin": origin,
    "priority": priority,
    "warehouse_id": warehouseId,
    "warehouse_name": warehouseName,
    "location_id": locationId,
    "location_name": locationName,
    "responsable_id": responsableId,
    "responsable": responsable,
    "picking_type": pickingType,
    "start_time_reception": startTimeReception,
    "end_time_reception": endTimeReception,
    "is_selected": isSelected,
    "is_started": isStarted,
    "is_finish": isFinish,
    "lineas_recepcion": lineasRecepcion == null
        ? []
        : List<dynamic>.from(lineasRecepcion!.map((x) => x.toMap())),
    "lineas_recepcion_enviadas": lineasRecepcionEnviadas == null
        ? []
        : List<dynamic>.from(lineasRecepcionEnviadas!.map((x) => x.toMap())),
    "backorder_name": backorderName,
    "backorder_id": backorderId,
    "maneja_temperatura": manejaTemperatura,
    "temperatura": temperatura,
    "type": type,
    "propietario": propietario,
    "manejo_propietario": manejoPropietario,
    "create_backorder": createBackorder,
  };
}

class LineasTransferencia {
  int? id;
  dynamic productId;
  dynamic idRecepcion;
  dynamic idMove;
  String? productName;
  String? productCode;
  String? productBarcode;
  String? productTracking;
  String? fechaVencimiento;

  dynamic diasVencimiento;
  List<Barcodes>? otherBarcodes;
  List<Barcodes>? productPacking;
  dynamic quantityOrdered;
  dynamic quantityToReceive;
  dynamic quantityDone;
  String? uom;

  int? locationDestId;
  String? locationDestName;
  String? locationDestBarcode;

  int? locationId;
  String? locationName;
  String? locationBarcode;
  double? weight;
  String? type;

  final String? observation;

  final dynamic productIsOk;
  final dynamic isQuantityIsOk;
  final int? loteId;
  final String? lotName;
  final String? loteDate;
  final dynamic quantitySeparate;

  final dynamic isSelected;
  final dynamic isSeparate;
  final dynamic isProductSplit;

  final dynamic dateSeparate;
  final dynamic dateStart;
  final dynamic dateEnd;
  final dynamic time;
  final dynamic isDoneItem;
  final dynamic dateTransaction;

  final dynamic isPrincipalItem;
  final dynamic cantidadFaltante;
  final dynamic manejaTemperatura;
  final dynamic temperatura;
  final dynamic image;
  final dynamic imageNovedad;
  final dynamic useExpirationDate;
  final dynamic manejaSegundaUnidad;
  final String? uomSegundaUnidad;
  final double? quantitySegundaUnidad;
  // date_transaction

  LineasTransferencia({
    this.id,
    this.productId,
    this.idMove,
    this.idRecepcion,
    this.productName,
    this.productCode,
    this.productBarcode,
    this.productTracking,
    this.fechaVencimiento,
    this.diasVencimiento,
    this.otherBarcodes,
    this.productPacking,
    this.quantityOrdered,
    this.quantityToReceive,
    this.quantityDone,
    this.uom,
    this.locationDestId,
    this.locationDestName,
    this.locationDestBarcode,
    this.locationId,
    this.locationName,
    this.locationBarcode,
    this.weight,
    this.loteId,
    this.lotName,
    this.loteDate,
    this.productIsOk,
    this.isQuantityIsOk,
    this.quantitySeparate,
    this.isSelected,
    this.isSeparate,
    this.isProductSplit,
    this.observation,
    this.dateSeparate,
    this.dateStart,
    this.dateEnd,
    this.time,
    this.isDoneItem,
    this.dateTransaction,
    this.isPrincipalItem,
    this.cantidadFaltante,
    this.type,
    this.manejaTemperatura,
    this.temperatura,
    this.image,
    this.imageNovedad,
    this.useExpirationDate,
    this.manejaSegundaUnidad,
    this.uomSegundaUnidad,
    this.quantitySegundaUnidad,
  });

  factory LineasTransferencia.fromMap(Map<String, dynamic> json) =>
      LineasTransferencia(
        id: _asIntOrNull(json["id"]),
        productId: json["product_id"],
        idRecepcion: json["id_recepcion"],
        idMove: json["id_move"],
        productName: json["product_name"],
        productCode: json["product_code"],
        productBarcode: json["product_barcode"],
        productTracking: json["product_tracking"],
        fechaVencimiento: json["fecha_vencimiento"],
        diasVencimiento: json["dias_vencimiento"],
        otherBarcodes: json["other_barcodes"] == null
            ? []
            : List<Barcodes>.from(
                json["other_barcodes"]!.map((x) => Barcodes.fromMap(x)),
              ),
        productPacking: json["product_packing"] == null
            ? []
            : List<Barcodes>.from(
                json["product_packing"]!.map((x) => Barcodes.fromMap(x)),
              ),
        quantityOrdered: json["quantity_ordered"],
        quantityToReceive: json["quantity_to_receive"],
        quantityDone: json["quantity_done"],
        uom: json["uom"],
        locationDestId: _asIntOrNull(json["location_dest_id"]),
        locationDestName: json["location_dest_name"],
        locationDestBarcode: json["location_dest_barcode"],
        locationId: _asIntOrNull(json["location_id"]),
        locationName: json["location_name"],
        locationBarcode: json["location_barcode"],
        weight: _asDoubleOrNull(json["weight"]),
        loteId: _asIntOrNull(json["lote_id"]),
        lotName: json["lot_name"],
        loteDate: json["lote_date"],
        productIsOk: json["product_is_ok"],
        isQuantityIsOk: json["is_quantity_is_ok"],
        quantitySeparate: json["quantity_separate"],
        isSelected: json["is_selected"],
        isSeparate: json["is_separate"],
        isProductSplit: json["is_product_split"],
        observation: json["observation"],
        dateSeparate: json["date_separate"],
        dateStart: json["date_start"],
        dateEnd: json["date_end"],
        time: json["time"],
        isDoneItem: json["is_done_item"],
        dateTransaction: json["date_transaction"],
        isPrincipalItem: json["is_principal_item"],
        cantidadFaltante: json["cantidad_faltante"],
        type: json["type"],
        manejaTemperatura: json["maneja_temperatura"],
        temperatura: json["temperatura"],
        image: json["image"],
        imageNovedad: json["image_novedad"],
        useExpirationDate: json["use_expiration_date"],
        manejaSegundaUnidad: json["maneja_segunda_unidad"],
        uomSegundaUnidad: json["uom_segunda_unidad"],
        quantitySegundaUnidad: _asDoubleOrNull(json["quantity_segunda_unidad"]),
      );

  Map<String, dynamic> toMap() => {
    "id": id,
    "product_id": productId,
    "id_recepcion": idRecepcion,
    "id_move": idMove,
    "product_name": productName,
    "product_code": productCode,
    "product_barcode": productBarcode,
    "product_tracking": productTracking,
    "fecha_vencimiento": fechaVencimiento,
    "dias_vencimiento": diasVencimiento,
    "other_barcodes": otherBarcodes == null
        ? []
        : List<dynamic>.from(otherBarcodes!.map((x) => x.toMap())),
    "product_packing": productPacking == null
        ? []
        : List<dynamic>.from(productPacking!.map((x) => x)),
    "quantity_ordered": quantityOrdered,
    "quantity_to_receive": quantityToReceive,
    "quantity_done": quantityDone,
    "uom": uom,
    "location_dest_id": locationDestId,
    "location_dest_name": locationDestName,
    "location_dest_barcode": locationBarcode,
    "location_id": locationId,
    "location_name": locationName,
    "location_barcode": locationBarcode,
    "weight": weight,
    "lote_id": loteId,
    "lot_name": lotName,
    "lote_date": loteDate,
    "product_is_ok": productIsOk,
    "is_quantity_is_ok": isQuantityIsOk,
    "quantity_separate": quantitySeparate,
    "is_selected": isSelected,
    "is_separate": isSeparate,
    "is_product_split": isProductSplit,
    "observation": observation,
    "date_separate": dateSeparate,
    "date_start": dateStart,
    "date_end": dateEnd,
    "time": time,
    "is_done_item": isDoneItem,
    "date_transaction": dateTransaction,
    "is_principal_item": isPrincipalItem,
    "cantidad_faltante": cantidadFaltante,
    "type": type,
    "maneja_temperatura": manejaTemperatura,
    "temperatura": temperatura,
    "image": image,
    "image_novedad": imageNovedad,
    "use_expiration_date": useExpirationDate,
    "maneja_segunda_unidad": manejaSegundaUnidad,
    "uom_segunda_unidad": uomSegundaUnidad,
    "quantity_segunda_unidad": quantitySegundaUnidad,
  };
}
