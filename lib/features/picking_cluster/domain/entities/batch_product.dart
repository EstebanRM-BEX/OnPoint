import 'package:equatable/equatable.dart';

/// Entidad de dominio que representa un producto dentro de un batch de picking.
/// Equivalente limpio de [ProductsBatch] del módulo wms_picking, propio de la
/// feature picking_cluster.
class BatchProduct extends Equatable {
  final int? id;
  final dynamic barcode;
  final String? type;
  final dynamic weight;
  final String? unidades;
  final int? idMove;
  final int? idProduct;
  final int? orderProduct;
  final dynamic productId;
  final dynamic pedido;
  final int? pedidoId;
  final dynamic batchId;
  final String? name;
  final dynamic removalPriority;
  final dynamic lotId;
  final dynamic loteId;
  final dynamic lote;
  final dynamic locationId;
  final int? muelleId;
  final dynamic locationDestId;
  final dynamic idLocationDest;
  final dynamic quantity;
  final List<BatchBarcode>? productPacking;
  final List<BatchBarcode>? otherBarcode;
  final String? productTracking;
  final dynamic barcodeLocation;
  final dynamic barcodeLocationDest;
  final int? isMuelle;
  final dynamic quantitySeparate;
  final dynamic isSelected;
  final int? isSeparate;
  final dynamic timeSeparate;
  final String? timeSeparateStart;
  final String? timeSeparateEnd;
  final String? observation;
  final int? isSendOdoo;
  final int? isPending;
  final String? isSendOdooDate;
  final dynamic expireDate;
  final dynamic origin;
  final String? typePick;
  final String? fechaTransaccion;
  final dynamic productCode;

  // Estado de validación del proceso de picking (mutable en runtime)
  final dynamic isLocationIsOk;
  final dynamic productIsOk;
  final dynamic locationDestIsOk;
  final dynamic isQuantityIsOk;

  const BatchProduct({
    this.id,
    this.barcode,
    this.type,
    this.weight,
    this.unidades,
    this.idMove,
    this.idProduct,
    this.orderProduct,
    this.productId,
    this.batchId,
    this.name,
    this.removalPriority,
    this.lotId,
    this.loteId,
    this.pedido,
    this.pedidoId,
    this.lote,
    this.locationId,
    this.muelleId,
    this.locationDestId,
    this.idLocationDest,
    this.quantity,
    this.productPacking,
    this.otherBarcode,
    this.productTracking,
    this.barcodeLocation,
    this.barcodeLocationDest,
    this.isMuelle,
    this.quantitySeparate,
    this.isSelected,
    this.isSeparate,
    this.timeSeparate,
    this.timeSeparateStart,
    this.timeSeparateEnd,
    this.observation,
    this.isSendOdoo,
    this.isPending,
    this.isSendOdooDate,
    this.expireDate,
    this.origin,
    this.typePick,
    this.fechaTransaccion,
    this.productCode,
    this.isLocationIsOk,
    this.productIsOk,
    this.locationDestIsOk,
    this.isQuantityIsOk,
  });

  @override
  List<Object?> get props => [
        id,
        barcode,
        type,
        weight,
        unidades,
        idMove,
        idProduct,
        orderProduct,
        productId,
        pedido,
        pedidoId,
        batchId,
        name,
        removalPriority,
        lotId,
        loteId,
        lote,
        locationId,
        muelleId,
        locationDestId,
        idLocationDest,
        quantity,
        productPacking,
        otherBarcode,
        productTracking,
        barcodeLocation,
        barcodeLocationDest,
        isMuelle,
        quantitySeparate,
        isSelected,
        isSeparate,
        timeSeparate,
        timeSeparateStart,
        timeSeparateEnd,
        observation,
        isSendOdoo,
        isPending,
        isSendOdooDate,
        expireDate,
        origin,
        typePick,
        fechaTransaccion,
        productCode,
        isLocationIsOk,
        productIsOk,
        locationDestIsOk,
        isQuantityIsOk,
      ];

  /// Crea una copia de la entidad con los campos modificados.
  BatchProduct copyWith({
    int? id,
    dynamic barcode,
    String? type,
    dynamic weight,
    String? unidades,
    int? idMove,
    int? idProduct,
    String? pedido,
    int? pedidoId,
    int? orderProduct,
    dynamic productId,
    dynamic batchId,
    String? name,
    dynamic removalPriority,
    dynamic lotId,
    dynamic loteId,
    dynamic lote,
    dynamic locationId,
    int? muelleId,
    dynamic locationDestId,
    dynamic idLocationDest,
    dynamic quantity,
    List<BatchBarcode>? productPacking,
    List<BatchBarcode>? otherBarcode,
    String? productTracking,
    dynamic barcodeLocation,
    dynamic barcodeLocationDest,
    int? isMuelle,
    dynamic quantitySeparate,
    dynamic isSelected,
    int? isSeparate,
    dynamic timeSeparate,
    String? timeSeparateStart,
    String? timeSeparateEnd,
    String? observation,
    int? isSendOdoo,
    int? isPending,
    String? isSendOdooDate,
    dynamic expireDate,
    dynamic origin,
    String? typePick,
    String? fechaTransaccion,
    dynamic productCode,
    dynamic isLocationIsOk,
    dynamic productIsOk,
    dynamic locationDestIsOk,
    dynamic isQuantityIsOk,
  }) {
    return BatchProduct(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      type: type ?? this.type,
      weight: weight ?? this.weight,
      pedido: pedido ?? this.pedido,
      pedidoId: pedidoId ?? this.pedidoId,
      unidades: unidades ?? this.unidades,
      idMove: idMove ?? this.idMove,
      idProduct: idProduct ?? this.idProduct,
      orderProduct: orderProduct ?? this.orderProduct,
      productId: productId ?? this.productId,
      batchId: batchId ?? this.batchId,
      name: name ?? this.name,
      removalPriority: removalPriority ?? this.removalPriority,
      lotId: lotId ?? this.lotId,
      loteId: loteId ?? this.loteId,
      lote: lote ?? this.lote,
      locationId: locationId ?? this.locationId,
      muelleId: muelleId ?? this.muelleId,
      locationDestId: locationDestId ?? this.locationDestId,
      idLocationDest: idLocationDest ?? this.idLocationDest,
      quantity: quantity ?? this.quantity,
      productPacking: productPacking ?? this.productPacking,
      otherBarcode: otherBarcode ?? this.otherBarcode,
      productTracking: productTracking ?? this.productTracking,
      barcodeLocation: barcodeLocation ?? this.barcodeLocation,
      barcodeLocationDest: barcodeLocationDest ?? this.barcodeLocationDest,
      isMuelle: isMuelle ?? this.isMuelle,
      quantitySeparate: quantitySeparate ?? this.quantitySeparate,
      isSelected: isSelected ?? this.isSelected,
      isSeparate: isSeparate ?? this.isSeparate,
      timeSeparate: timeSeparate ?? this.timeSeparate,
      timeSeparateStart: timeSeparateStart ?? this.timeSeparateStart,
      timeSeparateEnd: timeSeparateEnd ?? this.timeSeparateEnd,
      observation: observation ?? this.observation,
      isSendOdoo: isSendOdoo ?? this.isSendOdoo,
      isPending: isPending ?? this.isPending,
      isSendOdooDate: isSendOdooDate ?? this.isSendOdooDate,
      expireDate: expireDate ?? this.expireDate,
      origin: origin ?? this.origin,
      typePick: typePick ?? this.typePick,
      fechaTransaccion: fechaTransaccion ?? this.fechaTransaccion,
      productCode: productCode ?? this.productCode,
      isLocationIsOk: isLocationIsOk ?? this.isLocationIsOk,
      productIsOk: productIsOk ?? this.productIsOk,
      locationDestIsOk: locationDestIsOk ?? this.locationDestIsOk,
      isQuantityIsOk: isQuantityIsOk ?? this.isQuantityIsOk,
    );
  }
}

/// Entidad de dominio que representa un código de barras asociado a un producto.
/// Equivalente limpio de [Barcodes] del módulo wms_picking.
class BatchBarcode extends Equatable {
  final int? batchId;
  final int? idMove;
  final int? idProduct;
  final dynamic barcode;
  final dynamic cantidad;
  final String? barcodeType;

  const BatchBarcode({
    this.batchId,
    this.idMove,
    this.idProduct,
    this.barcode,
    this.cantidad,
    this.barcodeType,
  });

  @override
  List<Object?> get props => [
        batchId,
        idMove,
        idProduct,
        barcode,
        cantidad,
        barcodeType,
      ];
}
