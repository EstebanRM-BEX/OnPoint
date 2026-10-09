import 'package:injectable/injectable.dart';
import 'package:wms_app/core/services/configuracion_cache_service.dart';
import 'package:wms_app/core/services/interfaces/i_storage_service.dart';
import 'package:wms_app/core/services/novedades_cache_service.dart';
import 'package:wms_app/core/services/ubicaciones_cache_service.dart';
import 'package:wms_app/features/user/data/models/user_configuration_model.dart';
import 'package:wms_app/features/user/domain/entities/user_configuration.dart';
import 'package:wms_app/features/user/domain/entities/user_novelty.dart';
import 'package:wms_app/injection_container.dart';
import '../../../../core/utils/prefs/pref_utils.dart';
import '../../../../src/presentation/models/response_ubicaciones_model.dart';
import '../../../../src/presentation/providers/db/database.dart';
import '../models/user_location_model.dart';
import '../models/user_novelty_model.dart';

abstract class UserLocalDataSource {
  Future<void> cacheUserConfiguration(UserConfigurationModel config);
  Future<UserConfigurationModel?> getCachedUserConfiguration();
  /// Sync completo: reemplaza todas las ubicaciones (en una transacción).
  Future<void> cacheUserLocations(List<UserLocationModel> locations);

  /// Sync incremental: reemplaza [cambios] y borra lo que no esté en
  /// [activos] (si viene), en una transacción.
  Future<void> aplicarCambiosUbicaciones(
    List<UserLocationModel> cambios,
    List<int>? activos,
  );

  Future<List<UserLocationModel>> getUbicacionesLocales();
  Future<int> contarUbicaciones();
  Future<void> borrarUbicaciones();

  /// Empresa (URL + BD) de la sesión actual y la de las ubicaciones locales.
  Future<String> empresaActual();
  Future<String?> empresaUbicaciones();
  Future<void> guardarEmpresaUbicaciones(String empresa);

  /// `since`/`scope` de la última sync exitosa de ubicaciones.
  Future<({String since, String scope})?> marcaSyncUbicaciones();
  Future<void> guardarMarcaSyncUbicaciones(String since, String scope);
  Future<void> borrarMarcaSyncUbicaciones();
  Future<List<AllowedWarehouse>> getCachedWarehouses();
  Future<void> cacheUserNovelties(List<UserNoveltyModel> novelties);
  Future<List<UserNoveltyModel>?> getCachedUserNovelties();
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
    // El insert recién escribió la config fresca en SQLite — invalida el
    // cache compartido para que cualquier lector tome el dato nuevo.
    getIt<ConfiguracionCacheService>().invalidate(userId);

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
        await getIt<ConfiguracionCacheService>().getConfiguration(userId);

    if (config != null) {
      return _mapFromLegacy(config);
    }
    return null;
  }

  static ResultUbicaciones _aLegacy(UserLocationModel e) => ResultUbicaciones(
        id: e.id,
        name: e.name,
        barcode: e.barcode,
        locationId: e.locationId,
        locationName: e.locationName,
        idWarehouse: e.idWarehouse,
        warehouseName: e.warehouseName,
        isADockAlter: e.isADockAlter,
      );

  @override
  Future<void> cacheUserLocations(List<UserLocationModel> locations) async {
    await db.ubicacionesRepository
        .syncUbicaciones(locations.map(_aLegacy).toList());
    // Igual que novedades: el sync escribió ubicaciones frescas en SQLite,
    // el cache compartido en memoria debe volver a leerlas.
    getIt<UbicacionesCacheService>().invalidate();
  }

  @override
  Future<void> aplicarCambiosUbicaciones(
    List<UserLocationModel> cambios,
    List<int>? activos,
  ) async {
    await db.ubicacionesRepository
        .aplicarCambios(cambios.map(_aLegacy).toList(), activos);
    getIt<UbicacionesCacheService>().invalidate();
  }

  @override
  Future<List<UserLocationModel>> getUbicacionesLocales() async => [
        for (final u in await db.ubicacionesRepository.getAllUbicaciones())
          UserLocationModel(
            id: u.id ?? 0,
            name: u.name ?? '',
            idWarehouse: u.idWarehouse ?? 0,
            barcode: u.barcode,
            locationId: u.locationId,
            locationName: u.locationName,
            warehouseName: u.warehouseName,
            isADockAlter: u.isADockAlter,
          ),
      ];

  @override
  Future<int> contarUbicaciones() => db.getUbicacionesCount();

  @override
  Future<void> borrarUbicaciones() async {
    await db.ubicacionesRepository.deleteAll();
    getIt<UbicacionesCacheService>().invalidate();
  }

  @override
  Future<String> empresaActual() async =>
      '${await PrefUtils.getEnterprise()}|${getIt<IStorageService>().nameDatabase}';

  @override
  Future<String?> empresaUbicaciones() => PrefUtils.getUbicacionesEnterprise();

  @override
  Future<void> guardarEmpresaUbicaciones(String empresa) =>
      PrefUtils.setUbicacionesEnterprise(empresa);

  @override
  Future<({String since, String scope})?> marcaSyncUbicaciones() =>
      PrefUtils.getUbicacionesSync();

  @override
  Future<void> guardarMarcaSyncUbicaciones(String since, String scope) =>
      PrefUtils.setUbicacionesSync(since, scope);

  @override
  Future<void> borrarMarcaSyncUbicaciones() => PrefUtils.clearUbicacionesSync();

  @override
  Future<List<AllowedWarehouse>> getCachedWarehouses() async {
    return await db.warehouseRepository.getAllowedWarehouse();
  }

  @override
  Future<void> cacheUserNovelties(List<UserNoveltyModel> novelties) async {
    final List<Novedad> legacyNovelties = novelties.map((e) {
      return Novedad(
        id: e.id,
        name: e.name,
        code: e.code,
      );
    }).toList();
    await db.novedadesRepository.syncNovedades(legacyNovelties);
    // El sync recién escribió novedades frescas en SQLite — invalida el
    // cache compartido para que esta lectura y cualquier otro consumidor
    // (RecepcionBloc, TransferenciaBloc, WMSPickingBloc, etc.) tomen el
    // dato nuevo en vez de una copia vieja en memoria.
    getIt<NovedadesCacheService>().invalidate();
  }

  @override
  Future<List<UserNoveltyModel>?> getCachedUserNovelties() async {
    final List<Novedad> legacyNovelties = await getIt<NovedadesCacheService>()
        .getAll();

    if (legacyNovelties.isNotEmpty) {
      return legacyNovelties.map((e) {
        return UserNoveltyModel(
          id: e.id,
          name: e.name ?? '',
          code: e.code ?? '',
        );
      }).toList();
    }
    return null;
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
