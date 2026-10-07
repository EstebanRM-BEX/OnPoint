import 'package:injectable/injectable.dart';
import 'package:wms_app/core/network/network_guard.dart';
import 'package:wms_app/core/services/configuracion_cache_service.dart';
import 'package:wms_app/core/services/novedades_cache_service.dart';
import 'package:wms_app/core/services/ubicaciones_cache_service.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/user/domain/entities/user_novelty.dart';

/// Lo que el repositorio necesita del resto de la app (sesión, red, reloj y
/// catálogos compartidos), en un solo punto que los tests pueden mockear.
/// Solo lee: no modifica nada compartido.
@lazySingleton
class PackingEntorno {
  final ConfiguracionCacheService configuracionCache;
  final NovedadesCacheService novedadesCache;
  final UbicacionesCacheService ubicacionesCache;

  PackingEntorno(
    this.configuracionCache,
    this.novedadesCache,
    this.ubicacionesCache,
  );

  Future<bool> hayRed() => hasNetwork();

  DateTime ahora() => DateTime.now();

  Future<int> userId() => PrefUtils.getUserId();

  Future<String> userName() => PrefUtils.getUserName();

  /// MAC (o IMEI si la MAC no está disponible) de la PDA.
  Future<String> deviceId() => PrefUtils.getDeviceIdPDA();

  /// Dueño de los datos locales: empresa + usuario.
  Future<String> owner() async =>
      '${await PrefUtils.getEnterprise()}|${await PrefUtils.getUserId()}';

  Future<ConfigPackingUsuario> configuracion() async {
    final userId = await PrefUtils.getUserId();
    final c = (await configuracionCache.getConfiguration(
      userId,
    ))?.result?.result;
    if (c == null) return const ConfigPackingUsuario();
    return ConfigPackingUsuario(
      manualQuantityPack: c.manualQuantityPack ?? false,
      manualProductSelectionPack: c.manualProductSelectionPack ?? false,
      locationPackManual: c.locationPackManual ?? false,
      scanProduct: c.scanProduct ?? true,
      showPhotoTemperature: c.showPhotoTemperature ?? false,
      hideValidatePacking: c.hideValidatePacking ?? false,
    );
  }

  Future<List<Novedad>> novedades() => novedadesCache.getAll();

  /// Ubicaciones de muelle (is_a_dock) del catálogo compartido.
  Future<List<UbicacionMuelle>> ubicacionesMuelle() async {
    final todas = await ubicacionesCache.getAll();
    return [
      for (final u in todas)
        if (u.isADockAlter == true && u.id != null)
          UbicacionMuelle(
            id: u.id!,
            name: u.name ?? '',
            barcode: u.barcode ?? '',
            warehouseName: u.warehouseName ?? '',
          ),
    ];
  }
}
