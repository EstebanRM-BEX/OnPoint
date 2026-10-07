import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wms_app/core/network/network_quality_metrics.dart';
import 'package:wms_app/core/network/network_quality_sampler.dart';

void main() {
  NetworkQualityWindow window({
    int n = 20,
    int lossN = 120,
    int minSuccess = 5,
    double percentile = 90,
  }) => NetworkQualityWindow(
    NetworkQualityConfig(
      windowSize: n,
      lossWindowSize: lossN,
      minSuccessSamples: minSuccess,
      latencyPercentile: percentile,
    ),
  );

  /// Ventana lista para clasificar: [rtts] repetidos para superar el mínimo.
  NetworkQualityWindow filled(List<int> rtts) {
    final w = window(minSuccess: 1);
    rtts.forEach(w.addRtt);
    return w;
  }

  group('jitter', () {
    test('media de |RTT[i]-RTT[i-1]| sobre exitosas, saltando perdidas', () {
      final w = window(minSuccess: 1)
        ..addRtt(50)
        ..addLoss()
        ..addRtt(70)
        ..addLoss()
        ..addRtt(60);
      expect(w.stats.jitterMs, 15); // (20 + 10) / 2
    });

    test('null con menos de 2 exitosas', () {
      expect(window().stats.jitterMs, isNull);
      final w = window(minSuccess: 1)
        ..addRtt(50)
        ..addLoss()
        ..addLoss();
      expect(w.stats.jitterMs, isNull);
    });
  });

  group('percentil', () {
    test('p90 por rango más cercano', () {
      final w = filled(List.generate(10, (i) => (i + 1) * 10)); // 10..100
      expect(w.stats.percentileMs, 90);
      expect(w.stats.avgMs, 55);
    });

    test('es configurable', () {
      final w = window(minSuccess: 1, percentile: 50);
      for (var i = 1; i <= 10; i++) {
        w.addRtt(i * 10);
      }
      expect(w.stats.percentileMs, 50);
    });

    test('un pico aislado no mueve el p90 pero sí el promedio', () {
      final w = filled([...List.filled(19, 40), 400]);
      expect(w.stats.percentileMs, 40);
      expect(w.stats.avgMs, greaterThan(40));
    });
  });

  group('pérdida (ventana larga)', () {
    test('usa su propia ventana de 120 muestras', () {
      final w = window(n: 20, lossN: 120, minSuccess: 1);
      for (var i = 0; i < 119; i++) {
        w.addRtt(50);
      }
      w.addLoss();
      final s = w.stats;
      expect(s.lossTotal, 120);
      expect(s.lossLost, 1);
      expect(s.lossPercent, closeTo(0.833, 0.001));
      expect(s.samples, 20); // la ventana corta sigue en 20
    });

    test('una sola pérdida ya no pone todo en rojo', () {
      final w = window(minSuccess: 1);
      for (var i = 0; i < 119; i++) {
        w.addRtt(50);
      }
      w.addLoss();
      expect(w.stats.level, NetworkQualityLevel.optimal);
    });

    test('clearShort conserva el historial de pérdida', () {
      final w = window(minSuccess: 1)
        ..addRtt(50)
        ..addLoss()
        ..clearShort();
      expect(w.stats.samples, 0);
      expect(w.stats.lossTotal, 2);
    });
  });

  group('clasificación en los bordes', () {
    NetworkQualityLevel byLatency(int ms) =>
        filled(List.filled(6, ms)).stats.level;

    test('latencia 99 / 100 / 250 / 251 ms', () {
      expect(byLatency(99), NetworkQualityLevel.optimal);
      expect(byLatency(100), NetworkQualityLevel.acceptable);
      expect(byLatency(250), NetworkQualityLevel.acceptable);
      expect(byLatency(251), NetworkQualityLevel.problematic);
    });

    NetworkQualityLevel byJitter(int delta) {
      // Alterna 10 y 10+delta -> jitter = delta.
      final w = window(minSuccess: 1);
      for (var i = 0; i < 6; i++) {
        w.addRtt(i.isEven ? 10 : 10 + delta);
      }
      return w.stats.level;
    }

    test('jitter 19 / 20 / 50 / 51 ms', () {
      expect(byJitter(19), NetworkQualityLevel.optimal);
      expect(byJitter(20), NetworkQualityLevel.acceptable);
      expect(byJitter(50), NetworkQualityLevel.acceptable);
      expect(byJitter(51), NetworkQualityLevel.problematic);
    });

    NetworkQualityLevel byLoss(int lost) {
      final w = window(n: 20, lossN: 100, minSuccess: 1);
      for (var i = 0; i < 100 - lost; i++) {
        w.addRtt(50);
      }
      for (var i = 0; i < lost; i++) {
        w.addLoss();
      }
      return w.stats.level;
    }

    test('pérdida (de 100): 0 / 1 / 3 / 4 %', () {
      expect(byLoss(0), NetworkQualityLevel.optimal);
      expect(byLoss(1), NetworkQualityLevel.acceptable); // 1 % no es < 1 %
      expect(byLoss(3), NetworkQualityLevel.acceptable);
      expect(byLoss(4), NetworkQualityLevel.problematic);
    });

    test('usa el peor indicador y lo nombra como causa', () {
      final w = window(minSuccess: 1);
      for (var i = 0; i < 6; i++) {
        w.addRtt(i.isEven ? 10 : 70); // latencia baja, jitter 60
      }
      final s = w.stats;
      expect(s.level, NetworkQualityLevel.problematic);
      expect(s.causeMessage, contains('variación es alta'));
    });

    test('pérdidas frecuentes como causa', () {
      final w = window(n: 20, lossN: 20, minSuccess: 1);
      for (var i = 0; i < 15; i++) {
        w.addRtt(50);
      }
      for (var i = 0; i < 5; i++) {
        w.addLoss();
      }
      expect(w.stats.causeMessage, contains('Pérdidas frecuentes'));
    });

    test('ninguna exitosa con ventana llena = problemático', () {
      final w = window();
      for (var i = 0; i < 20; i++) {
        w.addLoss();
      }
      expect(w.stats.level, NetworkQualityLevel.problematic);
      expect(w.stats.causeMessage, contains('no responde'));
    });
  });

  group('mínimo de muestras', () {
    test('Midiendo… con menos de 5 exitosas', () {
      final w = window();
      for (var i = 0; i < 4; i++) {
        w.addRtt(50);
      }
      final s = w.stats;
      expect(s.level, NetworkQualityLevel.measuring);
      expect(s.causeMessage, isNull);
    });

    test('clasifica con la 5.ª exitosa', () {
      final w = window();
      for (var i = 0; i < 5; i++) {
        w.addRtt(50);
      }
      expect(w.stats.level, NetworkQualityLevel.optimal);
    });

    test('al vaciar la ventana corta vuelve a Midiendo…', () {
      final w = window();
      for (var i = 0; i < 5; i++) {
        w.addRtt(50);
      }
      w.clearShort();
      expect(w.stats.level, NetworkQualityLevel.measuring);
    });
  });

  group('sondeos no solapados', () {
    NetworkQualitySampler sampler(
      NetworkQualityWindow w,
      RttProbe probe, {
      bool Function()? canSample,
    }) => NetworkQualitySampler(window: w, probe: probe, canSample: canSample);

    test('salta el ciclo si hay un sondeo pendiente', () async {
      var calls = 0;
      final pending = Completer<int>();
      final w = window();
      final s = sampler(w, () {
        calls++;
        return pending.future;
      });

      final first = s.sampleOnce();
      await s.sampleOnce();
      await s.sampleOnce();
      expect(calls, 1);
      expect(s.skippedTicks, 2);

      pending.complete(40);
      await first;
      expect(w.stats.samples, 1);

      await s.sampleOnce(); // ya libre
      expect(calls, 2);
    });

    test('un fallo se registra como pérdida y libera el cupo', () async {
      final w = window();
      final s = sampler(w, () async => throw Exception('timeout'));
      await s.sampleOnce();
      expect(w.stats.lossLost, 1);
      await s.sampleOnce();
      expect(w.stats.lossTotal, 2);
    });

    test('no muestrea si canSample es false', () async {
      var calls = 0;
      final s = sampler(window(), () async {
        calls++;
        return 10;
      }, canSample: () => false);
      await s.sampleOnce();
      expect(calls, 0);
    });

    test('invalidate descarta el resultado del sondeo en curso', () async {
      final pending = Completer<int>();
      final w = window();
      final s = sampler(w, () => pending.future);
      final first = s.sampleOnce();
      s.invalidate();
      pending.complete(40);
      await first;
      expect(w.stats.samples, 0);
    });
  });
}
