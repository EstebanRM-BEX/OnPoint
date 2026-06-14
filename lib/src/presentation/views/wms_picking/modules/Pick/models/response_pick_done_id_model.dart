import 'dart:convert';

class RespondePickDoneId {
  final String? jsonrpc;
  final dynamic id;
  final RespondePickDoneIdResult? result;

  RespondePickDoneId({
    this.jsonrpc,
    this.id,
    this.result,
  });

  factory RespondePickDoneId.fromJson(String str) =>
      RespondePickDoneId.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RespondePickDoneId.fromMap(Map<String, dynamic> json) =>
      RespondePickDoneId(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null
            ? null
            : RespondePickDoneIdResult.fromMap(json["result"]),
      );

  Map<String, dynamic> toMap() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "result": result?.toMap(),
      };
}

class RespondePickDoneIdResult {
  final int? code;
  final ResultResult? result;

  RespondePickDoneIdResult({
    this.code,
    this.result,
  });

  factory RespondePickDoneIdResult.fromJson(String str) =>
      RespondePickDoneIdResult.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RespondePickDoneIdResult.fromMap(Map<String, dynamic> json) =>
      RespondePickDoneIdResult(
        code: json["code"],
        result: json["result"] == null
            ? null
            : ResultResult.fromMap(json["result"]),
      );

  Map<String, dynamic> toMap() => {
        "code": code,
        "result": result?.toMap(),
      };
}

class ResultResult {
  final int? id;
  final String? name;
  final dynamic fechaCreacion;
  final int? locationId;
  final String? locationName;
  final String? locationBarcode;
  final int? locationDestId;
  final String? locationDestName;
  final String? locationDestBarcode;
  final String? proveedor;
  final String? numeroTransferencia;
  final dynamic pesoTotal;
  final dynamic numeroItems;
  final String? state;
  final String? createBackorder;
  final String? origin;
  final String? priority;
  final int? warehouseId;
  final String? warehouseName;
  final int? responsableId;
  final String? responsable;
  final String? pickingType;
  final dynamic startTimeTransfer;
  final dynamic endTimeTransfer;
  final int? backorderId;
  final String? backorderName;
  final bool? showCheckAvailability;
  final String? orderBy;
  final String? orderPicking;
  final String? muelle;
  final int? muelleId;
  final int? idMuellePadre;
  final String? barcodeMuelle;
  final String? zonaEntrega;

  final dynamic quantityDone;
  final dynamic quantityOrdered;

  final List<LineasTransferenciaEnviada>? lineasTransferencia;
  final List<LineasTransferenciaEnviada>? lineasTransferenciaEnviadas;
  final dynamic numeroLineas;

  ResultResult({
    this.id,
    this.name,
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
    this.numeroItems,
    this.state,
    this.createBackorder,
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
    this.orderBy,
    this.orderPicking,
    this.muelle,
    this.muelleId,
    this.idMuellePadre,
    this.barcodeMuelle,
    this.zonaEntrega,
    this.lineasTransferencia,
    this.lineasTransferenciaEnviadas,
    this.numeroLineas,
    this.quantityDone,
    this.quantityOrdered,
  });

  factory ResultResult.fromJson(String str) =>
      ResultResult.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ResultResult.fromMap(Map<String, dynamic> json) => ResultResult(
        id: json["id"],
        name: json["name"],
        fechaCreacion: json["fecha_creacion"] != null
            ? DateTime.tryParse(json["fecha_creacion"])
            : null,
        locationId: json["location_id"],
        locationName: json["location_name"],
        locationBarcode: json["location_barcode"],
        locationDestId: json["location_dest_id"],
        locationDestName: json["location_dest_name"],
        locationDestBarcode: json["location_dest_barcode"],
        proveedor: json["proveedor"],
        numeroTransferencia: json["numero_transferencia"],
        pesoTotal: json["peso_total"],
        numeroItems: json["numero_items"],
        state: json["state"],
        createBackorder: json["create_backorder"],
        origin: json["origin"],
        priority: json["priority"],
        warehouseId: json["warehouse_id"],
        warehouseName: json["warehouse_name"],
        responsableId: json["responsable_id"],
        responsable: json["responsable"],
        pickingType: json["picking_type"],
        startTimeTransfer: json["start_time_transfer"] != null
            ? DateTime.tryParse(json["start_time_transfer"])
            : null,
        // ✅ Conversión de fechas:
        endTimeTransfer: json["end_time_transfer"] != null
            ? DateTime.tryParse(json["end_time_transfer"])
            : null,

        backorderId: json["backorder_id"],
        backorderName: json["backorder_name"],
        showCheckAvailability: json["show_check_availability"],
        orderBy: json["order_by"],
        orderPicking: json["order_picking"],
        muelle: json["muelle"],
        muelleId: json["muelle_id"],
        idMuellePadre: json["id_muelle_padre"],
        barcodeMuelle: json["barcode_muelle"],
        zonaEntrega: json["zona_entrega"],
        lineasTransferencia: json["lineas_transferencia"] == null
            ? []
            : List<LineasTransferenciaEnviada>.from(
                json["lineas_transferencia"]!
                    .map((x) => LineasTransferenciaEnviada.fromMap(x))),
        lineasTransferenciaEnviadas:
            json["lineas_transferencia_enviadas"] == null
                ? []
                : List<LineasTransferenciaEnviada>.from(
                    json["lineas_transferencia_enviadas"]!
                        .map((x) => LineasTransferenciaEnviada.fromMap(x))),
        numeroLineas: json["numero_lineas"],
        quantityDone: json["quantity_done"],
        quantityOrdered: json["quantity_ordered"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
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
        "numero_items": numeroItems,
        "state": state,
        "create_backorder": createBackorder,
        "origin": origin,
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
        "order_by": orderBy,
        "order_picking": orderPicking,
        "muelle": muelle,
        "muelle_id": muelleId,
        "id_muelle_padre": idMuellePadre,
        "barcode_muelle": barcodeMuelle,
        "zona_entrega": zonaEntrega,
        "lineas_transferencia": lineasTransferencia == null
            ? []
            : List<dynamic>.from(lineasTransferencia!.map((x) => x.toMap())),
        "lineas_transferencia_enviadas": lineasTransferenciaEnviadas == null
            ? []
            : List<dynamic>.from(
                lineasTransferenciaEnviadas!.map((x) => x.toMap())),
        "numero_lineas": numeroLineas,
        "quantity_done": quantityDone,
        "quantity_ordered": quantityOrdered,
      };
}

class LineasTransferenciaEnviada {
  final int? id;
  final int? idMove;
  final int? idTransferencia;
  final int? batchId;
  final int? idProduct;
  final List<dynamic>? productId;
  final String? productName;
  final String? productCode;
  final String? barcode;
  final String? productTracking;
  final String? diasVencimiento;
  final List<dynamic>? otherBarcodes;
  final List<ProductPacking>? productPacking;
  final dynamic quantity;
  final dynamic quantityToTransfer;
  final dynamic quantityDone;
  final dynamic cantidadFaltante;
  final String? unidades;
  final List<dynamic>? locationDestId;
  final String? locationDestName;
  final String? barcodeLocationDest;
  final List<dynamic>? locationId;
  final String? locationName;
  final String? barcodeLocation;
  final dynamic weight;
  final int? rimovalPriority;
  final String? zonaEntrega;
  final List<dynamic>? otherBarcode;
  final String? pedido;
  final int? pedidoId;
  final String? origin;
  final int? loteId;
  final String? lote;
  final dynamic quantitySeparate;
  final bool? isDoneItem;
  final dynamic dateTransaction;
  final String? observation;
  final String? timeSeparate;
  final dynamic time;
  final int? userOperatorId;
  final String? expireDate;
  final int? isSeparate;

  LineasTransferenciaEnviada({
    this.id,
    this.idMove,
    this.idTransferencia,
    this.batchId,
    this.idProduct,
    this.productId,
    this.productName,
    this.productCode,
    this.barcode,
    this.productTracking,
    this.diasVencimiento,
    this.otherBarcodes,
    this.productPacking,
    this.quantity,
    this.quantityToTransfer,
    this.quantityDone,
    this.cantidadFaltante,
    this.unidades,
    this.locationDestId,
    this.locationDestName,
    this.barcodeLocationDest,
    this.locationId,
    this.locationName,
    this.barcodeLocation,
    this.weight,
    this.rimovalPriority,
    this.zonaEntrega,
    this.otherBarcode,
    this.pedido,
    this.pedidoId,
    this.origin,
    this.loteId,
    this.lote,
    this.quantitySeparate,
    this.isDoneItem,
    this.dateTransaction,
    this.observation,
    this.timeSeparate,
    this.time,
    this.userOperatorId,
    this.expireDate,
    this.isSeparate,
  });

  factory LineasTransferenciaEnviada.fromJson(String str) =>
      LineasTransferenciaEnviada.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory LineasTransferenciaEnviada.fromMap(Map<String, dynamic> json) =>
      LineasTransferenciaEnviada(
        id: json["id"],
        idMove: json["id_move"],
        idTransferencia: json["id_transferencia"],
        batchId: json["batch_id"],
        idProduct: json["id_product"],
        productId: json["product_id"] == null
            ? []
            : List<dynamic>.from(json["product_id"]!.map((x) => x)),
        productName: json["product_name"],
        productCode: json["product_code"],
        barcode: json["barcode"],
        productTracking: json["product_tracking"],
        diasVencimiento: json["dias_vencimiento"],
        otherBarcodes: json["other_barcodes"] == null
            ? []
            : List<dynamic>.from(json["other_barcodes"]!.map((x) => x)),
        productPacking: json["product_packing"] == null
            ? []
            : List<ProductPacking>.from(
                json["product_packing"]!.map((x) => ProductPacking.fromMap(x))),
        quantity: json["quantity"],
        quantityToTransfer: json["quantity_to_transfer"],
        quantityDone: json["quantity_done"],
        cantidadFaltante: json["cantidad_faltante"],
        unidades: json["unidades"],
        locationDestId: json["location_dest_id"] == null
            ? []
            : List<dynamic>.from(json["location_dest_id"]!.map((x) => x)),
        locationDestName: json["location_dest_name"],
        barcodeLocationDest: json["barcode_location_dest"],
        locationId: json["location_id"] == null
            ? []
            : List<dynamic>.from(json["location_id"]!.map((x) => x)),
        locationName: json["location_name"],
        barcodeLocation: json["barcode_location"],
        weight: json["weight"],
        rimovalPriority: json["rimoval_priority"],
        zonaEntrega: json["zona_entrega"],
        otherBarcode: json["other_barcode"] == null
            ? []
            : List<dynamic>.from(json["other_barcode"]!.map((x) => x)),
        pedido: json["pedido"],
        pedidoId: json["pedido_id"],
        origin: json["origin"],
        loteId: json["lote_id"],
        lote: json["lote"],
        quantitySeparate: json["quantity_separate"],
        isDoneItem: json["is_done_item"],
        dateTransaction: json["date_transaction"] != null
            ? DateTime.tryParse(json["date_transaction"])
            : null,
        observation: json["observation"],
        timeSeparate: json["time_separate"],
        time: json["time"],
        userOperatorId: json["user_operator_id"],
        expireDate: json["expire_date"],
        isSeparate: json["is_separate"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "id_move": idMove,
        "id_transferencia": idTransferencia,
        "batch_id": batchId,
        "id_product": idProduct,
        "product_id": productId == null
            ? []
            : List<dynamic>.from(productId!.map((x) => x)),
        "product_name": productName,
        "product_code": productCode,
        "barcode": barcode,
        "product_tracking": productTracking,
        "dias_vencimiento": diasVencimiento,
        "other_barcodes": otherBarcodes == null
            ? []
            : List<dynamic>.from(otherBarcodes!.map((x) => x)),
        "product_packing": productPacking == null
            ? []
            : List<dynamic>.from(productPacking!.map((x) => x.toMap())),
        "quantity": quantity,
        "quantity_to_transfer": quantityToTransfer,
        "quantity_done": quantityDone,
        "cantidad_faltante": cantidadFaltante,
        "unidades": unidades,
        "location_dest_id": locationDestId == null
            ? []
            : List<dynamic>.from(locationDestId!.map((x) => x)),
        "location_dest_name": locationDestName,
        "barcode_location_dest": barcodeLocationDest,
        "location_id": locationId == null
            ? []
            : List<dynamic>.from(locationId!.map((x) => x)),
        "location_name": locationName,
        "barcode_location": barcodeLocation,
        "weight": weight,
        "rimoval_priority": rimovalPriority,
        "zona_entrega": zonaEntrega,
        "other_barcode": otherBarcode == null
            ? []
            : List<dynamic>.from(otherBarcode!.map((x) => x)),
        "pedido": pedido,
        "pedido_id": pedidoId,
        "origin": origin,
        "lote_id": loteId,
        "lote": lote,
        "quantity_separate": quantitySeparate,
        "is_done_item": isDoneItem,
        "date_transaction": dateTransaction?.toIso8601String(),
        "observation": observation,
        "time_separate": timeSeparate,
        "time": time,
        "user_operator_id": userOperatorId,
        "expire_date": expireDate,
        "is_separate": isSeparate,
      };
}

class ProductPacking {
  final String? barcode;
  final dynamic cantidad;
  final int? idProduct;
  final int? idMove;
  final int? batchId;
  final int? productId;

  ProductPacking({
    this.barcode,
    this.cantidad,
    this.idProduct,
    this.idMove,
    this.batchId,
    this.productId,
  });

  factory ProductPacking.fromJson(String str) =>
      ProductPacking.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ProductPacking.fromMap(Map<String, dynamic> json) => ProductPacking(
        barcode: json["barcode"],
        cantidad: json["cantidad"],
        idProduct: json["id_product"],
        idMove: json["id_move"],
        batchId: json["batch_id"],
        productId: json["product_id"],
      );

  Map<String, dynamic> toMap() => {
        "barcode": barcode,
        "cantidad": cantidad,
        "id_product": idProduct,
        "id_move": idMove,
        "batch_id": batchId,
        "product_id": productId,
      };
}
