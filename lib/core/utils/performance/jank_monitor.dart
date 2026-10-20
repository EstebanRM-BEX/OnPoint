import 'dart:async';
import 'dart:io' show ProcessInfo;
import 'dart:ui' show FrameTiming;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wms_app/core/utils/performance/frame_stats.dart';

/// Mide la fluidez de cada pantalla y la envía a Firebase Performance.
///
/// Por cada pantalla visible se abre una traza `screen_<ruta>` con métricas:
/// - `frames_total`: frames renderizados mientras la pantalla estuvo visible.
/// - `frames_slow`: build o raster por encima del presupuesto de 16 ms.
/// - `frames_frozen`: frames de más de 700 ms (la app se ve congelada).
/// - `frame_max_ms`: el peor frame de la visita.
/// - `frames_build_heavy`: frames cuyo build (reconstrucción de widgets)
///   pasó los 16 ms.
/// - `frames_sync` / `frames_slow_sync`: frames (y frames lentos) durante una
///   sincronización de datos; atributo `sync_activo` = `si`/`no`.
/// - `rss_inicio_mb` / `rss_fin_mb`: memoria del proceso al abrir y al cerrar
///   la visita.
///
/// Ver [FrameStats] y docs/plan_performance_pantallas.md (fase 0).
///
/// En la consola de Performance (Personalizado → trazas `screen_*`) se ve el
/// % de jank por pantalla, filtrable por versión, dispositivo y país.
///
/// Antes cada jank de más de 200 ms se enviaba como error no fatal a
/// Crashlytics: todos quedaban agrupados en un solo issue (mismo stack) y
/// consumían el cupo de no fatales por sesión de los errores reales. Ahora a
/// Crashlytics solo van breadcrumbs de frames congelados y la pantalla actual
/// como custom key, para dar contexto a los crashes.
class JankMonitor {
  static final JankMonitor _instance = JankMonitor._internal();
  factory JankMonitor() => _instance;
  JankMonitor._internal();

  bool _isMonitoring = false;
  AppLifecycleListener? _lifecycle;
  String _currentScreen = 'inicio';

  /// Pantalla visible actual (la mantiene [JankRouteObserver]).
  String get currentScreen => _currentScreen;

  Trace? _trace;
  final FrameStats _stats = FrameStats();

  /// Hay una sincronización de datos en curso. Lo configura `main.dart` (este
  /// monitor no depende de los servicios de sincronización).
  bool Function() sincronizando = () => false;

  void start() {
    // En debug todos los frames son lentos (JIT, asserts): solo ensucia datos.
    if (_isMonitoring || kDebugMode) return;
    _isMonitoring = true;
    WidgetsBinding.instance.addTimingsCallback(_onTimings);
    _startTrace(_currentScreen);
    // Una traza sin stop nunca se sube: si Android mata la app en segundo
    // plano, la visita se perdería. Se cierra al ocultarse y se reabre al volver.
    _lifecycle = AppLifecycleListener(
      onHide: _stopTrace,
      onShow: () => _startTrace(_currentScreen),
    );
  }

  void stop() {
    WidgetsBinding.instance.removeTimingsCallback(_onTimings);
    _lifecycle?.dispose();
    _lifecycle = null;
    _stopTrace();
    _isMonitoring = false;
  }

  /// Cierra la traza de la pantalla anterior y abre la de [name].
  void setContext(String name) {
    if (name == _currentScreen && _trace != null) return;
    _currentScreen = name;
    if (!_isMonitoring) return;
    FirebaseCrashlytics.instance.setCustomKey('screen', name);
    _stopTrace();
    _startTrace(name);
  }

  /// RSS del proceso en MB: métricas `rss_inicio_mb`/`rss_fin_mb` de cada
  /// visita, para ver qué pantallas hacen crecer la memoria (el aviso
  /// `memoria_alta` de Crashlytics solo dice dónde se cruzó el umbral).
  static int get _rssMb => ProcessInfo.currentRss >> 20;
  int _rssInicioMb = 0;

  void _startTrace(String screen) {
    _stats.reset();
    _rssInicioMb = _rssMb;
    final trace = FirebasePerformance.instance.newTrace(_traceName(screen));
    _trace = trace;
    unawaited(trace.start());
  }

  void _stopTrace() {
    final trace = _trace;
    _trace = null;
    if (trace == null) return;
    // Visitas sin frames (rutas que se reemplazan al instante) no aportan.
    if (_stats.total == 0) return;
    _stats.metricas.forEach(trace.setMetric);
    trace
      ..setMetric('rss_inicio_mb', _rssInicioMb)
      ..setMetric('rss_fin_mb', _rssMb)
      ..putAttribute('sync_activo', _stats.syncActivo);
    unawaited(trace.stop());
  }

  void _onTimings(List<FrameTiming> timings) {
    // Una consulta por lote de frames (el callback llega cada ~100 ms).
    var sync = false;
    try {
      sync = sincronizando();
    } catch (_) {}
    for (final timing in timings) {
      final totalMs = timing.totalSpan.inMilliseconds;
      _stats.registrar(
        totalMs: totalMs,
        buildUs: timing.buildDuration.inMicroseconds,
        rasterUs: timing.rasterDuration.inMicroseconds,
        sincronizando: sync,
      );
      if (totalMs > FrameStats.congeladoMs) {
        FirebaseCrashlytics.instance.log(
          'FROZEN FRAME | Screen: $_currentScreen | Total: ${totalMs}ms | '
          'Build: ${timing.buildDuration.inMilliseconds}ms | '
          'Raster: ${timing.rasterDuration.inMilliseconds}ms | '
          'Sync: ${sync ? 'si' : 'no'}',
        );
      }
    }
  }

  /// Firebase exige nombres de traza de hasta 100 caracteres, sin `_` inicial.
  static String _traceName(String screen) {
    final clean = screen
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final name = 'screen_${clean.isEmpty ? 'root' : clean}';
    return name.length > 100 ? name.substring(0, 100) : name;
  }
}

/// Avisa a [JankMonitor] qué pantalla está visible. Los diálogos y bottom
/// sheets no son `PageRoute`: sus frames cuentan para la pantalla de abajo.
class JankRouteObserver extends NavigatorObserver {
  void _updateScreenName(Route<dynamic>? route) {
    if (route is PageRoute && route.settings.name != null) {
      JankMonitor().setContext(route.settings.name!);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateScreenName(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // Al volver atrás, la pantalla visible es la ruta previa.
    if (route is PageRoute) _updateScreenName(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _updateScreenName(newRoute);
  }
}
