import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/response_pick_model.dart';

/// Abstract interface for components local (SQLite) data operations.
abstract class PickingComponentsLocalDataSource {
  Future<List<ResultPick>> getComponentsFromDb();
  Future<Unit> saveComponentsToDb(List<ResultPick> picks);
  Future<Unit> insertComponentProducts(List<ProductsBatch> products);
  Future<Unit> insertComponentBarcodes(List<Barcodes> barcodes);
}

/// Implementation using SQLite via [DataBaseSqlite].
@LazySingleton(as: PickingComponentsLocalDataSource)
class PickingComponentsLocalDataSourceImpl
    implements PickingComponentsLocalDataSource {
  final DataBaseSqlite db = DataBaseSqlite();

  @override
  Future<List<ResultPick>> getComponentsFromDb() async {
    return await db.pickRepository.getAllPickingPicks('pick-componentes');
  }

  @override
  Future<Unit> saveComponentsToDb(List<ResultPick> picks) async {
    await db.pickRepository.insertAllPickingPicks(picks, 'pick-componentes');
    return unit;
  }

  @override
  Future<Unit> insertComponentProducts(List<ProductsBatch> products) async {
    await db.pickProductsRepository
        .insertPickProducts(products, 'pick-componentes');
    return unit;
  }

  @override
  Future<Unit> insertComponentBarcodes(List<Barcodes> barcodes) async {
    await DataBaseSqlite()
        .barcodesPackagesRepository
        .insertOrUpdateBarcodes(barcodes, 'pick-componentes');
    return unit;
  }
}
