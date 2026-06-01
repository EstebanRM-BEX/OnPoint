import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/PickhWithProducts_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/response_pick_model.dart';

abstract class PickScanLocalDataSource {
  Future<Unit> setProductField(
      int batchId, int productId, String field, dynamic value, int idMove);

  Future<Unit> setProductFieldString(
      int batchId, int productId, String field, String value, int idMove);

  Future<Unit> setPickField(int pickId, String field, dynamic value);

  Future<Unit> startStopwatch(
      int batchId, int productId, int idMove, String time);

  Future<Unit> setTransactionDate(
      int batchId, String date, int productId, int idMove);

  Future<Unit> endStopwatch(
      int pickId, String time, int productId, int idMove);

  Future<String> getProductField(
      int batchId, int productId, int idMove, String field);

  Future<Unit> totalStopwatch(
      int pickId, int productId, int idMove, double seconds);

  Future<PickWithProducts?> getPickWithProducts(int pickId);

  Future<List<Barcodes>> getBarcodesProduct(
      int pickId, int productId, int idMove);

  Future<ProductsBatch?> getProductPick(
      int pickId, int productId, int idMove);

  Future<ResultPick?> getPickById(int pickId);
}

@LazySingleton(as: PickScanLocalDataSource)
class PickScanLocalDataSourceImpl implements PickScanLocalDataSource {
  final DataBaseSqlite db = DataBaseSqlite();

  @override
  Future<Unit> setProductField(int batchId, int productId, String field,
      dynamic value, int idMove) async {
    await db.pickProductsRepository
        .setFieldTablePickProducts(batchId, productId, field, value, idMove);
    return unit;
  }

  @override
  Future<Unit> setProductFieldString(int batchId, int productId, String field,
      String value, int idMove) async {
    await db.pickProductsRepository
        .setFieldStringTablePickProducts(batchId, productId, field, value, idMove);
    return unit;
  }

  @override
  Future<Unit> setPickField(int pickId, String field, dynamic value) async {
    await db.pickRepository.setFieldTablePick(pickId, field, value);
    return unit;
  }

  @override
  Future<Unit> startStopwatch(
      int batchId, int productId, int idMove, String time) async {
    await db.pickProductsRepository
        .startStopwatch(batchId, productId, idMove, time);
    return unit;
  }

  @override
  Future<Unit> setTransactionDate(
      int batchId, String date, int productId, int idMove) async {
    await db.pickProductsRepository
        .dateTransaccionProduct(batchId, date, productId, idMove);
    return unit;
  }

  @override
  Future<Unit> endStopwatch(
      int pickId, String time, int productId, int idMove) async {
    await db.pickProductsRepository
        .endStopwatchProduct(pickId, time, productId, idMove);
    return unit;
  }

  @override
  Future<String> getProductField(
      int batchId, int productId, int idMove, String field) async {
    return await db.pickProductsRepository
        .getFieldTableProductsPick(batchId, productId, idMove, field);
  }

  @override
  Future<Unit> totalStopwatch(
      int pickId, int productId, int idMove, double seconds) async {
    await db.pickProductsRepository
        .totalStopwatchProduct(pickId, productId, idMove, seconds);
    return unit;
  }

  @override
  Future<PickWithProducts?> getPickWithProducts(int pickId) async {
    return await db.pickProductsRepository.getPickWithProducts(pickId);
  }

  @override
  Future<List<Barcodes>> getBarcodesProduct(
      int pickId, int productId, int idMove) async {
    return await db.barcodesPackagesRepository
        .getBarcodesProduct(pickId, productId, idMove, 'pick');
  }

  @override
  Future<ProductsBatch?> getProductPick(
      int pickId, int productId, int idMove) async {
    return await db.pickProductsRepository
        .getProductPick(pickId, productId, idMove);
  }

  @override
  Future<ResultPick?> getPickById(int pickId) async {
    return await db.pickRepository.getPickById(pickId);
  }
}
