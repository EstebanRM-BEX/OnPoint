import 'package:shared_preferences/shared_preferences.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';

/// Conserva los datos locales de packing cuando la sesión se cierra sola.
///
/// Un operario puede tener productos "Preparado" (separados y certificados,
/// aún sin empacar) que solo existen en SQLite. Si la sesión expira o se
/// cierra de forma forzada, borrarlos obliga a rehacer el trabajo.
///
/// Para no mostrar datos de otra persona, se guarda a quién pertenecen los
/// datos locales (empresa + usuario) en cada login. Si el dueño es otro, se
/// borra todo antes de continuar.
class PackingPreservation {
  const PackingPreservation._();

  static const _kOwner = 'packing_preserved_owner';

  /// Llamar ANTES de limpiar las prefs (necesita empresa y usuario vigentes).
  static Future<void> markOwner() async {
    final enterprise = await PrefUtils.getEnterprise();
    final userId = await PrefUtils.getUserId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kOwner, '$enterprise|$userId');
  }

  /// Llamar al guardar la sesión de un login exitoso.
  ///
  /// Compara el dueño guardado con la empresa + usuario que acaba de entrar.
  /// Si cambió —o no se sabe de quién son los datos locales— se borra TODO lo
  /// local: no solo packing, porque entrar a otra empresa sin pasar por un
  /// cierre de sesión (error al arrancar, cambio de URL en "enterprice")
  /// dejaba pedidos de la empresa anterior a la vista.
  static Future<void> reconcileOnLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kOwner);

    final enterprise = await PrefUtils.getEnterprise();
    final userId = await PrefUtils.getUserId();
    final current = '$enterprise|$userId';

    if (stored != current) {
      await DataBaseSqlite().deleteBDCloseSession();
    }
    await prefs.setString(_kOwner, current);
  }
}
