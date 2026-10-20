import 'package:flutter_test/flutter_test.dart';
import 'package:wms_app/core/utils/performance/frame_stats.dart';

void main() {
  late FrameStats stats;

  setUp(() => stats = FrameStats());

  void frame({
    int totalMs = 10,
    int buildMs = 5,
    int rasterMs = 5,
    bool sync = false,
  }) =>
      stats.registrar(
        totalMs: totalMs,
        buildUs: buildMs * 1000,
        rasterUs: rasterMs * 1000,
        sincronizando: sync,
      );

  test('frame fluido: solo suma al total', () {
    frame();
    expect(stats.metricas, {
      'frames_total': 1,
      'frames_slow': 0,
      'frames_frozen': 0,
      'frame_max_ms': 10,
      'frames_build_heavy': 0,
      'frames_sync': 0,
      'frames_slow_sync': 0,
    });
    expect(stats.syncActivo, 'no');
  });

  test('lento por build cuenta como build pesado; por raster no', () {
    frame(totalMs: 30, buildMs: 25);
    frame(totalMs: 30, rasterMs: 25);
    expect(stats.lentos, 2);
    expect(stats.buildPesado, 1);
  });

  test('congelado: más de 700 ms', () {
    frame(totalMs: 700, buildMs: 600);
    frame(totalMs: 701, buildMs: 600);
    expect(stats.congelados, 1);
    expect(stats.maxMs, 701);
  });

  test('separa los frames lentos con sincronización activa', () {
    frame(sync: true);
    frame(totalMs: 40, buildMs: 30, sync: true);
    frame(totalMs: 40, buildMs: 30);
    expect(stats.conSync, 2);
    expect(stats.lentosConSync, 1);
    expect(stats.lentos, 2);
    expect(stats.syncActivo, 'si');
  });

  test('justo en el presupuesto de 16,667 ms no es lento', () {
    stats.registrar(
      totalMs: 16,
      buildUs: FrameStats.presupuestoUs,
      rasterUs: FrameStats.presupuestoUs,
      sincronizando: false,
    );
    expect(stats.lentos, 0);
  });

  test('reset vuelve todo a cero', () {
    frame(totalMs: 900, buildMs: 800, sync: true);
    stats.reset();
    expect(stats.metricas.values, everyElement(0));
    expect(stats.syncActivo, 'no');
  });
}
