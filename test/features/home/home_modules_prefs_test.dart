import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wms_app/core/utils/prefs/pref_keys.dart';
import 'package:wms_app/features/home/presentation/models/home_module_catalog.dart';

void main() {
  test('infoRapidaV2 nace oculto en una instalación nueva', () async {
    SharedPreferences.setMockInitialValues({});

    final layout = await HomeModulesPrefs.load();

    expect(layout.isVisible(HomeModuleId.infoRapidaV2), isFalse);
    expect(layout.isVisible(HomeModuleId.infoRapida), isTrue);
  });

  test('infoRapidaV2 queda oculto en dispositivos con orden ya guardado',
      () async {
    SharedPreferences.setMockInitialValues({
      PrefKeys.homeModulesOrder: ['infoRapida', 'picking'],
      PrefKeys.homeModulesHidden: <String>[],
    });

    final layout = await HomeModulesPrefs.load();

    expect(layout.order.last, HomeModuleId.infoRapidaV2);
    expect(layout.isVisible(HomeModuleId.infoRapidaV2), isFalse);
    expect(layout.visible.first, HomeModuleId.infoRapida);
  });

  test('se puede habilitar desde el editor', () async {
    SharedPreferences.setMockInitialValues({});

    final layout = (await HomeModulesPrefs.load()).show(HomeModuleId.infoRapidaV2);
    await HomeModulesPrefs.save(layout);
    final reloaded = await HomeModulesPrefs.load();

    expect(reloaded.isVisible(HomeModuleId.infoRapidaV2), isTrue);
  });
}
