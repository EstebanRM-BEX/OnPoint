import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const _kLastTs = 'diag_last_ts';
  static const _kLastExitTs = 'diag_last_exit_reported_ts';

  /// Motivos de salida normales: no se reportan.
  static const _benignReasons = {
    'EXIT_SELF',
    'USER_REQUESTED',
    'USER_STOPPED',
    'PACKAGE_UPDATED',
    'PACKAGE_STATE_CHANGE',
    'FREEZER',
  };

  static Timer? _heartbeat;
  static AppLifecycleListener? _lifecycle;
  static SharedPreferences? _prefs;
  static bool _started = false;

  static Future<void> start() async {
    if (kDebugMode || _started || !Platform.isAndroid) return;
    _started = true;
    try {
      _prefs = await SharedPreferences.getInstance();
      await _reportPreviousSession();
      await _reportAndroidExitReasons();
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
    await prefs.setString(_kLastState, state);
    await prefs.setString(_kLastScreen, screen);
    await prefs.setInt(_kLastRssMb, rss);
    await prefs.setInt(_kLastTs, DateTime.now().millisecondsSinceEpoch);
  }

  /// Señal 2: la sesión anterior terminó con la app en primer plano.
  static Future<void> _reportPreviousSession() async {
    final prefs = _prefs!;
    final lastState = prefs.getString(_kLastState);
    if (lastState == null) return; // primera ejecución
    if (lastState != 'resumed' && lastState != 'inactive') return;

    final screen = prefs.getString(_kLastScreen) ?? '?';
    final rss = prefs.getInt(_kLastRssMb) ?? -1;
    final lastTs = prefs.getInt(_kLastTs);
    final when = lastTs == null
        ? '?'
        : DateTime.fromMillisecondsSinceEpoch(lastTs).toIso8601String();

    await FirebaseCrashlytics.instance.recordError(
      Exception(
        'Cierre en primer plano: la sesión anterior terminó en "$lastState"',
      ),
      StackTrace.current,
      reason:
          'screen=$screen rss_mb=$rss ultimo_latido=$when',
      information: ['screen: $screen', 'rss_mb: $rss', 'ultimo_latido: $when'],
      fatal: false,
    );
  }

  /// Señal 1: motivo de salida que reporta Android 11+ (ApplicationExitInfo).
  static Future<void> _reportAndroidExitReasons() async {
    final prefs = _prefs!;
    final raw = await _channel.invokeMethod<List<dynamic>>('getExitInfo');
    if (raw == null || raw.isEmpty) return;

    final lastReported = prefs.getInt(_kLastExitTs) ?? 0;
    var newest = lastReported;

    for (final item in raw) {
      final info = Map<String, dynamic>.from(item as Map);
      final ts = (info['timestamp'] as num?)?.toInt() ?? 0;
      if (ts <= lastReported) continue;
      if (ts > newest) newest = ts;

      final reason = '${info['reason']}';
      if (_benignReasons.contains(reason)) continue;
      // `OTHER` + "empty for too long": Android liberó un proceso en caché que
      // llevaba mucho tiempo en segundo plano. Es la limpieza normal del
      // sistema, no un cierre anómalo.
      final description = '${info['description']}';
      if (reason == 'OTHER' && description.contains('empty for')) continue;

      final when = DateTime.fromMillisecondsSinceEpoch(ts).toIso8601String();
      await FirebaseCrashlytics.instance.recordError(
        Exception('Android process exit: $reason'),
        StackTrace.current,
        reason: '${info['description']}',
        information: [
          'reason: $reason',
          'description: ${info['description']}',
          'importance: ${info['importance']} (100 = primer plano)',
          'rss_kb: ${info['rss']}',
          'pss_kb: ${info['pss']}',
          'cuando: $when',
        ],
        fatal: false,
      );
    }

    if (newest > lastReported) await prefs.setInt(_kLastExitTs, newest);
  }

  static void dispose() {
    _stopHeartbeat();
    _lifecycle?.dispose();
    _lifecycle = null;
    _started = false;
  }
}
