import 'package:injectable/injectable.dart';
import 'package:wms_app/features/user/data/models/user_configuration_model.dart';
import 'package:wms_app/features/user/domain/entities/user_configuration.dart';
import '../../../../src/core/utils/prefs/pref_utils.dart';
import '../../../../src/presentation/models/response_ubicaciones_model.dart';
import '../../../../src/presentation/providers/db/database.dart';
import '../models/user_configuration_model.dart';
import '../models/user_location_model.dart';

abstract class UserLocalDataSource {
  Future<void> cacheUserConfiguration(UserConfigurationModel config);
  Future<UserConfigurationModel?> getCachedUserConfiguration();
  Future<void> cacheUserLocations(List<UserLocationModel> locations);
  Future<List<AllowedWarehouse>> getCachedWarehouses();
}

@LazySingleton(as: UserLocalDataSource)
class UserLocalDataSourceImpl implements UserLocalDataSource {
  final DataBaseSqlite db;

  UserLocalDataSourceImpl(this.db);

  @override
  Future<void> cacheUserConfiguration(UserConfigurationModel config) async {
    final int userId = await PrefUtils.getUserId();

    // Convert UserConfigurationModel to legacy Configurations
    final legacyConfig = _mapToLegacy(config);

    await db.configurationsRepository.insertConfiguration(legacyConfig, userId);

    // Also cache allowed warehouses
    if (legacyConfig.result?.result?.allowedWarehouses != null) {
      await db.warehouseRepository.insertAllowedWarehouse(
          legacyConfig.result?.result?.allowedWarehouses ?? []);
    }

    await PrefUtils.setUserRol(config.result?.result?.rol ?? '');
  }

  @override
  Future<UserConfigurationModel?> getCachedUserConfiguration() async {
    final int userId = await PrefUtils.getUserId();
    final UserConfigurationModel? config =
        await db.configurationsRepository.getConfiguration(userId);

    if (config != null) {
      return _mapFromLegacy(config);
    }
    return null;
  }

  @override
  Future<void> cacheUserLocations(List<UserLocationModel> locations) async {
    final List<ResultUbicaciones> legacyLocations = locations.map((e) {
      return ResultUbicaciones(
        id: e.id,
        name: e.name,
        idWarehouse: e.idWarehouse,
        barcode: e.barcode,
        warehouseName: e.warehouseName,
      );
    }).toList();

    await db.ubicacionesRepository.syncUbicaciones(legacyLocations);
  }

  @override
  Future<List<AllowedWarehouse>> getCachedWarehouses() async {
    return await db.warehouseRepository.getAllowedWarehouse();
  }

  // Mapper helper: UserConfigurationModel -> Configurations
  UserConfiguration _mapToLegacy(UserConfigurationModel model) {
    // We recreate the JSON structure to use the fromMap of the legacy model
    // This is safer than manually mapping 50+ fields
    final json = model.toJson();
    return UserConfigurationModel.fromJson(json);
  }

  // Mapper helper: Configurations -> UserConfigurationModel
  UserConfigurationModel _mapFromLegacy(UserConfigurationModel legacy) {
    final json = legacy.toJson();
    return UserConfigurationModel.fromJson(json);
  }
}
