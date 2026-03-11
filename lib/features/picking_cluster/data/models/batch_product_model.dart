import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import '../../domain/entities/batch_product.dart';

/// Convierte un [ProductsBatch] (modelo SQLite compartido) en la entidad de
/// dominio [BatchProduct] propia de la feature picking_cluster.
extension ProductsBatchToBatchProduct on ProductsBatch {
  BatchProduct toEntity() {
    return BatchProduct(
      id: id,
      barcode: barcode,
      type: type,
      weight: weigth,
      unidades: unidades,
      idMove: idMove,
      pedido: pedido,
      pedidoId: pedidoId,
      idProduct: idProduct,
      orderProduct: orderProduct,
      productId: productId,
      batchId: batchId,
      name: name,
      removalPriority: rimovalPriority,
      lotId: lotId,
      loteId: loteId,
      lote: lote,
      locationId: locationId,
      muelleId: muelleId,
      locationDestId: locationDestId,
      idLocationDest: idLocationDest,
      quantity: quantity,
      productPacking: productPacking?.map((b) => b.toEntity()).toList(),
      otherBarcode: otherBarcode?.map((b) => b.toEntity()).toList(),
      productTracking: productTracking,
      barcodeLocation: barcodeLocation,
      barcodeLocationDest: barcodeLocationDest,
      isMuelle: isMuelle,
      quantitySeparate: quantitySeparate,
      isSelected: isSelected,
      isSeparate: isSeparate,
      timeSeparate: timeSeparate,
      timeSeparateStart: timeSeparateStart,
      timeSeparateEnd: timeSeparateEnd,
      observation: observation,
      isSendOdoo: isSendOdoo,
      isPending: isPending,
      isSendOdooDate: isSendOdooDate,
      expireDate: expireDate,
      origin: origin,
      typePick: typePick,
      fechaTransaccion: fechaTransaccion,
      productCode: productCode,
      isLocationIsOk: isLocationIsOk,
      productIsOk: productIsOk,
      locationDestIsOk: locationDestIsOk,
      isQuantityIsOk: isQuantityIsOk,
    );
  }
}

/// Convierte una entidad [BatchProduct] de vuelta al modelo SQLite [ProductsBatch]
/// para persistencia/escritura en base de datos local.
extension BatchProductToProductsBatch on BatchProduct {
  ProductsBatch toModel() {
    return ProductsBatch(
      id: id,
      barcode: barcode,
      type: type,
      weigth: weight,
      unidades: unidades,
      idMove: idMove,
      pedido: pedido,
      pedidoId: pedidoId,
      idProduct: idProduct,
      orderProduct: orderProduct,
      productId: productId,
      batchId: batchId,
      name: name,
      rimovalPriority: removalPriority,
      lotId: lotId,
      loteId: loteId,
      lote: lote,
      locationId: locationId,
      muelleId: muelleId,
      locationDestId: locationDestId,
      idLocationDest: idLocationDest,
      quantity: quantity,
      productPacking: productPacking?.map((b) => b.toModel()).toList(),
      otherBarcode: otherBarcode?.map((b) => b.toModel()).toList(),
      productTracking: productTracking,
      barcodeLocation: barcodeLocation,
      barcodeLocationDest: barcodeLocationDest,
      isMuelle: isMuelle,
      quantitySeparate: quantitySeparate,
      isSelected: isSelected,
      isSeparate: isSeparate,
      timeSeparate: timeSeparate,
      timeSeparateStart: timeSeparateStart,
      timeSeparateEnd: timeSeparateEnd,
      observation: observation,
      isSendOdoo: isSendOdoo,
      isPending: isPending,
      isSendOdooDate: isSendOdooDate,
      expireDate: expireDate,
      origin: origin,
      typePick: typePick,
      fechaTransaccion: fechaTransaccion,
      productCode: productCode,
      isLocationIsOk: isLocationIsOk,
      productIsOk: productIsOk,
      locationDestIsOk: locationDestIsOk,
      isQuantityIsOk: isQuantityIsOk,
    );
  }
}

/// Convierte un [Barcodes] al dominio [BatchBarcode].
extension BarcodesToBatchBarcode on Barcodes {
  BatchBarcode toEntity() {
    return BatchBarcode(
      batchId: batchId,
      idMove: idMove,
      idProduct: idProduct,
      barcode: barcode,
      cantidad: cantidad,
      barcodeType: barcodeType,
    );
  }
}

/// Convierte una entidad [BatchBarcode] de vuelta al modelo [Barcodes].
extension BatchBarcodeToModel on BatchBarcode {
  Barcodes toModel() {
    return Barcodes(
      batchId: batchId,
      idMove: idMove,
      idProduct: idProduct,
      barcode: barcode,
      cantidad: cantidad,
      barcodeType: barcodeType,
    );
  }
}
