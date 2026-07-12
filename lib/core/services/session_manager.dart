import 'package:flutter/foundation.dart';
import 'package:wms_app/core/services/interfaces/i_storage_service.dart';
import 'package:wms_app/core/services/interfaces/i_websocket_service.dart';
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

  static Future<void> closeSession() async {
    try {
      getIt<IWebSocketService>().disconnect();
    } catch (e) {
      debugPrint('⚠️ Error al desconectar websocket en logout: $e');
    }

    await PrefUtils.clearPrefs();
    getIt<IStorageService>().removeUrlWebsite();
    await DataBaseSqlite().deleteBDCloseSession();
    await PrefUtils.setIsLoggedIn(false);

    // Recrea el árbol: los blocs se cierran y `CheckAuthPage` (initialRoute)
    // vuelve a evaluar la sesión y redirige a 'enterprice'.
    AppRestart.restart();
  }
}
