import 'dart:async';

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Traza de Firebase Performance por sincronización incremental de un
/// catálogo: `catalogo_sync` (productos, `product_quants`) o
/// `ubicaciones_sync` (`/api/ubicaciones`).
///
/// Atributos (filtrables en la consola, Personalizado → `catalogo_sync`):
/// - `tipo`: `completa` | `incremental`.
/// - `motivo`: por qué fue completa (ver [motivoDescargaCompleta]) o
///   `incremental`.
/// - `resultado`: `ok` | `error` | `sesion_expirada` | `sin_productos`.
///
/// Métricas: `filas`, `barcodes`, `eliminados`, `ms_descarga` (red + parseo)
/// y `ms_guardado` (SQLite). La duración total la mide la propia traza.
///
/// Sirve para decidir la Fase 3 (catálogos por `scope`): cuántas descargas
/// completas son `motivo = scope_distinto`.
class CatalogoSyncTrace {
  CatalogoSyncTrace._(this._trace);

  final Trace? _trace;
  final _reloj = Stopwatch()..start();
  int _desdeMs = 0;

  /// En debug (y en tests) no se envía nada: igual que el resto de
  /// Performance, los tiempos con JIT no son representativos.
  static CatalogoSyncTrace iniciar([String nombre = 'catalogo_sync']) {
    if (kDebugMode) return CatalogoSyncTrace._(null);
    try {
      final trace = FirebasePerformance.instance.newTrace(nombre);
      unawaited(trace.start());
      return CatalogoSyncTrace._(trace);
    } catch (_) {
      return CatalogoSyncTrace._(null);
    }
  }

  void atributo(String nombre, String valor) =>
      _trace?.putAttribute(nombre, valor);

  void metrica(String nombre, int valor) => _trace?.setMetric(nombre, valor);

  /// Guarda en [nombre] los ms desde la marca anterior (o el inicio) y los
  /// devuelve (para el log de debug).
  int tramo(String nombre) {
    final ahora = _reloj.elapsedMilliseconds;
    final ms = ahora - _desdeMs;
    metrica(nombre, ms);
    _desdeMs = ahora;
    return ms;
  }

  void terminar(String resultado) {
    atributo('resultado', resultado);
    final trace = _trace;
    if (trace != null) unawaited(trace.stop());
  }
}

/// Motivo de una descarga completa, para el atributo `motivo`.
///
/// [motivoLocal]: por qué la app no pidió incremental (`empresa_distinta`,
/// `sin_marca`, `catalogo_vacio`), o null si sí lo pidió con [scopeEnviado].
String motivoDescargaCompleta({
  required String? motivoLocal,
  required String? scopeEnviado,
  required String? serverTime,
  required String? scopeRecibido,
}) {
  if (serverTime == null) return 'backend_anterior';
  if (motivoLocal != null) return motivoLocal;
  if (scopeRecibido != null && scopeRecibido != scopeEnviado) {
    return 'scope_distinto';
  }
  // Mismo scope: since viejo (> 30 días) o demasiados cambios.
  return 'servidor_full';
}
