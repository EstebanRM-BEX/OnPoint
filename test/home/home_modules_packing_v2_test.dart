import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wms_app/core/utils/prefs/pref_keys.dart';
import 'package:wms_app/features/home/presentation/models/home_module_catalog.dart';

/// El packing por pedido nuevo convive con el actual: nace oculto en todos
/// los dispositivos y solo aparece si alguien lo habilita.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('dispositivo sin configuración: el módulo nuevo está oculto', () async {
    final layout = await HomeModulesPrefs.load();
    expect(layout.isVisible(HomeModuleId.packingPedidoV2), isFalse);
    expect(layout.isVisible(HomeModuleId.packing), isTrue);
  });

  test(
    'configuración guardada antes de existir el módulo: entra oculto',
    () async {
      SharedPreferences.setMockInitialValues({
        PrefKeys.homeModulesOrder: [
          for (final id in HomeModuleId.values)
            if (id != HomeModuleId.packingPedidoV2) id.name,
        ],
        PrefKeys.homeModulesHidden: <String>[],
      });
      final layout = await HomeModulesPrefs.load();
      expect(layout.order.last, HomeModuleId.packingPedidoV2);
      expect(layout.isVisible(HomeModuleId.packingPedidoV2), isFalse);
    },
  );

  test('habilitado en el editor: queda visible al recargar', () async {
    final habilitado = (await HomeModulesPrefs.load()).show(
      HomeModuleId.packingPedidoV2,
    );
    await HomeModulesPrefs.save(habilitado);

    final layout = await HomeModulesPrefs.load();
    expect(layout.isVisible(HomeModuleId.packingPedidoV2), isTrue);
    expect(layout.visible.last, HomeModuleId.packingPedidoV2);
  });

  test('restablecer vuelve a ocultarlo', () async {
    await HomeModulesPrefs.save(
      HomeModulesLayout.defaults.show(HomeModuleId.packingPedidoV2),
    );
    await HomeModulesPrefs.reset();
    final layout = await HomeModulesPrefs.load();
    expect(layout.isVisible(HomeModuleId.packingPedidoV2), isFalse);
  });
}
