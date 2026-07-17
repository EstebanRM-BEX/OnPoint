import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento seguro para datos sensibles (Keystore en Android / Keychain en iOS).
/// El password NUNCA debe guardarse en SharedPreferences: usar siempre esta clase.
class SecureStorage {
  SecureStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyUserPass = 'user_pass';

  static Future<void> setUserPass(String pass) =>
      _storage.write(key: _keyUserPass, value: pass);

  static Future<String> getUserPass() async =>
      await _storage.read(key: _keyUserPass) ?? '';

  static Future<void> deleteUserPass() => _storage.delete(key: _keyUserPass);
}
