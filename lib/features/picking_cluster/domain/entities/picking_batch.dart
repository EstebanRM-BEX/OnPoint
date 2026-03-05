import 'package:equatable/equatable.dart';

/// Represents a batch or cluster of picking tasks.
class PickingBatch extends Equatable {
  final int? id;
  final String? name;
  final String? userName;
  final int? userId;
  final String? rol;
  final String? orderBy;
  final String? orderPicking;
  final String? scheduledDate;
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
  final List<PickingBatchItem> listItems;

  const PickingBatch({
    this.id,
    this.name,
    this.userName,
    this.userId,
    this.rol,
    this.orderBy,
    this.orderPicking,
    this.scheduledDate,
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
    required this.listItems,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        userName,
        userId,
        rol,
        orderBy,
        orderPicking,
        scheduledDate,
        state,
        pickingTypeId,
        observation,
        isWave,
        muelle,
        idMuelle,
        idMuellePadre,
        barcodeMuelle,
        countItems,
        totalQuantityItems,
        completedItems,
        progressPercentage,
        startTimePick,
        endTimePick,
        productSeparateQty,
        zonaEntrega,
        listItems,
      ];
}

/// Represents an individual item within a picking batch.
class PickingBatchItem extends Equatable {
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
  final String? location;
  final List<dynamic>? locationDestId;
  final String? locationDest;
  final dynamic? quantity;
  final String? barcode;
  final List<PickingOtherBarcode>? otherBarcodes;
  final List<PickingOtherBarcode>? productPacking;
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

  const PickingBatchItem({
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
    this.location,
    this.locationDestId,
    this.locationDest,
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

  @override
  List<Object?> get props => [
        batchId,
        idMove,
        pickingId,
        idProduct,
        pedido,
        pedidoId,
        origin,
        productId,
        loteId,
        lotId,
        expireDate,
        locationId,
        rimovalPriority,
        location,
        locationDestId,
        locationDest,
        quantity,
        barcode,
        otherBarcodes,
        productPacking,
        weight,
        unidades,
        zonaEntrega,
        idZonaEntrega,
        quantitySeparate,
        observation,
        timeSeparate,
        fechaTransaccion,
        isSeparate,
        manejaTemperatura,
        temperatura,
        image,
        imageNovedad,
        packageConsecutivo,
        realizado,
        productTracking,
      ];
}

class PickingOtherBarcode extends Equatable {
  final String? barcode;
  final dynamic? cantidad;
  final int? idProduct;
  final int? idMove;
  final int? batchId;
  final int? productId;

  const PickingOtherBarcode({
    this.barcode,
    this.cantidad,
    this.idProduct,
    this.idMove,
    this.batchId,
    this.productId,
  });

  @override
  List<Object?> get props => [
        barcode,
        cantidad,
        idProduct,
        idMove,
        batchId,
        productId,
      ];
}
