import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/core/utils/prefs/secure_storage_utils.dart';
import 'package:wms_app/features/login/domain/entities/user.dart';

/// Local data source for login operations.
/// Saves user session data; the password goes to SecureStorage (Keystore/Keychain),
/// never to SharedPreferences.
abstract class LoginLocalDataSource {
  Future<void> saveUserSession({
    required User user,
    required String password,
  });
}

@LazySingleton(as: LoginLocalDataSource)
class LoginLocalDataSourceImpl implements LoginLocalDataSource {
  LoginLocalDataSourceImpl();

  @override
  Future<void> saveUserSession({
    required User user,
    required String password,
  }) async {
    try {
      await SecureStorage.setUserPass(password);
      // Limpia el password que versiones anteriores guardaban en SharedPreferences
      await PrefUtils.removeLegacyPass();

      // Save user data to SharedPreferences
      await PrefUtils.setUserName(user.name);
      await PrefUtils.setUserEmail(user.username);
      await PrefUtils.setUserId(user.uid);
      await PrefUtils.setIsLoggedIn(true);
      await PrefUtils.saveLastActiveTime();
    } catch (e) {
      throw CacheException('Error al guardar sesión: $e');
    }
  }
}
