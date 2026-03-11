import 'dart:convert';
import '../../domain/entities/picking_batch.dart';
import 'pedido_validate_model.dart';

PickingClusterModel pickingClusterModelFromJson(String str) =>
    PickingClusterModel.fromJson(json.decode(str));

class PickingClusterModel {
  final String? jsonrpc;
  final dynamic id;
  final PickingClusterResultModel? result;

  PickingClusterModel({
    this.jsonrpc,
    this.id,
    this.result,
  });

  factory PickingClusterModel.fromJson(Map<String, dynamic> json) =>
      PickingClusterModel(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null
            ? null
            : PickingClusterResultModel.fromJson(json["result"]),
      );
}

class PickingClusterResultModel {
  final int? code;
  final bool? updateVersion;
  final List<ResultElementModel>? result;

  PickingClusterResultModel({
    this.code,
    this.updateVersion,
    this.result,
  });

  factory PickingClusterResultModel.fromJson(Map<String, dynamic> json) =>
      PickingClusterResultModel(
        code: json["code"],
        updateVersion: json["update_version"],
        result: json["result"] == null
            ? []
            : List<ResultElementModel>.from(
                json["result"]!.map((x) => ResultElementModel.fromJson(x))),
      );
}

class ResultElementModel {
  final int? id;
  final String? name;
  final String? userName;
  final int? userId;
  final String? rol;
  final String? orderBy;
  final String? orderPicking;
  final String? scheduleddate;
  final String? state;
  final String? pickingTypeId;
  final String? observation;
  final bool? isWave;
  final String? muelle;
  final dynamic idMuelle;
  final dynamic idMuellePadre;
  final String? barcodeMuelle;
  final int? countItems;
  final dynamic? totalQuantityItems;
  final int? completedItems;
  final dynamic? progressPercentage;
  final dynamic startTimePick;
  final dynamic endTimePick;
  final int? productSeparateQty;
  final String? zonaEntrega;
  // final List<OriginElement>? origin;
  final List<PedidoValidateModel>? pedidosValidate;
  final List<ListItem>? listItems;

  ResultElementModel({
    this.id,
    this.name,
    this.userName,
    this.userId,
    this.rol,
    this.orderBy,
    this.orderPicking,
    this.scheduleddate,
    this.state,
    this.pickingTypeId,
    this.observation,
    this.isWave,
    this.muelle,
    this.idMuelle,
    this.idMuellePadre,
    this.barcodeMuelle,
    this.countItems,
    this.totalQuantityItems,
    this.completedItems,
    this.progressPercentage,
    this.startTimePick,
    this.endTimePick,
    this.productSeparateQty,
    this.zonaEntrega,
    // this.origin,
    this.pedidosValidate,
    this.listItems,
  });
  factory ResultElementModel.fromJson(Map<String, dynamic> json) =>
      ResultElementModel(
        id: json["id"],
        name: json["name"],
        userName: json["user_name"],
        userId: json["user_id"],
        rol: json["rol"],
        orderBy: json["order_by"],
        orderPicking: json["order_picking"],
        scheduleddate:
            json["scheduleddate"] == false ? "" : json["scheduleddate"],
        state: json["state"],
        pickingTypeId: json["picking_type_id"],
        observation: json["observation"],
        isWave: json["is_wave"],
        muelle: json["muelle"],
        idMuelle: json["id_muelle"],
        idMuellePadre: json["id_muelle_padre"],
        barcodeMuelle: json["barcode_muelle"],
        countItems: json["count_items"],
        totalQuantityItems: json["total_quantity_items"],
        completedItems: json["completed_items"],
        progressPercentage: json["progress_percentage"],
        startTimePick: json["start_time_pick"],
        endTimePick: json["end_time_pick"] == false
            ? ""
            : DateTime.parse(json["end_time_pick"]),
        productSeparateQty: json["product_separate_qty"],
        zonaEntrega: json["zona_entrega"],
        //         json["origin"]!.map((x) => OriginElement.fromJson(x))),
        pedidosValidate: json["pedidos_validate"] == null
            ? []
            : List<PedidoValidateModel>.from(json["pedidos_validate"]!
                .map((x) => PedidoValidateModel.fromJson(x))),
        listItems: json["list_items"] == null
            ? []
            : List<ListItem>.from(
                json["list_items"]!.map((x) => ListItem.fromJson(x))),
      );

  PickingBatch toEntity() {
    return PickingBatch(
      id: id,
      name: name,
      userName: userName,
      userId: userId,
      rol: rol,
      orderBy: orderBy,
      orderPicking: orderPicking,
      scheduledDate: scheduleddate == false ? "" : scheduleddate,
      state: state,
      pickingTypeId: pickingTypeId,
      observation: observation,
      isWave: isWave,
      muelle: muelle,
      idMuelle: idMuelle,
      idMuellePadre: idMuellePadre,
      barcodeMuelle: barcodeMuelle,
      countItems: countItems,
      totalQuantityItems: totalQuantityItems,
      completedItems: completedItems,
      progressPercentage: progressPercentage,
      startTimePick: startTimePick,
      endTimePick: endTimePick,
      productSeparateQty: productSeparateQty,
      zonaEntrega: zonaEntrega,
      pedidosValidate: pedidosValidate?.map((i) => i.toEntity()).toList() ?? [],
      listItems: listItems?.map((i) => i.toEntity()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "user_name": userName,
        "user_id": userId,
        "rol": rol,
        "order_by": orderBy,
        "order_picking": orderPicking,
        "scheduleddate": scheduleddate,
        "state": state,
        "picking_type_id": pickingTypeId,
        "observation": observation,
        "is_wave": isWave,
        "muelle": muelle,
        "id_muelle": idMuelle,
        "id_muelle_padre": idMuellePadre,
        "barcode_muelle": barcodeMuelle,
        "count_items": countItems,
        "total_quantity_items": totalQuantityItems,
        "completed_items": completedItems,
        "progress_percentage": progressPercentage,
        "start_time_pick": startTimePick,
        "end_time_pick": endTimePick,
        "product_separate_qty": productSeparateQty,
        "zona_entrega": zonaEntrega,
        //     : List<dynamic>.from(origin!.map((x) => x.toJson())),
        "pedidos_validate": pedidosValidate == null
            ? []
            : List<dynamic>.from(pedidosValidate!.map((x) => x.toJson())),
        "list_items": listItems == null
            ? []
            : List<dynamic>.from(listItems!.map((x) => x.toJson())),
      };
}

class ListItem {
  final int? batchId;
  final int? idMove;
  final int? pickingId;
  final int? idProduct;
  final String? pedido;
  final int? pedidoId;
  final String? origin;
  final List<dynamic>? productId;
  final int? loteId;
  final List<dynamic>? lotId;
  final String? expireDate;
  final List<dynamic>? locationId;
  final int? rimovalPriority;
  final String? barcodeLocation;
  final List<dynamic>? locationDestId;
  final String? barcodeLocationDest;
  final dynamic? quantity;
  final String? barcode;
  final List<OtherBarcode>? otherBarcodes;
  final List<OtherBarcode>? productPacking;
  final dynamic? weight;
  final String? unidades;
  final String? zonaEntrega;
  final int? idZonaEntrega;
  final dynamic? quantitySeparate;
  final String? observation;
  final String? timeSeparate;
  final String? fechaTransaccion;
  final int? isSeparate;
  final bool? manejaTemperatura;
  final dynamic? temperatura;
  final String? image;
  final String? imageNovedad;
  final String? packageConsecutivo;
  final bool? realizado;
  final String? productTracking;

  ListItem({
    this.batchId,
    this.idMove,
    this.pickingId,
    this.idProduct,
    this.pedido,
    this.pedidoId,
    this.origin,
    this.productId,
    this.loteId,
    this.lotId,
    this.expireDate,
    this.locationId,
    this.rimovalPriority,
    this.barcodeLocation,
    this.locationDestId,
    this.barcodeLocationDest,
    this.quantity,
    this.barcode,
    this.otherBarcodes,
    this.productPacking,
    this.weight,
    this.unidades,
    this.zonaEntrega,
    this.idZonaEntrega,
    this.quantitySeparate,
    this.observation,
    this.timeSeparate,
    this.fechaTransaccion,
    this.isSeparate,
    this.manejaTemperatura,
    this.temperatura,
    this.image,
    this.imageNovedad,
    this.packageConsecutivo,
    this.realizado,
    this.productTracking,
  });

  factory ListItem.fromJson(Map<String, dynamic> json) => ListItem(
        batchId: json["batch_id"],
        idMove: json["id_move"],
        pickingId: json["picking_id"],
        idProduct: json["id_product"],
        pedido: json["pedido"],
        pedidoId: json["pedido_id"],
        origin: json["origin"],
        productId: json["product_id"] == null
            ? []
            : List<dynamic>.from(json["product_id"]!.map((x) => x)),
        loteId: json["lote_id"],
        lotId: json["lot_id"] == null
            ? []
            : List<dynamic>.from(json["lot_id"]!.map((x) => x)),
        expireDate: json["expire_date"],
        locationId: json["location_id"] == null
            ? []
            : List<dynamic>.from(json["location_id"]!.map((x) => x)),
        rimovalPriority: json["rimoval_priority"],
        barcodeLocation: json["barcode_location"],
        locationDestId: json["location_dest_id"] == null
            ? []
            : List<dynamic>.from(json["location_dest_id"]!.map((x) => x)),
        barcodeLocationDest: json["barcode_location_dest"],
        quantity: json["quantity"],
        barcode: json["barcode"],
        otherBarcodes: json["other_barcodes"] == null
            ? []
            : List<OtherBarcode>.from(
                json["other_barcodes"]!.map((x) => OtherBarcode.fromJson(x))),
        productPacking: json["product_packing"] == null
            ? []
            : List<OtherBarcode>.from(
                json["product_packing"]!.map((x) => OtherBarcode.fromJson(x))),
        weight: json["weight"]?.toDouble(),
        unidades: json["unidades"],
        zonaEntrega: json["zona_entrega"],
        idZonaEntrega: json["id_zona_entrega"],
        quantitySeparate: json["quantity_separate"],
        observation: json["observation"],
        timeSeparate: json["time_separate"],
        fechaTransaccion: json["fecha_transaccion"],
        isSeparate: json["is_separate"],
        manejaTemperatura: json["maneja_temperatura"],
        temperatura: json["temperatura"],
        image: json["image"],
        imageNovedad: json["image_novedad"],
        packageConsecutivo: json["package_consecutivo"],
        realizado: json["realizado"],
        productTracking: json["product_tracking"],
      );

  PickingBatchItem toEntity() {
    return PickingBatchItem(
      batchId: batchId,
      idMove: idMove,
      pickingId: pickingId,
      idProduct: idProduct,
      pedido: pedido,
      pedidoId: pedidoId,
      origin: origin,
      productId: productId,
      loteId: loteId,
      lotId: lotId,
      expireDate: expireDate,
      locationId: locationId,
      rimovalPriority: rimovalPriority,
      location: barcodeLocation,
      locationDestId: locationDestId,
      locationDest: barcodeLocationDest,
      quantity: quantity,
      barcode: barcode,
      otherBarcodes: otherBarcodes?.map((o) => o.toEntity()).toList(),
      productPacking: productPacking?.map((o) => o.toEntity()).toList(),
      weight: weight,
      unidades: unidades,
      zonaEntrega: zonaEntrega,
      idZonaEntrega: idZonaEntrega,
      quantitySeparate: quantitySeparate,
      observation: observation,
      timeSeparate: timeSeparate,
      fechaTransaccion: fechaTransaccion,
      isSeparate: isSeparate,
      manejaTemperatura: manejaTemperatura,
      temperatura: temperatura,
      image: image,
      imageNovedad: imageNovedad,
      packageConsecutivo: packageConsecutivo,
      realizado: realizado,
      productTracking: productTracking,
    );
  }

  Map<String, dynamic> toJson() => {
        "batch_id": batchId,
        "id_move": idMove,
        "picking_id": pickingId,
        "id_product": idProduct,
        "pedido": pedido,
        "pedido_id": pedidoId,
        "origin": origin,
        "product_id": productId == null
            ? []
            : List<dynamic>.from(productId!.map((x) => x)),
        "lote_id": loteId,
        "lot_id": lotId == null ? [] : List<dynamic>.from(lotId!.map((x) => x)),
        "expire_date": expireDate,
        "location_id": locationId == null
            ? []
            : List<dynamic>.from(locationId!.map((x) => x)),
        "rimoval_priority": rimovalPriority,
        "barcode_location": barcodeLocation,
        "location_dest_id": locationDestId == null
            ? []
            : List<dynamic>.from(locationDestId!.map((x) => x)),
        "barcode_location_dest": barcodeLocationDest,
        "quantity": quantity,
        "barcode": barcode,
        "other_barcodes": otherBarcodes == null
            ? []
            : List<dynamic>.from(otherBarcodes!.map((x) => x.toJson())),
        "product_packing": productPacking == null
            ? []
            : List<dynamic>.from(productPacking!.map((x) => x.toJson())),
        "weight": weight,
        "unidades": unidades,
        "zona_entrega": zonaEntrega,
        "id_zona_entrega": idZonaEntrega,
        "quantity_separate": quantitySeparate,
        "observation": observation,
        "time_separate": timeSeparate,
        "fecha_transaccion": fechaTransaccion,
        "is_separate": isSeparate,
        "maneja_temperatura": manejaTemperatura,
        "temperatura": temperatura,
        "image": image,
        "image_novedad": imageNovedad,
        "package_consecutivo": packageConsecutivo,
        "realizado": realizado,
      };
}

class OtherBarcode {
  final String? barcode;
  final dynamic? cantidad;
  final int? idProduct;
  final int? idMove;
  final int? batchId;
  final int? productId;

  OtherBarcode({
    this.barcode,
    this.cantidad,
    this.idProduct,
    this.idMove,
    this.batchId,
    this.productId,
  });

  factory OtherBarcode.fromJson(Map<String, dynamic> json) => OtherBarcode(
        barcode: json["barcode"],
        cantidad: json["cantidad"],
        idProduct: json["id_product"],
        idMove: json["id_move"],
        batchId: json["batch_id"],
        productId: json["product_id"],
      );

  PickingOtherBarcode toEntity() {
    return PickingOtherBarcode(
      barcode: barcode,
      cantidad: cantidad,
      idProduct: idProduct,
      idMove: idMove,
      batchId: batchId,
      productId: productId,
    );
  }

  Map<String, dynamic> toJson() => {
        "barcode": barcode,
        "cantidad": cantidad,
        "id_product": idProduct,
        "id_move": idMove,
        "batch_id": batchId,
        "product_id": productId,
      };
}
