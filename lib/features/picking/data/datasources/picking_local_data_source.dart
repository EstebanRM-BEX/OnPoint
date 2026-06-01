import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/features/user/data/models/user_configuration_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/PickhWithProducts_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/response_pick_model.dart';

/// Abstract interface for picking local (SQLite) data operations.
abstract class PickingLocalDataSource {
  Future<Unit> savePicksToDb(List<ResultPick> picks);
  Future<List<ResultPick>> getPicksFromDb();
  Future<Unit> assignUserLocally(int pickId, int userId, String userName);
  Future<Unit> recordTimeLocally(int pickId, String timeType, String time);
  Future<PickWithProducts?> getPickWithProducts(int pickId);
  Future<UserConfigurationModel?> getConfigurations(int userId);
  Future<Unit> clearPicks();
  Future<Unit> insertPickProducts(List<ProductsBatch> products);
  Future<Unit> insertBarcodes(List<Barcodes> barcodes);
}

/// Implementation of [PickingLocalDataSource] using SQLite via [DataBaseSqlite].
@LazySingleton(as: PickingLocalDataSource)
class PickingLocalDataSourceImpl implements PickingLocalDataSource {
  final DataBaseSqlite db = DataBaseSqlite();

  @override
  Future<Unit> savePicksToDb(List<ResultPick> picks) async {
    await db.pickRepository.insertAllPickingPicks(picks, 'pick');
    return unit;
  }

  @override
  Future<List<ResultPick>> getPicksFromDb() async {
    return await db.pickRepository.getAllPickingPicks('pick');
  }

  @override
  Future<Unit> assignUserLocally(
      int pickId, int userId, String userName) async {
    await db.pickRepository.setFieldTablePick(pickId, 'responsable_id', userId);
    await db.pickRepository
        .setFieldTablePick(pickId, 'responsable', userName);
    await db.pickRepository.setFieldTablePick(pickId, 'is_selected', 1);
    return unit;
  }

  @override
  Future<Unit> recordTimeLocally(
      int pickId, String timeType, String time) async {
    if (timeType == 'start_time_transfer') {
      await db.pickRepository
          .setFieldTablePick(pickId, 'start_time_transfer', time);
      await db.pickRepository.setFieldTablePick(pickId, 'is_selected', 1);
    } else if (timeType == 'end_time_transfer') {
      await db.pickRepository
          .setFieldTablePick(pickId, 'end_time_transfer', time);
    }
    return unit;
  }

  @override
  Future<PickWithProducts?> getPickWithProducts(int pickId) async {
    return await db.pickProductsRepository.getPickWithProducts(pickId);
  }

  @override
  Future<UserConfigurationModel?> getConfigurations(int userId) async {
    return await db.configurationsRepository.getConfiguration(userId);
  }

  @override
  Future<Unit> clearPicks() async {
    await DataBaseSqlite().delePick('pick');
    return unit;
  }

  @override
  Future<Unit> insertPickProducts(List<ProductsBatch> products) async {
    await db.pickProductsRepository.insertPickProducts(products, 'pick');
    return unit;
  }

  @override
  Future<Unit> insertBarcodes(List<Barcodes> barcodes) async {
    await DataBaseSqlite()
        .barcodesPackagesRepository
        .insertOrUpdateBarcodes(barcodes, 'pick');
    return unit;
  }
}
