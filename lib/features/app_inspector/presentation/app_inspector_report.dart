import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:wms_app/core/utils/diagnostics/bloc_registry.dart';
import 'package:wms_app/core/utils/diagnostics/route_stack_tracker.dart';

/// Nodo del árbol montado desde `GetMaterialApp`. Si [isRoute], representa
/// una ruta del Navigator (pantalla o diálogo) y cuelga de ella su subárbol.
class MountNode {
  MountNode(
    this.label, {
    this.relevant = false,
    this.routeKind,
    this.isSelf = false,
    this.openedAt,
  });

  final String label;
  final bool relevant;

  /// null = widget normal; si no, ruta del Navigator.
  final RouteKind? routeKind;

  /// true en la ruta del propio diálogo del inspector.
  final bool isSelf;

  /// Cuándo se abrió la ruta (solo en nodos de ruta).
  final DateTime? openedAt;
  final List<MountNode> children = [];

  bool get isRoute => routeKind != null;
}

enum RouteKind { page, dialog }

/// Foto del estado de la UI y los Blocs para mostrarla y exportarla.
class AppInspectorReport {
  AppInspectorReport._({
    required this.takenAt,
    required this.snapshot,
    required this.routes,
    required this.blocs,
    required this.rssMb,
    required this.root,
    required this.truncated,
  });

  /// O(n) sobre el árbol de widgets: llamar solo al abrir o refrescar.
  factory AppInspectorReport.capture() {
    final (root, truncated) = _captureRoot();
    return AppInspectorReport._(
      takenAt: DateTime.now(),
      snapshot: RouteStackTracker.instance.snapshot(),
      routes: RouteStackTracker.instance.routes,
      blocs: AppBlocObserver.instance.all,
      rssMb: _rssMb(),
      root: root,
      truncated: truncated,
    );
  }

  final DateTime takenAt;
  final UiTreeSnapshot snapshot;
  final List<RouteInfo> routes;
  final List<BlocInfo> blocs;
  final int rssMb;

  /// Árbol montado desde `GetMaterialApp` (null si no hay árbol aún).
  final MountNode? root;

  /// true si se cortó al llegar al tope de nodos.
  final bool truncated;

  static const _maxNodes = 6000;

  /// El `_ModalScope` de cada ruta. Flutter monta debajo un
  /// `_ModalScopeStatus`, con el mismo prefijo, que no es una ruta: tomarlo
  /// como tal producía una "ruta" fantasma (de tipo diálogo) por cada pantalla.
  static final _modalScope = RegExp(r'^_ModalScope(<.*>)?$');

  static final _relevantName = RegExp(
    r'(Screen|Page|Dialog|Sheet|Scaffold|Bloc|Cubit|Provider|Listener|'
    r'Listenable|Tab|Overlay|AppBar|ListView|GridView|TextField|Form|'
    r'PopScope|Stack|Manager|Scope|App$|Navigator)',
  );

  /// Widgets internos de Flutter que coinciden con el patrón por nombre pero
  /// no se crean en el código de la app (DevTools los oculta por conocer la
  /// ubicación de creación; en release no hay forma de saberlo).
  static const _framework = {
    'MaterialApp',
    'WidgetsApp',
    'HeroControllerScope',
    'RootRestorationScope',
    'UnmanagedRestorationScope',
    'RestorationScope',
    'NotificationListener',
    'ScaffoldMessenger',
    'Navigator',
    'Overlay',
    'FocusScope',
    'PrimaryScrollController',
    'ScrollNotificationObserver',
  };

  /// Envoltorios genéricos que solo cuentan como "de la app" una vez dentro
  /// del código propio (antes son el andamiaje de MaterialApp).
  static const _wrappers = {'ListenableBuilder', 'ValueListenableBuilder'};

  static String _baseName(String name) {
    final i = name.indexOf('<');
    return i < 0 ? name : name.substring(0, i);
  }

  static bool _isRelevant(String name, {required bool inUserCode}) {
    if (name.startsWith('_') || !_relevantName.hasMatch(name)) return false;
    final base = _baseName(name);
    if (_framework.contains(base)) return false;
    if (_wrappers.contains(base) && !inUserCode) return false;
    return true;
  }

  /// Recorre el árbol desde `GetMaterialApp`. Cada `_ModalScope` se vuelve un
  /// nodo de ruta. Solo bajo demanda: es O(n) sobre todos los widgets.
  static (MountNode?, bool) _captureRoot() {
    final rootElement = WidgetsBinding.instance.rootElement;
    if (rootElement == null) return (null, false);

    Element? start;
    void find(Element e) {
      if (start != null) return;
      if (e.widget.runtimeType.toString() == 'GetMaterialApp') {
        start = e;
        return;
      }
      e.visitChildren(find);
    }

    find(rootElement);
    var count = 0;
    var truncated = false;

    MountNode? build(Element e, bool inUserCode) {
      if (count >= _maxNodes) {
        truncated = true;
        return null;
      }
      count++;
      final name = e.widget.runtimeType.toString();
      MountNode node;
      if (_modalScope.hasMatch(name)) {
        final route = _routeOf(e);
        final routeName = route == null
            ? 'ruta'
            : route.settings.name ??
                  route.runtimeType.toString().split('<').first;
        node = MountNode(
          routeName == kAppInspectorRouteName
              ? 'Inspector (este diálogo)'
              : routeName,
          relevant: true,
          routeKind: route is PageRoute ? RouteKind.page : RouteKind.dialog,
          isSelf: routeName == kAppInspectorRouteName,
          openedAt: route == null
              ? null
              : RouteStackTracker.instance.openedAtOf(route),
        );
      } else {
        node = MountNode(
          name,
          relevant: _isRelevant(name, inUserCode: inUserCode),
        );
      }
      // Desde el primer widget propio (p. ej. SessionTimeoutManager) hacia
      // abajo ya se está en código de la app.
      final childInUser =
          inUserCode || (node.relevant && _baseName(name) != 'GetMaterialApp');
      e.visitChildren((c) {
        final child = build(c, childInUser);
        if (child != null) node.children.add(child);
      });
      return node;
    }

    return (build(start ?? rootElement, false), truncated);
  }

  /// Ruta de un `_ModalScope`: se lee del `_ModalScopeStatus` descendiente.
  /// `ModalRoute.of` no sirve aquí: el primer hijo del scope queda por encima
  /// de ese InheritedWidget, y además registraría una dependencia.
  static ModalRoute<dynamic>? _routeOf(Element scope) {
    Element? status;
    void search(Element c) {
      if (status != null) return;
      if (c.widget.runtimeType.toString().startsWith('_ModalScopeStatus')) {
        status = c;
        return;
      }
      c.visitChildren(search);
    }

    scope.visitChildren(search);
    if (status == null) return null;
    try {
      final route = (status!.widget as dynamic).route;
      return route is ModalRoute<dynamic> ? route : null;
    } catch (_) {
      return null;
    }
  }

  /// Rutas montadas (base → cima) sin el diálogo del propio inspector.
  List<MountNode> get routeNodes {
    final out = <MountNode>[];
    void walk(MountNode n) {
      if (n.isRoute && !n.isSelf) out.add(n);
      for (final c in n.children) {
        walk(c);
      }
    }

    final r = root;
    if (r != null) walk(r);
    return out;
  }

  /// Pantallas apiladas.
  List<MountNode> get pageNodes =>
      routeNodes.where((n) => n.routeKind == RouteKind.page).toList();

  /// Diálogos, bottom sheets y menús abiertos.
  List<MountNode> get dialogNodes =>
      routeNodes.where((n) => n.routeKind == RouteKind.dialog).toList();

  static final _contentName = RegExp(r'(Dialog|Screen|Page|Sheet|Scope)');

  /// Envoltorios que no dicen qué contiene la ruta.
  static const _generic = {
    'PageStorage',
    'ListenableBuilder',
    'ValueListenableBuilder',
    'DisplayFeatureSubScreen',
    'Stack',
    'Listener',
    'Scaffold',
    'PopScope',
    'AnnotatedRegion',
    'BlocProvider',
    'BlocBuilder',
    'BlocListener',
    'BlocConsumer',
    'InheritedProvider',
  };

  /// Qué widget propio muestra la ruta (p. ej. `DialogLoading`, `HomePage`):
  /// el primer descendiente relevante con nombre de pantalla o diálogo; si no
  /// hay, el primero relevante que no sea un envoltorio genérico.
  static String? contentOf(MountNode route) {
    String? fallback;
    String? found;
    void walk(MountNode n) {
      if (found != null) return;
      for (final c in n.children) {
        if (found != null) return;
        if (c.isRoute) continue;
        final base = _baseName(c.label);
        if (c.relevant && !_generic.contains(base)) {
          if (_contentName.hasMatch(base)) {
            found = c.label;
            return;
          }
          fallback ??= c.label;
        }
        walk(c);
      }
    }

    walk(route);
    return found ?? fallback;
  }

  int get alive => blocs.where((b) => !b.isClosed).length;
  int get closed => blocs.length - alive;

  static int _rssMb() {
    try {
      return ProcessInfo.currentRss ~/ (1024 * 1024);
    } catch (_) {
      return -1;
    }
  }

  static String hhmmss(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:'
      '${t.second.toString().padLeft(2, '0')}';

  /// Reporte en texto plano para copiar/compartir.
  String toText() {
    final b = StringBuffer()
      ..writeln('REPORTE INSPECTOR — ${hhmmss(takenAt)}')
      ..writeln('Pantallas: ${snapshot.pages}')
      ..writeln('Diálogos/overlays: ${snapshot.overlays}')
      ..writeln('Widgets vivos: ${snapshot.elements}')
      ..writeln('Memoria (RSS): $rssMb MB')
      ..writeln('Blocs vivos: $alive · cerrados: $closed')
      ..writeln()
      ..writeln('RUTAS (base → cima)');
    for (final r in routes) {
      b.writeln(
        '- [${r.isPage ? 'pantalla' : 'diálogo'}] ${r.name} '
        '(${hhmmss(r.openedAt)})',
      );
    }
    void detail(String title, List<MountNode> nodes) {
      b
        ..writeln()
        ..writeln('$title (${nodes.length})');
      for (final n in nodes) {
        final content = contentOf(n);
        final at = n.openedAt;
        b.writeln(
          '- ${n.label}'
          '${content == null ? '' : ' → $content'}'
          '${at == null ? '' : ' (${hhmmss(at)})'}',
        );
      }
    }

    detail('PANTALLAS APILADAS (base → cima)', pageNodes);
    detail('DIÁLOGOS ABIERTOS', dialogNodes);
    b
      ..writeln()
      ..writeln('ÁRBOL DESDE GetMaterialApp (solo relevantes)');
    void dump(MountNode n, int depth) {
      final show = n.relevant;
      if (show) {
        final tag = n.isRoute
            ? '[${n.routeKind == RouteKind.page ? 'pantalla' : 'diálogo'}] '
            : '';
        b.writeln('${'  ' * depth}$tag${n.label}');
      }
      for (final c in n.children) {
        dump(c, show ? depth + 1 : depth);
      }
    }

    if (root != null) dump(root!, 0);
    b
      ..writeln()
      ..writeln('BLOCS');
    for (final i in blocs) {
      b.writeln(
        '- ${i.isClosed ? 'CERRADO' : 'VIVO'} ${i.name} · '
        'estado=${i.lastState} · evento=${i.lastEvent} · '
        'cambios=${i.changes} · creado=${hhmmss(i.createdAt)}'
        '${i.isClosed ? ' · cerrado=${hhmmss(i.closedAt!)}' : ''}',
      );
    }
    return b.toString();
  }
}
