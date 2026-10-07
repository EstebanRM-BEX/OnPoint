import 'package:flutter/widgets.dart';

/// Foto del árbol de navegación y de widgets en un instante.
class UiTreeSnapshot {
  const UiTreeSnapshot({
    required this.pages,
    required this.overlays,
    required this.elements,
    required this.stack,
  });

  /// Pantallas (`PageRoute`) apiladas.
  final int pages;

  /// Diálogos, bottom sheets y menús (`PopupRoute`/`ModalRoute` no página).
  final int overlays;

  /// Elementos vivos en el árbol de widgets (-1 si no se pudo contar).
  final int elements;

  /// Últimas rutas del stack, de la base a la cima.
  final String stack;

  @override
  String toString() =>
      'pages=$pages overlays=$overlays elements=$elements stack=$stack';
}

/// Ruta abierta, para listarla en el inspector.
class RouteInfo {
  const RouteInfo({
    required this.name,
    required this.isPage,
    required this.openedAt,
  });

  final String name;

  /// true = pantalla; false = diálogo/bottom sheet/menú.
  final bool isPage;
  final DateTime openedAt;
}

/// Nombre de la ruta del propio inspector: se excluye de los conteos.
const kAppInspectorRouteName = 'app_inspector';

/// Lleva el stack de rutas del Navigator raíz para detectar pantallas o
/// diálogos que se acumulan. Se registra en `navigatorObservers`.
class RouteStackTracker extends NavigatorObserver {
  RouteStackTracker._();
  static final RouteStackTracker instance = RouteStackTracker._();

  final List<Route<dynamic>> _routes = [];
  final Map<Route<dynamic>, DateTime> _openedAt = {};

  bool _tracked(Route<dynamic> r) => r.settings.name != kAppInspectorRouteName;

  /// Stack actual (base → cima) sin el diálogo del inspector.
  List<RouteInfo> get routes => [
    for (final r in _routes)
      if (_tracked(r))
        RouteInfo(
          name: _name(r),
          isPage: r is PageRoute,
          openedAt: _openedAt[r] ?? DateTime.now(),
        ),
  ];

  /// Cuándo se abrió [route] (null si no es una ruta registrada).
  DateTime? openedAtOf(Route<dynamic> route) => _openedAt[route];

  static String _name(Route<dynamic> r) =>
      r.settings.name ?? r.runtimeType.toString().split('<').first;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
    _openedAt[route] = DateTime.now();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _forget(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _forget(route);

  void _forget(Route<dynamic> route) {
    _routes.remove(route);
    _openedAt.remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (i >= 0) {
      _openedAt.remove(_routes[i]);
      if (newRoute == null) {
        _routes.removeAt(i);
      } else {
        _routes[i] = newRoute;
        _openedAt[newRoute] = DateTime.now();
      }
    } else if (newRoute != null) {
      _routes.add(newRoute);
      _openedAt[newRoute] = DateTime.now();
    }
  }

  /// Cuenta el stack y recorre el árbol de widgets (O(n); llamar con poca
  /// frecuencia, p. ej. en el latido de 1 min).
  UiTreeSnapshot snapshot({int tail = 6}) {
    final tracked = _routes.where(_tracked).toList();
    final pages = tracked.whereType<PageRoute>().length;
    final names = tracked.map(_name).toList();
    final shown = names.length > tail
        ? names.sublist(names.length - tail)
        : names;

    var elements = -1;
    final root = WidgetsBinding.instance.rootElement;
    if (root != null) {
      elements = 0;
      void visit(Element e) {
        elements++;
        e.visitChildren(visit);
      }

      visit(root);
    }

    return UiTreeSnapshot(
      pages: pages,
      overlays: tracked.length - pages,
      elements: elements,
      stack: shown.join(' > '),
    );
  }
}
