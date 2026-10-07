import 'dart:async';
import 'dart:developer' as developer;

import 'package:wms_app/core/network/network_quality_metrics.dart';

/// Una medición de RTT en ms. Lanza si falla o vence (cuenta como pérdida).
typedef RttProbe = Future<int> Function();

/// Lanza muestras periódicas hacia una [NetworkQualityWindow] sin solapar
/// sondeos: si al cumplirse el intervalo hay uno pendiente, ese ciclo se salta.
class NetworkQualitySampler {
  NetworkQualitySampler({
    required this.window,
    required this.probe,
    this.canSample,
    this.onSample,
  });

  final NetworkQualityWindow window;
  final RttProbe probe;

  /// Si devuelve false no se muestrea (por ejemplo sin conexión).
  final bool Function()? canSample;

  /// Se llama tras registrar cada muestra.
  final void Function(NetworkQualityStats stats)? onSample;

  Timer? _timer;
  bool _inFlight = false;
  int _generation = 0;

  /// Ciclos saltados por haber un sondeo en curso.
  int skippedTicks = 0;

  /// Motivo de la última muestra perdida (diagnóstico); null si la última salió bien.
  String? lastError;

  bool get isRunning => _timer != null;

  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(window.config.sampleInterval, (_) => sampleOnce());
    sampleOnce();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    invalidate();
  }

  /// Descarta el resultado del sondeo en curso (cambió el contexto: offline,
  /// segundo plano...) y libera el cupo para el siguiente.
  void invalidate() {
    _generation++;
    _inFlight = false;
  }

  Future<void> sampleOnce() async {
    if (_inFlight) {
      skippedTicks++;
      return;
    }
    if (!(canSample?.call() ?? true)) return;

    _inFlight = true;
    final generation = _generation;
    int? rtt;
    try {
      // Red de seguridad por si un probe no respeta su propio timeout.
      rtt = await probe().timeout(
        window.config.probeTimeout + const Duration(milliseconds: 500),
      );
    } catch (e) {
      lastError = e.toString();
      developer.log('Muestra perdida: $e', name: 'NetworkQuality');
      rtt = null;
    }
    // El contexto cambió mientras se medía: el resultado ya no vale.
    if (generation != _generation) return;
    _inFlight = false;

    if (rtt != null) lastError = null;
    rtt == null ? window.addLoss() : window.addRtt(rtt);
    onSample?.call(window.stats);
  }
}
