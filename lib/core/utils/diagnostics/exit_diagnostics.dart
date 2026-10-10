import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wms_app/core/utils/diagnostics/exit_classifier.dart';
import 'package:wms_app/core/utils/diagnostics/route_stack_tracker.dart';
import 'package:wms_app/core/utils/performance/jank_monitor.dart';

/// Diagnóstico de cierres que Crashlytics no ve (OOM, kill del sistema, ANR).
///
/// Crashlytics solo captura errores de Dart y crashes nativos con señal. Si
/// Android mata el proceso por memoria o el sistema lo cierra, no queda nada.
/// Este servicio aporta dos señales, ambas como no fatales para no mezclarlas
/// con los fallos reales:
///
/// 1. **ApplicationExitInfo (Android 11+)**: al arrancar pregunta al SO por
///    qué terminó el proceso anterior (LOW_MEMORY, ANR, CRASH_NATIVE,
///    SIGNALED…) y lo reporta una sola vez.
/// 2. **Cierre en primer plano (todas las versiones)**: se persiste el estado
///    del ciclo de vida. Si la sesión anterior terminó en `resumed`/`inactive`
///    el proceso murió con la app a la vista, sin pasar por segundo plano.
///    Si Android registró el motivo de esa muerte, se une a esta señal.
///
/// Cada motivo va a su propio issue (`ExitDiagnostics.cierre_CRASH`,
/// `cierre_equipo_apagado`, `salida_LOW_MEMORY`…), ver [clasificarCierrePrevio]
/// y [pilaDeGrupo]. Las salidas intencionales (`exit(0)`) se marcan con
/// [markIntentionalExit] y no se reportan.
///
/// Además, cada minuto actualiza las custom keys `rss_mb` y `screen` para que
/// cualquier crash llegue con la memoria y la pantalla del momento.
///
/// No corre en debug: cada stop desde el IDE parecería un cierre anómalo.
class ExitDiagnostics {
  ExitDiagnostics._();

  static const _channel = MethodChannel('device_info/custom');

  static const _kLastState = 'diag_last_state';
  static const _kLastScreen = 'diag_last_screen';
  static const _kLastRssMb = 'diag_last_rss_mb';
  static const _kLastUi = 'diag_last_ui';
  static const _kLastTs = 'diag_last_ts';
  static const _kLastExitTs = 'diag_last_exit_reported_ts';

  static Timer? _heartbeat;
  static AppLifecycleListener? _lifecycle;
  static SharedPreferences? _prefs;
  static bool _started = false;

  static Future<void> start() async {
    if (kDebugMode || _started || !Platform.isAndroid) return;
    _started = true;
    try {
      _prefs = await SharedPreferences.getInstance();
      final salidas = await _leerSalidasAndroid();
      // Solo si la sesión murió a la vista: esa salida se reporta junto al
      // cierre (señal 2). Si murió en segundo plano va por la señal 1.
      final previa = terminoEnPrimerPlano(_prefs!.getString(_kLastState))
          ? salidaDeSesionPrevia(salidas, _prefs!.getInt(_kLastTs))
          : null;
      await _reportPreviousSession(
        previa,
        soReportaSalidas: await _soReportaSalidas(),
      );
      await _reportAndroidExitReasons(salidas, excluir: previa);
    } catch (e, s) {
      debugPrint('ExitDiagnostics: error al revisar la sesión previa: $e\n$s');
    }

    await _persist('resumed');
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        _persist(state.name);
        // En segundo plano no hay nada que medir: se detiene el latido y se
        // retoma al volver (menos despertares del proceso, sin trabajo que
        // compita con el sistema mientras la app no está a la vista).
        if (state == AppLifecycleState.resumed) {
          _startHeartbeat();
        } else {
          _stopHeartbeat();
        }
      },
    );
    _startHeartbeat();
  }

  static void _startHeartbeat() {
    if (_heartbeat != null) return;
    _heartbeat = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _persist(
        WidgetsBinding.instance.lifecycleState?.name ?? 'resumed',
      ),
    );
  }

  static void _stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  static double get _rssMb => ProcessInfo.currentRss / (1024 * 1024);

  static Future<void> _persist(String state) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final screen = JankMonitor().currentScreen;
    final rss = _rssMb.round();
    FirebaseCrashlytics.instance
      ..setCustomKey('rss_mb', rss)
      ..setCustomKey('screen', screen);
    final ui = RouteStackTracker.instance.snapshot();
    FirebaseCrashlytics.instance
      ..setCustomKey('nav_pages', ui.pages)
      ..setCustomKey('nav_overlays', ui.overlays)
      ..setCustomKey('widget_elements', ui.elements)
      ..setCustomKey('nav_stack', ui.stack);
    await prefs.setString(_kLastUi, ui.toString());
    await prefs.setString(_kLastState, state);
    await prefs.setString(_kLastScreen, screen);
    await prefs.setInt(_kLastRssMb, rss);
    await prefs.setInt(_kLastTs, DateTime.now().millisecondsSinceEpoch);
  }

  /// Salidas de Android 11+ aún no reportadas (más nuevas que la última
  /// reportada). Vacía en Android < 11.
  static Future<List<SalidaAndroid>> _leerSalidasAndroid() async {
    final List<dynamic>? raw;
    try {
      raw = await _channel.invokeMethod<List<dynamic>>('getExitInfo');
    } catch (e) {
      // Sin motivos del SO igual se reporta el cierre en primer plano.
      debugPrint('ExitDiagnostics: getExitInfo falló: $e');
      return const [];
    }
    if (raw == null || raw.isEmpty) return const [];
    final lastReported = _prefs!.getInt(_kLastExitTs) ?? 0;
    return raw
        .map((e) => SalidaAndroid.fromMap(Map<String, dynamic>.from(e as Map)))
        .where((s) => s.timestamp > lastReported)
        .toList();
  }

  static Future<bool> _soReportaSalidas() async {
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      return info.version.sdkInt >= 30; // ApplicationExitInfo: Android 11
    } catch (_) {
      return false;
    }
  }

  /// Señal 2: la sesión anterior terminó con la app en primer plano. Si
  /// Android registró el motivo, va en el issue de ese motivo
  /// ([clasificarCierrePrevio]).
  static Future<void> _reportPreviousSession(
    SalidaAndroid? salida, {
    required bool soReportaSalidas,
  }) async {
    final prefs = _prefs!;
    final lastState = prefs.getString(_kLastState);
    final cierre = clasificarCierrePrevio(
      ultimoEstado: lastState,
      salida: salida,
      soReportaSalidas: soReportaSalidas,
    );
    if (cierre == null) return;

    final screen = prefs.getString(_kLastScreen) ?? '?';
    final rss = prefs.getInt(_kLastRssMb) ?? -1;
    final ui = prefs.getString(_kLastUi) ?? '?';
    final lastTs = prefs.getInt(_kLastTs);
    final when = lastTs == null
        ? '?'
        : DateTime.fromMillisecondsSinceEpoch(lastTs).toIso8601String();
    final gapMin = lastTs == null
        ? '?'
        : DateTime.now()
              .difference(DateTime.fromMillisecondsSinceEpoch(lastTs))
              .inMinutes
              .toString();

    await FirebaseCrashlytics.instance.recordError(
      Exception(cierre.titulo),
      pilaDeGrupo(cierre.grupo),
      reason: 'screen=$screen rss_mb=$rss ui=[$ui] ultimo_latido=$when',
      information: [
        'screen: $screen',
        'rss_mb: $rss',
        'ui: $ui',
        'ultimo_latido: $when',
        'minutos_hasta_relanzar: $gapMin',
        ...?salida?.informacion,
      ],
      fatal: false,
    );
  }

  /// Señal 1: salidas anómalas que reporta Android 11+ (ApplicationExitInfo)
  /// y que no son la de la sesión previa (esa ya va en la señal 2). Un issue
  /// por motivo.
  static Future<void> _reportAndroidExitReasons(
    List<SalidaAndroid> salidas, {
    SalidaAndroid? excluir,
  }) async {
    if (salidas.isEmpty) return;
    final prefs = _prefs!;
    var newest = prefs.getInt(_kLastExitTs) ?? 0;

    for (final salida in salidas) {
      if (salida.timestamp > newest) newest = salida.timestamp;
      if (identical(salida, excluir) || salida.esBenigna) continue;

      await FirebaseCrashlytics.instance.recordError(
        Exception('Android process exit: ${salida.reason}'),
        pilaDeGrupo(grupoDeSalida(salida)),
        reason: salida.description,
        information: salida.informacion,
        fatal: false,
      );
    }

    await prefs.setInt(_kLastExitTs, newest);
  }

  /// Marca una salida intencional (`exit(0)`) para que el próximo arranque
  /// no la reporte como cierre anómalo. Funciona aunque [start] no haya
  /// corrido (p. ej. error antes de terminar la inicialización).
  static Future<void> markIntentionalExit() async {
    _stopHeartbeat();
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString(_kLastState, estadoSalidaIntencional);
    } catch (_) {
      // Sin preferencias el peor caso es un falso "cierre en primer plano".
    }
  }

  static void dispose() {
    _stopHeartbeat();
    _lifecycle?.dispose();
    _lifecycle = null;
    _started = false;
  }
}
