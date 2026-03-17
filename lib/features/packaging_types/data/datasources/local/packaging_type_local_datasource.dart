import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import '../../models/packaging_type_model.dart';

abstract class PackagingTypeLocalDataSource {
  Future<List<PackagingTypeModel>> getPackagingTypes();
  Future<void> savePackagingTypes(List<PackagingTypeModel> packagingTypes);
}

@LazySingleton(as: PackagingTypeLocalDataSource)
class PackagingTypeLocalDataSourceImpl implements PackagingTypeLocalDataSource {
  static const String tableName = 'tbl_packaging_types';
  
  // Using DataBaseSqlite from the project's existing DB initialization
  final DataBaseSqlite dbProvider;

  PackagingTypeLocalDataSourceImpl(this.dbProvider);

  @override
  Future<List<PackagingTypeModel>> getPackagingTypes() async {
    final db = await dbProvider.getDatabaseInstance();
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    
    return maps.map((map) => PackagingTypeModel.fromJson(map)).toList();
  }

  @override
  Future<void> savePackagingTypes(List<PackagingTypeModel> packagingTypes) async {
    final db = await dbProvider.getDatabaseInstance();
    
    await db.transaction((txn) async {
      final batch = txn.batch();
      
      // Clear existing records before inserting new to stay synced (Replace all)
      batch.delete(tableName);
      
      for (var type in packagingTypes) {
        batch.insert(
          tableName,
          type.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      await batch.commit(noResult: true);
    });
  }
}
