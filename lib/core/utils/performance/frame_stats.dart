/// Acumula las métricas de fluidez de una visita a una pantalla (lo que
/// [JankMonitor] envía en cada traza `screen_*`). Sin dependencias de
/// Firebase para poder probarla.
class FrameStats {
  /// Presupuesto de un frame a 60 Hz.
  static const presupuestoUs = 16667;

  /// Un frame de más de esto se ve como la app congelada.
  static const congeladoMs = 700;

  int total = 0;
  int lentos = 0;
  int congelados = 0;
  int maxMs = 0;

  /// Frames cuyo *build* (reconstrucción de widgets) pasó el presupuesto:
  /// separa "se reconstruye demasiado" de "pinta demasiado" (raster).
  int buildPesado = 0;

  /// Frames durante una sincronización (catálogo, ubicaciones, terceros…)
  /// y cuántos de ellos fueron lentos.
  int conSync = 0;
  int lentosConSync = 0;

  void registrar({
    required int totalMs,
    required int buildUs,
    required int rasterUs,
    required bool sincronizando,
  }) {
    total++;
    if (totalMs > maxMs) maxMs = totalMs;
    final esLento = buildUs > presupuestoUs || rasterUs > presupuestoUs;
    if (esLento) lentos++;
    if (buildUs > presupuestoUs) buildPesado++;
    if (totalMs > congeladoMs) congelados++;
    if (sincronizando) {
      conSync++;
      if (esLento) lentosConSync++;
    }
  }

  void reset() {
    total = lentos = congelados = maxMs = 0;
    buildPesado = conSync = lentosConSync = 0;
  }

  /// Métricas de la traza. Los nombres `frames_*` y `frame_max_ms` se
  /// mantienen para no cortar el histórico de la consola.
  Map<String, int> get metricas => {
        'frames_total': total,
        'frames_slow': lentos,
        'frames_frozen': congelados,
        'frame_max_ms': maxMs,
        'frames_build_heavy': buildPesado,
        'frames_sync': conSync,
        'frames_slow_sync': lentosConSync,
      };

  /// Atributo `sync_activo`: hubo sincronización en algún momento de la
  /// visita. Permite filtrar la traza en la consola (con / sin sync).
  String get syncActivo => conSync > 0 ? 'si' : 'no';
}
