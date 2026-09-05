import 'dart:convert';
import 'package:wms_app/src/presentation/views/transferencias/models/response_transferencias.dart';

class ResponseDeleteLine {
    final String? jsonrpc;
    final dynamic id;
    final ResponseDeleteLineResult? result;

    ResponseDeleteLine({
        this.jsonrpc,
        this.id,
        this.result,
    });

    factory ResponseDeleteLine.fromJson(String str) => ResponseDeleteLine.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory ResponseDeleteLine.fromMap(Map<String, dynamic> json) => ResponseDeleteLine(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null ? null : ResponseDeleteLineResult.fromMap(json["result"]),
    );

    Map<String, dynamic> toMap() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "result": result?.toMap(),
    };
}

class ResponseDeleteLineResult {
    final int? code;
    final String? msg;
    final ResultResult? result;

    ResponseDeleteLineResult({
        this.code,
        this.msg,
        this.result,
    });

    factory ResponseDeleteLineResult.fromJson(String str) => ResponseDeleteLineResult.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory ResponseDeleteLineResult.fromMap(Map<String, dynamic> json) => ResponseDeleteLineResult(
        code: json["code"],
        msg: json["msg"],
        result: json["result"] == null ? null : ResultResult.fromMap(json["result"]),
    );

    Map<String, dynamic> toMap() => {
        "code": code,
        "msg": msg,
        "result": result?.toMap(),
    };
}

class ResultResult {
    final int? id;
    final int? idMove;
    final int? idTransferencia;
    final int? productId;
    final String? productName;
    final String? productCode;
    final dynamic productBarcode;
    final String? ordenName;
    final String? productTracking;
    final dynamic diasVencimiento;
    final String? fechaVencimiento;
    final int? locationDestId;
    final String? locationDestName;
    final String? locationDestBarcode;
    final int? locationId;
    final String? locationName;
    final String? locationBarcode;
    final dynamic quantityOrdered;
    final dynamic quantityToTransfer;
    final dynamic cantidadFaltante;
    final dynamic cantidadDemandada;
    final String? uom;
    final double? weight;
    final dynamic lotId;
    final String? lotName;
    final dynamic observation;
    final dynamic time;
    final dynamic manejaSegundaUnidad;
    final String? uomSegundaUnidad;

    ResultResult({
        this.id,
        this.idMove,
        this.idTransferencia,
        this.productId,
        this.productName,
        this.productCode,
        this.productBarcode,
        this.ordenName,
        this.productTracking,
        this.diasVencimiento,
        this.fechaVencimiento,
        this.locationDestId,
        this.locationDestName,
        this.locationDestBarcode,
        this.locationId,
        this.locationName,
        this.locationBarcode,
        this.quantityOrdered,
        this.quantityToTransfer,
        this.cantidadFaltante,
        this.cantidadDemandada,
        this.uom,
        this.weight,
        this.lotId,
        this.lotName,
        this.observation,
        this.time,
        this.manejaSegundaUnidad,
        this.uomSegundaUnidad,
    });

    factory ResultResult.fromJson(String str) => ResultResult.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory ResultResult.fromMap(Map<String, dynamic> json) => ResultResult(
        id: json["id"],
        idMove: json["id_move"],
        idTransferencia: json["id_transferencia"],
        productId: json["product_id"],
        productName: json["product_name"],
        productCode: json["product_code"],
        productBarcode: json["product_barcode"],
        ordenName: json["orden_name"],
        productTracking: json["product_tracking"],
        diasVencimiento: json["dias_vencimiento"],
        fechaVencimiento: json["fecha_vencimiento"],
        locationDestId: json["location_dest_id"],
        locationDestName: json["location_dest_name"],
        locationDestBarcode: json["location_dest_barcode"],
        locationId: json["location_id"],
        locationName: json["location_name"],
        locationBarcode: json["location_barcode"],
        quantityOrdered: json["quantity_ordered"],
        quantityToTransfer: json["quantity_to_transfer"],
        cantidadFaltante: json["cantidad_faltante"],
        cantidadDemandada: json["cantidad_demandada"],
        uom: json["uom"],
        weight: (json["weight"] as num?)?.toDouble(),
        lotId: json["lot_id"],
        lotName: json["lot_name"],
        observation: json["observation"],
        time: json["time"],
        manejaSegundaUnidad: json["maneja_segunda_unidad"],
        uomSegundaUnidad: json["uom_segunda_unidad"],
    );

    Map<String, dynamic> toMap() => {
        "id": id,
        "id_move": idMove,
        "id_transferencia": idTransferencia,
        "product_id": productId,
        "product_name": productName,
        "product_code": productCode,
        "product_barcode": productBarcode,
        "orden_name": ordenName,
        "product_tracking": productTracking,
        "dias_vencimiento": diasVencimiento,
        "fecha_vencimiento": fechaVencimiento,
        "location_dest_id": locationDestId,
        "location_dest_name": locationDestName,
        "location_dest_barcode": locationDestBarcode,
        "location_id": locationId,
        "location_name": locationName,
        "location_barcode": locationBarcode,
        "quantity_ordered": quantityOrdered,
        "quantity_to_transfer": quantityToTransfer,
        "cantidad_faltante": cantidadFaltante,
        "cantidad_demandada": cantidadDemandada,
        "uom": uom,
        "weight": weight,
        "lot_id": lotId,
        "lot_name": lotName,
        "observation": observation,
        "time": time,
        "maneja_segunda_unidad": manejaSegundaUnidad,
        "uom_segunda_unidad": uomSegundaUnidad,
    };

    // La línea "por hacer" ya viene completamente resuelta (y fusionada,
    // si aplicaba) desde el backend. `type` no viaja en esta respuesta
    // porque es un dato puramente local (origen del sync), así que se
    // preserva de la fila que se está reemplazando.
    LineasTransferenciaTrans toLineasTransferencia({required String type}) {
        return LineasTransferenciaTrans(
            idMove: idMove,
            idTransferencia: idTransferencia,
            productId: productId,
            productName: productName,
            productCode: productCode,
            productBarcode: productBarcode,
            productTracking: productTracking,
            diasVencimiento: diasVencimiento,
            quantityOrdered: quantityOrdered,
            quantityToTransfer: quantityToTransfer,
            quantityDone: 0,
            uom: uom,
            locationDestId: locationDestId,
            locationDestName: locationDestName,
            locationDestBarcode: locationDestBarcode,
            locationId: locationId,
            locationName: locationName,
            locationBarcode: locationBarcode,
            weight: weight,
            lotId: lotId,
            lotName: lotName,
            fechaVencimiento: fechaVencimiento,
            isLocationIsOk: false,
            productIsOk: false,
            locationDestIsOk: false,
            isQuantityIsOk: false,
            isProductSplit: 0,
            isSeparate: 0,
            isSelected: 0,
            observation: observation ?? "",
            time: 0,
            isDoneItem: 0,
            dateTransaction: "",
            dateStart: "",
            dateEnd: "",
            cantidadFaltante: cantidadFaltante,
            type: type,
            manejaSegundaUnidad: manejaSegundaUnidad ?? 0,
            uomSegundaUnidad: uomSegundaUnidad,
            quantitySegundaUnidad: 0,
        );
    }
}
