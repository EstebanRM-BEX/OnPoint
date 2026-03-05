import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class JankMonitor {
  static final JankMonitor _instance = JankMonitor._internal();
  factory JankMonitor() => _instance;
  JankMonitor._internal();

  bool _isMonitoring = false;

  // ✅ NUEVO: Variable para saber dónde estamos
  String _currentScreen = "Inicio / Desconocido";

  // ✅ NUEVO: Setter para actualizar manualmente (si quieres trackear funciones)
  void setContext(String name) {
    _currentScreen = name;
  }

  void start() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    WidgetsBinding.instance.addTimingsCallback(_onTimings);
  }

  void stop() {
    WidgetsBinding.instance.removeTimingsCallback(_onTimings);
    _isMonitoring = false;
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final duration = timing.totalSpan.inMilliseconds;

      // Umbral: > 32ms es visible. > 100ms es grave.
      if (duration > 100) {
        _reportJank(duration, timing);
      }
    }
  }

  void _reportJank(int duration, FrameTiming timing) {
    // ✅ AHORA EL REPORTE INCLUYE LA PANTALLA

    FirebaseCrashlytics.instance.log(
        "JANK | Screen: $_currentScreen | Total: ${duration}ms | Build: ${timing.buildDuration.inMilliseconds}ms | Raster: ${timing.rasterDuration.inMilliseconds}ms");

    if (duration > 200) {
      // Enviamos como error no fatal para ver la estadística agrupada por pantalla
      FirebaseCrashlytics.instance.recordError(
        Exception("Jank Crítico ($duration ms)"),
        StackTrace.current,
        reason: "Pantalla: $_currentScreen",
        fatal: false,
      );
    }
  }
}

// -----------------------------------------------------------------------------
// ✅ CLASE NUEVA: El Espía de Navegación
// -----------------------------------------------------------------------------
class JankRouteObserver extends NavigatorObserver {
  void _updateScreenName(Route<dynamic>? route) {
    if (route is PageRoute && route.settings.name != null) {
      final screenName = route.settings.name!;
      JankMonitor().setContext(screenName);
      debugPrint("👀 JankMonitor: Usuario navegó a -> $screenName");
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
    // Al volver atrás, tomamos el nombre de la ruta previa (la que ahora es visible)
    _updateScreenName(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _updateScreenName(newRoute);
  }
}
