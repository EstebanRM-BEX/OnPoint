import 'dart:developer';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/features/picking_cluster/data/models/batch_product_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/features/picking_cluster/data/models/pedido_validate_model.dart';
import '../../domain/entities/batch_product.dart';
import '../../domain/entities/picking_batch.dart';

abstract class PickingClusterLocalDataSource {
  Future<void> cachePickingBatches(List<PickingBatch> batches);
  Future<List<PickingBatch>> getCachedPickingBatches();
  Future<List<BatchProduct>> getBatchProducts(int batchId);
  Future<void> setFieldTableBatchProducts(int batchId, int productId,
      String field, dynamic value, int idMove, String type);
  Future<void> setFieldTableBatch(
      int batchId, String field, dynamic value, String type);
  Future<List<BatchBarcode>> getBarcodesProduct(
      int batchId, int productId, int idMove, String type);
  Future<void> incremenQtytProductSeparate(
      int batchId, int productId, int idMove, dynamic quantity, String type);
  Future<void> incrementProductSeparateQty(int batchId, String type);
  Future<String> getFieldTableProducts(
      int batchId, int productId, int moveId, String field, String type);
  Future<BatchProduct?> getProductBatch(
      int batchId, int productId, int idMove, String type);
  Future<void> setFieldTableBatchPedidoValidate(
      int batchId, String namePedido, String field, dynamic value);
  Future<void> endStopwatchBatch(int batchId, String time, String typePicking);
}

@LazySingleton(as: PickingClusterLocalDataSource)
class PickingClusterLocalDataSourceImpl
    implements PickingClusterLocalDataSource {
  @override
  Future<void> cachePickingBatches(List<PickingBatch> batches) async {
    try {
      if (batches.isNotEmpty) {
        int userId = await PrefUtils.getUserId();
        final batchModels = batches.map((b) => b.toBatchsModel()).toList();

        // Limpiar datos existentes antes de insertar
        await DataBaseSqlite().delePicking('cluster');

        await DataBaseSqlite()
            .batchPickingRepository
            .insertAllBatches(batchModels, userId, 'cluster');

        final productsIterable =
            _extractAllProducts(batchModels).toList(growable: false);
        final allBarcodes =
            _extractAllBarcodes(batchModels).toList(growable: false);

        await DataBaseSqlite().insertBatchProducts(productsIterable, 'cluster');

        final allPedidosValidate = batches
            .expand((b) => b.pedidosValidate)
            .map((e) => PedidoValidateModel.fromEntity(e))
            .toList();
        await DataBaseSqlite().insertPedidosValidate(allPedidosValidate);

        if (allBarcodes.isNotEmpty) {
          await DataBaseSqlite()
              .barcodesPackagesRepository
              .insertOrUpdateBarcodes(allBarcodes, 'cluster');
        }
      }
    } catch (e) {
      log('Error caching picking clusters to sqlite: $e',
          name: 'PickingClusterLocalDS');
    }
  }

  @override
  Future<List<PickingBatch>> getCachedPickingBatches() async {
    try {
      int userId = await PrefUtils.getUserId();
      final batchModels = await DataBaseSqlite()
          .batchPickingRepository
          .getAllBatchs(userId, 'cluster');

      final entities = <PickingBatch>[];
      for (var model in batchModels) {
        final entity = model.toPickingBatchEntity();
        final pedidosValidateModels =
            await DataBaseSqlite().getPedidosValidate(entity.id!);
        entities.add(entity.copyWith(
          pedidosValidate:
              pedidosValidateModels.map((m) => m.toEntity()).toList(),
        ));
      }
      return entities;
    } catch (e) {
      log('Error reading cached picking clusters from sqlite: $e',
          name: 'PickingClusterLocalDS');
      return [];
    }
  }

  @override
  Future<List<BatchProduct>> getBatchProducts(int batchId) async {
    try {
      final batchWithProducts =
          await DataBaseSqlite().getBatchWithProducts(batchId, 'cluster');
      final rawProducts = batchWithProducts?.products ?? [];
      return rawProducts.map((p) => p.toEntity()).toList();
    } catch (e) {
      log('Error reading batch products from sqlite: $e',
          name: 'PickingClusterLocalDS');
      return [];
    }
  }

  @override
  Future<void> setFieldTableBatchProducts(int batchId, int productId,
      String field, dynamic value, int idMove, String type) async {
    try {
      await DataBaseSqlite().setFieldTableBatchProducts(
          batchId, productId, field, value, idMove, type);
    } catch (e) {
      log('Error setFieldTableBatchProducts sqlite: $e',
          name: 'PickingClusterLocalDS');
      throw Exception('Database error');
    }
  }

  @override
  Future<void> setFieldTableBatch(
      int batchId, String field, dynamic value, String type) async {
    try {
      await DataBaseSqlite()
          .batchPickingRepository
          .setFieldTableBatch(batchId, field, value, type);
    } catch (e) {
      log('Error setFieldTableBatch sqlite: $e', name: 'PickingClusterLocalDS');
      throw Exception('Database error');
    }
  }

  @override
  Future<List<BatchBarcode>> getBarcodesProduct(
      int batchId, int productId, int idMove, String type) async {
    try {
      final result = await DataBaseSqlite()
          .barcodesPackagesRepository
          .getBarcodesProduct(batchId, productId, idMove, type);
      return result.map((b) => b.toEntity()).toList();
    } catch (e) {
      log('Error getBarcodesProduct sqlite: $e', name: 'PickingClusterLocalDS');
      return [];
    }
  }

  @override
  Future<void> incremenQtytProductSeparate(int batchId, int productId,
      int idMove, dynamic quantity, String type) async {
    try {
      await DataBaseSqlite().incremenQtytProductSeparate(
          batchId, productId, idMove, quantity, type);
    } catch (e) {
      log('Error incremenQtytProductSeparate sqlite: $e',
          name: 'PickingClusterLocalDS');
      throw Exception('Database error');
    }
  }

  @override
  Future<void> incrementProductSeparateQty(int batchId, String type) async {
    try {
      await DataBaseSqlite().incrementProductSeparateQty(batchId, type);
    } catch (e) {
      log('Error incrementProductSeparateQty sqlite: $e',
          name: 'PickingClusterLocalDS');
      throw Exception('Database error');
    }
  }

  @override
  Future<String> getFieldTableProducts(
      int batchId, int productId, int moveId, String field, String type) async {
    try {
      return await DataBaseSqlite()
          .getFieldTableProducts(batchId, productId, moveId, field, type);
    } catch (e) {
      log('Error getFieldTableProducts sqlite: $e',
          name: 'PickingClusterLocalDS');
      throw Exception('Database error');
    }
  }

  @override
  Future<BatchProduct?> getProductBatch(
      int batchId, int productId, int idMove, String type) async {
    try {
      final result = await DataBaseSqlite()
          .getProductBatch(batchId, productId, idMove, type);
      return result?.toEntity();
    } catch (e) {
      log('Error getProductBatch sqlite: $e', name: 'PickingClusterLocalDS');
      throw Exception('Database error');
    }
  }

  @override
  Future<void> setFieldTableBatchPedidoValidate(
      int batchId, String namePedido, String field, dynamic value) async {
    try {
      await DataBaseSqlite()
          .setFieldTableBatchPedidoValidate(batchId, namePedido, field, value);
    } catch (e) {
      log('Error setFieldTableBatchPedidoValidate sqlite: $e',
          name: 'PickingClusterLocalDS');
      throw Exception('Database error');
    }
  }

  @override
  Future<void> endStopwatchBatch(
      int batchId, String time, String typePicking) async {
    try {
      await DataBaseSqlite()
          .batchPickingRepository
          .endStopwatchBatch(batchId, time, typePicking);
    } catch (e) {
      log('Error endStopwatchBatch sqlite: $e', name: 'PickingClusterLocalDS');
      throw Exception('Database error');
    }
  }

  // ─── Private helpers ────────────────────────────────────────────────────

  Iterable<Barcodes> _extractAllBarcodes(List<BatchsModel> batches) sync* {
    for (final batch in batches) {
      if (batch.listItems == null) continue;
      for (final product in batch.listItems!) {
        if (product.productPacking != null) yield* product.productPacking!;
        if (product.otherBarcode != null) yield* product.otherBarcode!;
      }
    }
  }

  Iterable<ProductsBatch> _extractAllProducts(List<BatchsModel> batches) sync* {
    for (final batch in batches) {
      if (batch.listItems != null) yield* batch.listItems!;
    }
  }
}

// ─── Extension: PickingBatch → BatchsModel (para persistencia SQLite) ──────

extension BatchMapping on PickingBatch {
  BatchsModel toBatchsModel() {
    return BatchsModel(
      id: id,
      name: name,
      userName: userName,
      userId: userId,
      orderBy: orderBy,
      orderPicking: orderPicking,
      scheduleddate: scheduledDate?.toString(),
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
      startTimePick: startTimePick?.toString(),
      endTimePick: endTimePick?.toString(),
      zonaEntrega: zonaEntrega,
      listItems: listItems.map((item) => item.toProductsBatch()).toList(),
    );
  }
}

// ─── Extension: BatchsModel → PickingBatch (al leer desde SQLite) ──────────

extension BatchModelToEntityMapping on BatchsModel {
  PickingBatch toPickingBatchEntity() {
    return PickingBatch(
      id: id!,
      name: name ?? '',
      userName: userName ?? '',
      userId:
          userId is int ? userId : int.tryParse(userId?.toString() ?? '') ?? 0,
      orderBy: orderBy?.toString(),
      orderPicking: orderPicking?.toString(),
      scheduledDate: scheduleddate?.toString() ?? '',
      state: state ?? '',
      pickingTypeId: pickingTypeId?.toString() ?? '',
      observation: observation,
      isWave: isWave is bool ? isWave : isWave == 1 || isWave == 'true',
      muelle: muelle,
      idMuelle:
          idMuelle is int ? idMuelle : int.tryParse(idMuelle?.toString() ?? ''),
      idMuellePadre: idMuellePadre is int
          ? idMuellePadre
          : int.tryParse(idMuellePadre?.toString() ?? ''),
      barcodeMuelle: barcodeMuelle,
      countItems: countItems is int
          ? countItems
          : int.tryParse(countItems?.toString() ?? '') ?? 0,
      totalQuantityItems: totalQuantityItems is int
          ? totalQuantityItems
          : int.tryParse(totalQuantityItems?.toString() ?? '') ?? 0,
      progressPercentage: 0.0,
      startTimePick: startTimePick?.toString(),
      endTimePick: endTimePick?.toString(),
      zonaEntrega: zonaEntrega,
      listItems: [],
    );
  }
}

// ─── Extension: PickingBatchItem → ProductsBatch (para SQLite insert) ──────

extension BatchItemMapping on PickingBatchItem {
  ProductsBatch toProductsBatch() {
    return ProductsBatch(
      batchId: batchId,
      idMove: idMove,
      idProduct: idProduct,
      orderProduct: null,
      productId: productId,
      origin: origin,
      pedido: pedido,
      pedidoId: pedidoId,
      muelleId: null,
      barcodeLocation: location,
      barcodeLocationDest: locationDest,
      lotId: lotId,
      loteId: loteId,
      productPacking: productPacking
          ?.map((b) => Barcodes(
                barcode: b.barcode,
                cantidad: b.cantidad,
                idProduct: b.idProduct,
                idMove: b.idMove,
                batchId: b.batchId,
              ))
          .toList(),
      otherBarcode: otherBarcodes
          ?.map((b) => Barcodes(
                barcode: b.barcode,
                cantidad: b.cantidad,
                idProduct: b.idProduct,
                idMove: b.idMove,
                batchId: b.batchId,
              ))
          .toList(),
      locationId: locationId,
      locationDestId: locationDestId,
      quantity: quantity,
      barcode: barcode,
      name: null,
      weigth: weight,
      unidades: unidades,
      quantitySeparate: quantitySeparate,
      timeSeparate: timeSeparate?.toString(),
      observation: observation,
      fechaTransaccion: fechaTransaccion?.toString(),
      isSeparate: isSeparate,
      productTracking: productTracking,
    );
  }
}
