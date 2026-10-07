import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wms_app/core/utils/prefs/pref_keys.dart';
import 'package:wms_app/features/home/presentation/models/home_module_catalog.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('por defecto el Resumen operativo está desplegado', () async {
    expect(await HomeModulesPrefs.loadSummaryExpanded(), isTrue);
  });

  test('contraer se guarda y se lee después', () async {
    await HomeModulesPrefs.saveSummaryExpanded(false);
    expect(await HomeModulesPrefs.loadSummaryExpanded(), isFalse);

    await HomeModulesPrefs.saveSummaryExpanded(true);
    expect(await HomeModulesPrefs.loadSummaryExpanded(), isTrue);
  });

  test('restablecer el layout del home no toca el estado del resumen',
      () async {
    await HomeModulesPrefs.saveSummaryExpanded(false);
    await HomeModulesPrefs.reset();
    expect(await HomeModulesPrefs.loadSummaryExpanded(), isFalse);
  });

  test('la clave no está entre las que se borran al cerrar sesión', () async {
    // clearPrefs/clearSession solo remueven claves concretas (usuario,
    // cookie, empresa…); esta es una preferencia del dispositivo.
    SharedPreferences.setMockInitialValues({PrefKeys.homeSummaryExpanded: false});
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      PrefKeys.cookie,
      PrefKeys.userId,
      PrefKeys.isLoggedIn,
    ]) {
      await prefs.remove(key);
    }
    expect(await HomeModulesPrefs.loadSummaryExpanded(), isFalse);
  });
}
