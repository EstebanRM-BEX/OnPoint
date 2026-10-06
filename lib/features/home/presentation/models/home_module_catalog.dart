import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wms_app/core/utils/prefs/pref_keys.dart';

/// Módulos del home. El orden de declaración es el orden por defecto y el
/// `name` es el id que se persiste: no renombrar valores existentes.
enum HomeModuleId {
  picking('Picking', 'Preparación', Icons.assignment_turned_in_outlined),
  packing('Packing', 'Empaque', Icons.inventory_2_outlined),
  devolucion('Devolución', 'Retorno', Icons.keyboard_return),
  recepcion('Recepción', 'Ingreso mercancía', Icons.input),
  transferencia('Transferencia', 'Entre ubicaciones', Icons.sync_alt),
  inventario('Inventario', 'Conteo físico', Icons.shelves),
  componentes(
    'Componentes',
    'Picking componentes',
    Icons.settings_suggest_outlined,
  ),
  entradaProductos(
    'Entrada Prod.',
    'Entrega productos',
    Icons.move_to_inbox_outlined,
  ),
  infoRapida('Info Rápida', 'Consulta directa', Icons.qr_code_scanner),
  etiquetas('Etiquetas', 'Impresión', Icons.print_outlined),
  expedicion('Expedición', 'Despachos', Icons.local_shipping_outlined);

  final String title;
  final String subtitle;
  final IconData icon;

  const HomeModuleId(this.title, this.subtitle, this.icon);
}

/// Orden y visibilidad de los módulos del home.
class HomeModulesLayout {
  /// Todos los módulos (visibles y ocultos) en el orden elegido.
  final List<HomeModuleId> order;
  final Set<HomeModuleId> hidden;

  const HomeModulesLayout({required this.order, required this.hidden});

  static const int minVisible = 3;

  static const HomeModulesLayout defaults = HomeModulesLayout(
    order: HomeModuleId.values,
    hidden: {},
  );

  List<HomeModuleId> get visible =>
      order.where((id) => !hidden.contains(id)).toList();

  bool isVisible(HomeModuleId id) => !hidden.contains(id);

  /// Solo se puede ocultar si quedan más del mínimo visibles.
  bool canHide(HomeModuleId id) =>
      !isVisible(id) || visible.length > minVisible;

  List<HomeModuleId> get hiddenInOrder =>
      order.where((id) => hidden.contains(id)).toList();

  /// Deja [id] visible en la posición [index] (0-based) del home.
  HomeModulesLayout moveTo(HomeModuleId id, int index) {
    final newVisible = visible..remove(id);
    newVisible.insert(index.clamp(0, newVisible.length), id);
    final newHidden = {...hidden}..remove(id);
    return HomeModulesLayout(
      order: [...newVisible, ...hiddenInOrder.where((h) => h != id)],
      hidden: newHidden,
    );
  }

  /// Muestra [id] al final del home.
  HomeModulesLayout show(HomeModuleId id) => moveTo(id, visible.length);

  HomeModulesLayout hide(HomeModuleId id) =>
      HomeModulesLayout(order: order, hidden: {...hidden, id});
}

/// Persistencia por dispositivo en SharedPreferences. Las claves no están en
/// `PrefUtils.clearPrefs`/`clearSession`, así que sobreviven al logout.
abstract final class HomeModulesPrefs {
  static Future<HomeModulesLayout> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedOrder = prefs.getStringList(PrefKeys.homeModulesOrder);
    if (savedOrder == null) return HomeModulesLayout.defaults;

    final byName = {for (final id in HomeModuleId.values) id.name: id};
    final order = <HomeModuleId>[
      for (final name in savedOrder)
        if (byName[name] != null) byName[name]!,
    ];
    // Módulos nuevos (no guardados todavía) van al final y visibles.
    for (final id in HomeModuleId.values) {
      if (!order.contains(id)) order.add(id);
    }
    final hidden = <HomeModuleId>{
      for (final name
          in prefs.getStringList(PrefKeys.homeModulesHidden) ?? const [])
        if (byName[name] != null) byName[name]!,
    };
    return HomeModulesLayout(order: order, hidden: hidden);
  }

  static Future<void> save(HomeModulesLayout layout) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      PrefKeys.homeModulesOrder,
      layout.order.map((id) => id.name).toList(),
    );
    await prefs.setStringList(
      PrefKeys.homeModulesHidden,
      layout.hidden.map((id) => id.name).toList(),
    );
  }

  /// Estado del "Resumen operativo" (desplegado/contraído). Por dispositivo y
  /// no se borra al cerrar sesión; por defecto, desplegado.
  static Future<bool> loadSummaryExpanded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PrefKeys.homeSummaryExpanded) ?? true;
  }

  static Future<void> saveSummaryExpanded(bool expanded) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.homeSummaryExpanded, expanded);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PrefKeys.homeModulesOrder);
    await prefs.remove(PrefKeys.homeModulesHidden);
  }
}
