import 'package:injectable/injectable.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/features/auth/data/models/session_model.dart';

/// Data source abstracto para operaciones de autenticación locales
abstract class AuthLocalDataSource {
  Future<SessionModel> getSession();
  Future<void> clearSession();
  Future<void> updateLastActiveTime();
}

/// Implementación del data source local usando PrefUtils
@LazySingleton(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  @override
  Future<SessionModel> getSession() async {
    final isLoggedIn = await PrefUtils.getIsLoggedIn();
    final lastActiveTime = await PrefUtils.getLastActiveTime();
    final userId = await PrefUtils.getUserId();

    return SessionModel.fromPrefs(
      isLoggedIn: isLoggedIn,
      lastActiveTime: lastActiveTime,
      userId: userId,
    );
  }

  @override
  Future<void> clearSession() async {
    await PrefUtils.clearSession();
  }

  @override
  Future<void> updateLastActiveTime() async {
    await PrefUtils.saveLastActiveTime();
  }
}
