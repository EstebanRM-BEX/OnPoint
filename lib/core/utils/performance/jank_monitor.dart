import 'dart:async';
import 'dart:ui' show FrameTiming;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Mide la fluidez de cada pantalla y la envía a Firebase Performance.
///
/// Por cada pantalla visible se abre una traza `screen_<ruta>` con métricas:
/// - `frames_total`: frames renderizados mientras la pantalla estuvo visible.
/// - `frames_slow`: build o raster por encima del presupuesto de 16 ms.
/// - `frames_frozen`: frames de más de 700 ms (la app se ve congelada).
/// - `frame_max_ms`: el peor frame de la visita.
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

  static const _slowFrameBudget = Duration(microseconds: 16667);
  static const _frozenFrameMs = 700;

  bool _isMonitoring = false;
  AppLifecycleListener? _lifecycle;
  String _currentScreen = 'inicio';

  Trace? _trace;
  int _framesTotal = 0;
  int _framesSlow = 0;
  int _framesFrozen = 0;
  int _frameMaxMs = 0;

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

  void _startTrace(String screen) {
    _framesTotal = _framesSlow = _framesFrozen = _frameMaxMs = 0;
    final trace = FirebasePerformance.instance.newTrace(_traceName(screen));
    _trace = trace;
    unawaited(trace.start());
  }

  void _stopTrace() {
    final trace = _trace;
    _trace = null;
    if (trace == null) return;
    // Visitas sin frames (rutas que se reemplazan al instante) no aportan.
    if (_framesTotal == 0) return;
    trace
      ..setMetric('frames_total', _framesTotal)
      ..setMetric('frames_slow', _framesSlow)
      ..setMetric('frames_frozen', _framesFrozen)
      ..setMetric('frame_max_ms', _frameMaxMs);
    unawaited(trace.stop());
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final totalMs = timing.totalSpan.inMilliseconds;
      _framesTotal++;
      if (totalMs > _frameMaxMs) _frameMaxMs = totalMs;
      if (timing.buildDuration > _slowFrameBudget ||
          timing.rasterDuration > _slowFrameBudget) {
        _framesSlow++;
      }
      if (totalMs > _frozenFrameMs) {
        _framesFrozen++;
        FirebaseCrashlytics.instance.log(
          'FROZEN FRAME | Screen: $_currentScreen | Total: ${totalMs}ms | '
          'Build: ${timing.buildDuration.inMilliseconds}ms | '
          'Raster: ${timing.rasterDuration.inMilliseconds}ms',
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
