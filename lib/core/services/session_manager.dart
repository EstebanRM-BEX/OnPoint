import 'package:flutter/foundation.dart';
import 'package:wms_app/core/services/barcodes_inventario_cache_service.dart';
import 'package:wms_app/core/services/configuracion_cache_service.dart';
import 'package:wms_app/core/services/interfaces/i_storage_service.dart';
import 'package:wms_app/core/services/interfaces/i_websocket_service.dart';
import 'package:wms_app/core/services/novedades_cache_service.dart';
import 'package:wms_app/core/services/packing_preservation.dart';
import 'package:wms_app/core/services/productos_cache_service.dart';
import 'package:wms_app/core/services/ubicaciones_cache_service.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/core/utils/widgets/app_restart_widget.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';

/// Punto único de cierre de sesión.
///
/// Limpia las tres capas donde vive el estado de la sesión —websocket,
/// preferencias, base de datos— y reinicia el árbol de widgets para que los
/// blocs del root se destruyan y se recreen limpios.
class SessionManager {
  const SessionManager._();

  /// [keepPackingData]: cierre automático (expiración): conserva packing para
  /// no perder productos "Preparado". El logout manual sigue borrando todo.
  static Future<void> closeSession({bool keepPackingData = false}) async {
    try {
      getIt<IWebSocketService>().disconnect();
    } catch (e) {
      debugPrint('⚠️ Error al desconectar websocket en logout: $e');
    }

    if (keepPackingData) await PackingPreservation.markOwner();
    await PrefUtils.clearPrefs();
    getIt<IStorageService>().removeUrlWebsite();
    await DataBaseSqlite().deleteBDCloseSession(keepPacking: keepPackingData);
    _invalidateMemoryCaches();
    await PrefUtils.setIsLoggedIn(false);

    // Recrea el árbol: los blocs se cierran y `CheckAuthPage` (initialRoute)
    // vuelve a evaluar la sesión y redirige a 'enterprice'.
    AppRestart.restart();
  }

  /// Los caches son `@lazySingleton` de `getIt`: sobreviven a
  /// [AppRestart.restart] (que solo recrea widgets/blocs). Sin esto, la
  /// siguiente sesión —otro cliente/almacén— lee la lista vieja en memoria
  /// aunque SQLite ya esté vacío.
  static void _invalidateMemoryCaches() {
    getIt<UbicacionesCacheService>().invalidate();
    getIt<ProductosCacheService>().invalidate();
    getIt<NovedadesCacheService>().invalidate();
    getIt<BarcodesInventarioCacheService>().invalidate();
    getIt<ConfiguracionCacheService>().invalidate();
  }
}
