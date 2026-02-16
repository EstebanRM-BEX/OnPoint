import 'package:wms_app/core/utils/prefs/pref_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefUtils {
  PrefUtils();

  static setEnterprise(String enterprise) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(PrefKeys.enterprise, enterprise);
  }

  static Future<String> getEnterprise() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(PrefKeys.enterprise) ?? "";
  }

  static setIsLoggedIn(bool isLoggedIn) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(PrefKeys.isLoggedIn, isLoggedIn);
  }

  static Future<bool> getIsLoggedIn() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getBool(PrefKeys.isLoggedIn) ?? false;
  }

  static getUserPass() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(PrefKeys.pass) ?? "";
  }

//guardamos la cookie de la ultima petición
  static Future<void> setCookie(String cookie) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(PrefKeys.cookie, cookie);
  }

//obtenemos la cookie de la ultima petición
  static Future<String> getCookie() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(PrefKeys.cookie) ?? "";
  }

  // Guardar la hora actual como última actividad
  static Future<void> saveLastActiveTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_active_time', DateTime.now().toIso8601String());
  }

  // Obtener la última hora registrada
  static Future<DateTime?> getLastActiveTime() async {
    final prefs = await SharedPreferences.getInstance();
    final String? timeStr = prefs.getString('last_active_time');
    if (timeStr == null) return null;
    return DateTime.tryParse(timeStr);
  }

  //TODO GUARDAMOS LOS DATOS DE LA PDA

  static Future<void> setMacPDA(String mac) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(PrefKeys.macPDA, mac);
  }

  static Future<String> getMacPDA() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(PrefKeys.macPDA) ?? "";
  }

  static Future<void> setImeiPDA(String imei) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(PrefKeys.imeiPDA, imei);
  }

  static Future<String> getImeiPDA() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(PrefKeys.imeiPDA) ?? "";
  }

  static Future<void> setModeloPDA(String modelo) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(PrefKeys.modeloPDA, modelo);
  }

  static Future<String> getModeloPDA() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(PrefKeys.modeloPDA) ?? "";
  }

  static Future<void> setFabricantePDA(String fabricante) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(PrefKeys.fabricantePDA, fabricante);
  }

  static Future<String> getFabricantePDA() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(PrefKeys.fabricantePDA) ?? "";
  }

//todo guardamos los datos del usuario
//*nombre
  static Future<void> setUserName(String name) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(PrefKeys.user, name);
  }

//*correo
  static Future<void> setUserEmail(String email) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(PrefKeys.email, email);
  }

//*rol
  static Future<void> setUserRol(String rol) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(PrefKeys.rol, rol);
  }

//user id
  static Future<void> setUserId(int id) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setInt(PrefKeys.userId, id);
  }

//obtenemos el id del usuario
  static Future<int> getUserId() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getInt(PrefKeys.userId) ?? 0;
  }

//*contraseña
  static Future<void> setUserPass(String pass) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(PrefKeys.pass, pass);
  }

//*obtenemos los datos del usuario
  static Future<String> getUserName() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(PrefKeys.user) ?? "";
  }

  static Future<String> getUserEmail() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(PrefKeys.email) ?? "";
  }

  static Future<String> getUserRol() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(PrefKeys.rol) ?? "";
  }

  //METODO PARA ELIMINAR LOS DATOS DEL USUARIO
  static Future<void> clearUserData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(PrefKeys.user);
    await preferences.remove(PrefKeys.email);
    await preferences.remove(PrefKeys.pass);
    await preferences.remove(PrefKeys.userId);
    await preferences.remove(PrefKeys.rol);
    await preferences.remove(PrefKeys.isLoggedIn);
  }

  //metodo apra borrar los prefs pero no los de la pda
  static Future<void> clearPrefs() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(PrefKeys.enterprise);
    await preferences.remove(PrefKeys.cookie);
    await preferences.remove(PrefKeys.isLoggedIn);
    await preferences.remove(PrefKeys.urlWebsite);
    await preferences.remove(PrefKeys.userId);
    await preferences.remove(PrefKeys.user);
    await preferences.remove(PrefKeys.email);
    await preferences.remove(PrefKeys.pass);
    await preferences.remove(PrefKeys.rol);
  }

  static Future<void> clearSession() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    // 1. Borramos la hora de actividad (CRÍTICO para que no haga loop infinito de logout)
    await preferences.remove('last_active_time');

    // 2. Marcamos al usuario como deslogueado
    await preferences.setBool(PrefKeys.isLoggedIn, false);

    // 3. Limpiamos datos sensibles de la sesión actual
    await preferences.remove(PrefKeys.cookie);
    await preferences.remove(PrefKeys.pass);
    await preferences.remove(PrefKeys.user);
    await preferences.remove(PrefKeys.userId);
    await preferences.remove(PrefKeys.email);
    await preferences.remove(PrefKeys.rol);

    // NOTA: No borramos Enterprise ni datos de la PDA (Mac, Imei)
    // porque esos deben persistir aunque el usuario cierre sesión.
  }
}
