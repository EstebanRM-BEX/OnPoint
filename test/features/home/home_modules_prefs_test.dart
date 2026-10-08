import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wms_app/core/utils/prefs/pref_keys.dart';
import 'package:wms_app/features/home/presentation/models/home_module_catalog.dart';

void main() {
  test('Info Rápida es visible por defecto', () async {
    SharedPreferences.setMockInitialValues({});

    final layout = await HomeModulesPrefs.load();

    expect(layout.isVisible(HomeModuleId.infoRapida), isTrue);
  });

  test('ignora el módulo de pruebas "infoRapidaV2" guardado en el dispositivo',
      () async {
    // Fase 5 lo agregó como módulo aparte; en la fase 7 Info Rápida ya abre
    // el módulo nuevo y ese id dejó de existir.
    SharedPreferences.setMockInitialValues({
      PrefKeys.homeModulesOrder: ['infoRapidaV2', 'infoRapida', 'picking'],
      PrefKeys.homeModulesHidden: <String>[],
    });

    final layout = await HomeModulesPrefs.load();

    expect(layout.visible.first, HomeModuleId.infoRapida);
    expect(layout.order.map((id) => id.name), isNot(contains('infoRapidaV2')));
  });
}
