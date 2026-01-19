// ignore_for_file: unnecessary_question_mark

import 'dart:convert';

class BatchModelResponse {
  final String? jsonrpc;
  final dynamic id;
  final DataBatch? result;

  BatchModelResponse({
    this.jsonrpc,
    this.id,
    this.result,
  });

  factory BatchModelResponse.fromJson(String str) =>
      BatchModelResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory BatchModelResponse.fromMap(Map<String, dynamic> json) =>
      BatchModelResponse(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result:
            json["result"] == null ? null : DataBatch.fromMap(json["result"]),
      );

  Map<String, dynamic> toMap() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "result": result?.toMap(),
      };
}

class DataBatch {
  final int? code;
  final String? msg;
  final bool? updateVersion;
  final List<BatchsModel>? result;

  DataBatch({
    this.code,
    this.msg,
    this.updateVersion,
    this.result,
  });

  factory DataBatch.fromJson(String str) => DataBatch.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory DataBatch.fromMap(Map<String, dynamic> json) => DataBatch(
        code: json["code"],
        msg: json["msg"],
        updateVersion: json["update_version"],
        result: json["result"] == null
            ? []
            : List<BatchsModel>.from(
                json["result"]!.map((x) => BatchsModel.fromMap(x))),
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

class BatchsModel {
  final int? id;
  final String? name;
  final String? type;
  final dynamic scheduleddate;
  final dynamic pickingTypeId;
  final String? muelle; 
  final String? barcodeMuelle;
  final dynamic? idMuelle;
  final dynamic? idMuellePadre; // Nuevo campo para el ID del muelle padre
  final String? state;
  final dynamic userId;
  final String? userName;
  final int? countItems;
  final dynamic? totalQuantityItems;

  final int? indexList;
  final dynamic isWave;
  final int? isSeparate;
  final dynamic isSelected;
  final int? productSeparateQty; //cantidad que se lleva separada

  final double? timeSeparateTotal;

  final String? isSendOdoo;
  final String? isSendOdooDate;
  final String? observation;

  final dynamic orderBy;
  final dynamic orderPicking;


  final dynamic startTimePick;
  final dynamic endTimePick;
  final String? zonaEntrega;
  final List<Origin>? origin;

  List<ProductsBatch>? listItems;

  BatchsModel({
    this.id,
    this.name,
    this.type,
    this.scheduleddate,
    this.pickingTypeId,
    this.muelle,
    this.barcodeMuelle,
    this.idMuelle,
    this.idMuellePadre,
    this.state,
    this.userId,
    this.userName,
    this.countItems,
    this.totalQuantityItems,
    this.indexList,
    this.isWave,
    this.isSeparate,
    this.isSelected,
    this.productSeparateQty,
    this.timeSeparateTotal,
    this.isSendOdoo,
    this.isSendOdooDate,
    this.observation,
    this.listItems,
    this.orderBy,
    this.orderPicking,
    this.startTimePick,
    this.endTimePick,
    this.zonaEntrega,
    this.origin,
  });

  factory BatchsModel.fromJson(String str) =>
      BatchsModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory BatchsModel.fromMap(Map<String, dynamic> json) => BatchsModel(
        id: json['id'],
        name: json['name'].toString(),
        type: json['type'],
        scheduleddate: json["scheduleddate"],
        pickingTypeId: json['picking_type_id'],
        muelle: json['muelle'],
        barcodeMuelle: json['barcode_muelle'],
        idMuelle: json['id_muelle'],
        idMuellePadre: json['id_muelle_padre'], // Nuevo campo
        state: json['state'],
        userId: json['user_id'],
        userName: json['user_name'],
        countItems: json['count_items'],
        totalQuantityItems: json['total_quantity_items'],
        indexList: json['index_list'],
        isWave: json['is_wave'],
        isSeparate: json['is_separate'],
        isSelected: json['is_selected'],
        productSeparateQty: json['product_separate_qty'],
        timeSeparateTotal: json['time_separate_total'],
        isSendOdoo: json['is_send_oddo'],
        isSendOdooDate: json['is_send_oddo_date'],
        observation: json['observation'],
        listItems: json["list_items"] == null
            ? []
            : List<ProductsBatch>.from(
                json["list_items"]!.map((x) => ProductsBatch.fromMap(x))),
        orderBy: json["order_by"],
        orderPicking: json["order_picking"],
        startTimePick: json["start_time_pick"],
        endTimePick: json["end_time_pick"],
        zonaEntrega: json["zona_entrega"],
        origin: json["origin"] == null
            ? []
            : List<Origin>.from(
                json["origin"]!.map((x) => Origin.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'scheduleddate': scheduleddate,
        'picking_type_id': pickingTypeId,
        'muelle': muelle,
        'barcode_muelle': barcodeMuelle,
        'id_muelle': idMuelle,
        'id_muelle_padre': idMuellePadre, // Nuevo campo
        'state': state,
        'user_id': userId,
        'user_name': userName,
        'count_items': countItems,
        'total_quantity_items': totalQuantityItems,
        'index_list': indexList,
        'is_wave': isWave,
        'is_separate': isSeparate,
        'is_selected': isSelected,
        'product_separate_qty': productSeparateQty,
        'time_separate_total': timeSeparateTotal,
        'is_send_oddo': isSendOdoo,
        'is_send_oddo_date': isSendOdooDate,
        'observation': observation,
        'list_items': listItems == null
            ? []
            : List<dynamic>.from(listItems!.map((x) => x.toMap())),
        'order_by': orderBy,
        'order_picking': orderPicking,
        'start_time_pick': startTimePick,
        'end_time_pick': endTimePick,
        'zona_entrega': zonaEntrega,
        'origin': origin == null
            ? []
            : List<dynamic>.from(origin!.map((x) => x.toMap())),
      };
}


class Origin{

  final int? id;
  final String? name;
  final int? idBatch;


  Origin({
    this.id,
    this.name,
    this.idBatch,
  });

  factory Origin.fromJson(String str) => Origin.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());
  factory Origin.fromMap(Map<String, dynamic> json) => Origin(
    id: json['id'],
    name: json['name'],
    idBatch: json['id_batch'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'id_batch': idBatch,
  };


}

class ProductsBatch {
  final int? id;
  final dynamic barcode;
  final String? type;
  final dynamic? weigth;
  final String? unidades;

  final int? idMove;

  final int? idProduct;
  final int? orderProduct;
  final dynamic productId;
  final dynamic? batchId;
  final String? name;
  final dynamic? rimovalPriority;
  
  final dynamic lotId;
  final dynamic loteId;
  final dynamic lote;
  final dynamic locationId;
  final int? muelleId;
  final dynamic locationDestId;
  final dynamic idLocationDest;
  final dynamic quantity; // Cambiado a double
  final List<Barcodes>? productPacking;
  final List<Barcodes>? otherBarcode;
  final String? productTracking;

  final dynamic barcodeLocation;
  final dynamic barcodeLocationDest;

  final int? isMuelle;

  final dynamic? quantitySeparate;
  final dynamic isSelected;
  final int? isSeparate;
  final dynamic timeSeparate;
  final String? timeSeparateStart;
  final String? timeSeparateEnd;
  final String? observation;
  final int? isSendOdoo;
  final int? isPending;
  final String? isSendOdooDate;
  final dynamic? weight;
  final dynamic expireDate;
  final dynamic origin;
  final String? typePick;

  // Variables para el picking
  late dynamic
      isLocationIsOk; // Variable para si la ubicación es leída correctamente
  late dynamic
      productIsOk; // Variable para si el producto es leído correctamente
  late dynamic
      locationDestIsOk; // Variable para si la ubicación destino está leída
  late dynamic
      isQuantityIsOk; // Variable para si la cantidad es leída correctamente
  final String? fechaTransaccion;

  final dynamic productCode;

  ProductsBatch({
    this.id,
    this.batchId,
    this.idMove,
    this.rimovalPriority,
    this.muelleId,
    this.type,
    this.expireDate,
    // this.pickingId,
    this.orderProduct,
    this.origin,

    this.productTracking,

    
    this.barcodeLocation,
    this.idProduct,
    this.productId,
    this.lotId,
    this.isMuelle,
    this.loteId,
    this.lote,
    this.locationId,
    this.locationDestId,
    this.idLocationDest,
    this.barcodeLocationDest,
    this.quantity,
    this.productPacking,
    this.barcode,
    this.isPending,



    this.name,
    this.weigth,
    this.unidades,
    this.quantitySeparate,
    this.isSelected,
    this.isSeparate,
    this.timeSeparate,
    this.timeSeparateStart,
    this.timeSeparateEnd,
    this.observation,
    this.isLocationIsOk,
    this.productIsOk,
    this.locationDestIsOk,
    this.isQuantityIsOk,
    this.isSendOdoo,
    this.isSendOdooDate,
    this.weight,
    this.otherBarcode,
    this.fechaTransaccion,
    this.typePick,
    this.productCode,
  });

  factory ProductsBatch.fromMap(Map<String, dynamic> map) {
    return ProductsBatch(
      id: map['id'],
      rimovalPriority: map['rimoval_priority'],
      expireDate: map['expire_date'],
      batchId: map['batch_id'],
      type: map['type'] ,
      orderProduct: map['order_product'],
      idProduct: map['id_product'],
      productId: map['product_id'],
      origin: map['origin'],
      muelleId: map['muelle_id'],
      idMove: map['id_move'],

      productTracking: map['product_tracking'],

      barcodeLocation: map['barcode_location'],
      barcodeLocationDest: map['barcode_location_dest'],
      lotId: map['lot_id'],
      loteId: map['lote_id'],
      lote: map['lote'],
      productPacking: map['product_packing'] == null
          ? []
          : List<Barcodes>.from(
              map['product_packing'].map((x) => Barcodes.fromMap(x))),
      otherBarcode: map['other_barcode'] == null
          ? []
          : List<Barcodes>.from(
              map['other_barcode'].map((x) => Barcodes.fromMap(x))),
      locationId: map['location_id'],
      locationDestId: map['location_dest_id'],
      idLocationDest: map['id_location_dest'],
      quantity: map['quantity'],
      barcode: map['barcode'],
      name: map['name'],
      weigth: map['weigth'],
      unidades: map['unidades'],
      quantitySeparate: map['quantity_separate'],
      isSelected: map['is_selected'],
      isSeparate: map['is_separate'],
      isPending: map['is_pending'],
      timeSeparate: map['time_separate'],
      timeSeparateStart: map['time_separate_start'],
      timeSeparateEnd: map['time_separate_end'],
      observation: map['observation'],
      isMuelle: map['is_muelle'],

      isLocationIsOk: map["is_location_is_ok"] ?? false,
      productIsOk: map["product_is_ok"] ?? false,
      locationDestIsOk: map["location_dest_is_ok"] ?? false,
      isQuantityIsOk: map["is_quantity_is_ok"] ?? false,
      isSendOdoo: map['is_send_odoo'],
      isSendOdooDate: map['is_send_odoo_date'],
      weight: map['weight'],
      fechaTransaccion: map['fecha_transaccion'],
      typePick: map['type_pick'],
      productCode: map['product_code'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "expire_date": expireDate,
      "rimoval_priority": rimovalPriority,
      "id_product": idProduct,
      "type": type,
      "batch_id": batchId,
      "id_move": idMove,
      "muelle_id": muelleId,
      "origin": origin,

      "product_tracking": productTracking,

      "order_product": orderProduct,
      "barcode_location_dest": barcodeLocation,
      // "picking_id": pickingId,
      "product_id": productId,
      "lot_id": lotId,
      "lote_id": loteId,
      "lote": lote,
      "location_id": locationId,
      "location_dest_id": locationDestId,
      "id_location_dest": idLocationDest,
      "quantity": quantity,
      "product_packing": productPacking == null
          ? []
          : List<dynamic>.from(productPacking!.map((x) => x.toMap())),
      "other_barcode": otherBarcode == null
          ? []
          : List<dynamic>.from(otherBarcode!.map((x) => x.toMap())),
      "barcode": barcode,
      "name": name,
      "weigth": weigth,
      "barcode_location": barcodeLocation,
      "unidades": unidades,
      "quantity_separate": quantitySeparate,
      "is_selected": isSelected,
      'is_muelle': isMuelle,
      "is_pending": isPending,
      "is_separate": isSeparate,
      "time_separate": timeSeparate,
      "time_separate_start": timeSeparateStart,
      "time_separate_end": timeSeparateEnd,
      "observation": observation,
      "is_location_is_ok": isLocationIsOk,
      "product_is_ok": productIsOk,
      "location_dest_is_ok": locationDestIsOk,
      "is_quantity_is_ok": isQuantityIsOk,
      "is_send_odoo": isSendOdoo,
      "is_send_odoo_date": isSendOdooDate,
      "weight": weight,
      "fecha_transaccion": fechaTransaccion,
      "type_pick": typePick,
      "product_code": productCode,
    };
  }
}

class Barcodes {
  final int? batchId;
  final int? idMove;
  final int? idProduct;
  final dynamic barcode;
  final dynamic cantidad;
  final String? barcodeType;

  Barcodes({
    this.batchId,
    this.idMove,
    this.idProduct,
    this.barcode,
    this.cantidad,
    this.barcodeType,
  });

  factory Barcodes.fromJson(String str) => Barcodes.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Barcodes.fromMap(Map<String, dynamic> json) => Barcodes(
        batchId: json["batch_id"],
        idMove: json["id_move"],
        idProduct: json["id_product"],
        barcode: json["barcode"],
        cantidad: json["cantidad"],
        barcodeType: json["barcode_type"],
      );

  Map<String, dynamic> toMap() => {
        "batch_id": batchId,
        "id_move": idMove,
        "id_product": idProduct,
        "barcode": barcode,
        "cantidad": cantidad,
        "barcode_type": barcodeType,
      };
}
