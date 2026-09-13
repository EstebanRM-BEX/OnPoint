import 'package:injectable/injectable.dart';
import 'package:wms_app/features/user/data/models/user_configuration_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';

/// Cache en memoria de la configuración/permisos del usuario
/// (tbl_configurations), compartido por toda la app. A diferencia de
/// ubicaciones/productos/novedades, acá no hay riesgo de aliasing (el bug
/// de "clear() vacía el cache" de Productos/UbicacionesCacheService):
/// [UserConfigurationModel]/[UserConfiguration]/[UserProfile] son clases
/// inmutables (`final`, `const`), nadie puede mutarlas en el sitio.
///
/// Se cachea por [userId] (la config es por usuario, no global) — en la
/// práctica hay un solo usuario activo por sesión, pero se guarda con esa
/// llave por si alguna vez conviven dos.
///
/// Se sincroniza en un solo lugar (UserBloc._onLoadUserInfo, al login,
/// después de traerla por red) — [invalidate] se llama justo después de
/// esa escritura para que ~26 lectores (screens/blocs que hoy hacen su
/// propia consulta a `configurationsRepository.getConfiguration(userId)`
/// en su `initState`/handler) tomen el dato fresco.
@lazySingleton
class ConfiguracionCacheService {
  final Map<int, UserConfigurationModel?> _cache = {};

  Future<UserConfigurationModel?> getConfiguration(
    int userId, {
    bool forceRefresh = false,
  }) async {
    if (!_cache.containsKey(userId) || forceRefresh) {
      _cache[userId] = await DataBaseSqlite().configurationsRepository
          .getConfiguration(userId);
    }
    return _cache[userId];
  }

  /// Recarga desde SQLite — usar tras guardar una configuración nueva
  /// (UserBloc._onLoadUserInfo, justo después de insertConfiguration).
  void invalidate([int? userId]) {
    if (userId != null) {
      _cache.remove(userId);
    } else {
      _cache.clear();
    }
  }
}
