import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/src/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/features/login/domain/entities/user.dart';

/// Local data source for login operations.
/// Handles saving user session data with encrypted password.
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
      // Encrypt password before saving
      final encryptedPassword = _encryptPassword(password);

      // Save user data to SharedPreferences
      await PrefUtils.setUserName(user.name);
      await PrefUtils.setUserEmail(user.username);
      await PrefUtils.setUserPass(encryptedPassword);
      await PrefUtils.setUserId(user.uid);
      await PrefUtils.setIsLoggedIn(true);
      await PrefUtils.saveLastActiveTime();
    } catch (e) {
      throw CacheException('Error al guardar sesión: $e');
    }
  }

  /// Encrypt password using SHA-256
  String _encryptPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
