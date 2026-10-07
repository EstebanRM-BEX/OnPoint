import 'dart:collection';
import 'dart:math' as math;

/// Cómo se mide cada muestra de latencia.
enum NetworkProbeMode {
  /// Apertura de un socket TCP al host del servidor (latencia de red pura).
  tcpConnect,

  /// GET ligero al servidor Odoo con un cliente HTTP keep-alive (tiempo de
  /// respuesta del servidor). Cualquier código no 2xx cuenta como pérdida.
  httpProbe,
}

/// Configuración del medidor de calidad de red. Todo lo ajustable vive aquí.
///
/// Clasificación (indicador a indicador, se usa el peor):
/// - Óptimo: valor < `optimal*`.
/// - Problemático: valor > `problem*`.
/// - Aceptable: lo que queda en medio (los bordes exactos son Aceptable).
class NetworkQualityConfig {
  /// Muestras de la ventana corta (latencia, p90 y jitter).
  final int windowSize;

  /// Muestras de la ventana larga, independiente, solo para pérdida.
  final int lossWindowSize;

  /// Muestras exitosas mínimas en la ventana corta antes de clasificar.
  final int minSuccessSamples;

  /// Percentil (0–100) de las muestras exitosas usado para clasificar la
  /// latencia. 90 = p90.
  final double latencyPercentile;

  final double optimalLatencyMs;
  final double optimalJitterMs;
  final double optimalLossPercent;

  final double problemLatencyMs;
  final double problemJitterMs;
  final double problemLossPercent;

  final NetworkProbeMode probeMode;

  /// Ruta del GET en modo [NetworkProbeMode.httpProbe].
  final String httpProbePath;

  /// Odoo expone `version_info` como ruta JSON-RPC (igual que
  /// `/web/session/authenticate`): un GET suele responder no 2xx, así que por
  /// defecto se hace POST con cuerpo JSON-RPC vacío. false = GET simple.
  final bool httpProbeJsonRpcPost;

  /// Tiempo máximo de cada muestra; al vencer cuenta como pérdida.
  final Duration probeTimeout;

  /// Intervalo entre muestras.
  final Duration sampleInterval;

  /// Separación mínima entre descargas de 1 MB (Mbps) disparadas al expandir.
  final Duration speedTestMinInterval;

  const NetworkQualityConfig({
    this.windowSize = 20,
    this.lossWindowSize = 120,
    this.minSuccessSamples = 5,
    this.latencyPercentile = 90,
    this.optimalLatencyMs = 100,
    this.optimalJitterMs = 20,
    this.optimalLossPercent = 1,
    this.problemLatencyMs = 250,
    this.problemJitterMs = 50,
    this.problemLossPercent = 3,
    this.probeMode = NetworkProbeMode.httpProbe,
    this.httpProbePath = '/web/webclient/version_info',
    this.httpProbeJsonRpcPost = true,
    this.probeTimeout = const Duration(milliseconds: 1500),
    this.sampleInterval = const Duration(seconds: 2),
    this.speedTestMinInterval = const Duration(seconds: 60),
  });
}

enum NetworkQualityLevel { measuring, optimal, acceptable, problematic }

/// Resultado de las dos ventanas. Latencias/jitter son null cuando no hay
/// suficientes muestras exitosas (el jitter pide al menos 2).
class NetworkQualityStats {
  /// Ventana corta.
  final int samples;
  final int successes;
  final double? avgMs;
  final int? minMs;
  final int? maxMs;
  final double? percentileMs;
  final double? jitterMs;
  final double? stdDevMs;

  /// Ventana larga (pérdida).
  final int lossTotal;
  final int lossLost;
  final double lossPercent;

  final NetworkQualityLevel level;

  /// Qué indicador determina el estado, en lenguaje para el usuario.
  /// null mientras se está midiendo.
  final String? causeMessage;

  const NetworkQualityStats({
    required this.samples,
    required this.successes,
    required this.avgMs,
    required this.minMs,
    required this.maxMs,
    required this.percentileMs,
    required this.jitterMs,
    required this.stdDevMs,
    required this.lossTotal,
    required this.lossLost,
    required this.lossPercent,
    required this.level,
    required this.causeMessage,
  });

  static const empty = NetworkQualityStats(
    samples: 0,
    successes: 0,
    avgMs: null,
    minMs: null,
    maxMs: null,
    percentileMs: null,
    jitterMs: null,
    stdDevMs: null,
    lossTotal: 0,
    lossLost: 0,
    lossPercent: 0,
    level: NetworkQualityLevel.measuring,
    causeMessage: null,
  );
}

/// Dos ventanas deslizantes: una corta (últimas N muestras de RTT, con las
/// pérdidas marcadas) para latencia/jitter, y otra larga solo para pérdida.
class NetworkQualityWindow {
  NetworkQualityWindow([this.config = const NetworkQualityConfig()]);

  final NetworkQualityConfig config;

  // Ventana corta: null = muestra perdida.
  final Queue<int?> _samples = Queue<int?>();

  // Ventana larga: true = muestra perdida.
  final Queue<bool> _lossSamples = Queue<bool>();

  void addRtt(int ms) => _push(ms);

  void addLoss() => _push(null);

  /// Vacía solo la ventana corta (reconexión, vuelta de segundo plano). El
  /// historial de pérdida se conserva.
  void clearShort() => _samples.clear();

  void clearAll() {
    _samples.clear();
    _lossSamples.clear();
  }

  void _push(int? value) {
    _samples.addLast(value);
    while (_samples.length > config.windowSize) {
      _samples.removeFirst();
    }
    _lossSamples.addLast(value == null);
    while (_lossSamples.length > config.lossWindowSize) {
      _lossSamples.removeFirst();
    }
  }

  /// Percentil por rango más cercano sobre [sortedAsc] (no vacía).
  static double percentile(List<int> sortedAsc, double p) {
    final rank = (p / 100 * sortedAsc.length).ceil();
    final index = (rank - 1).clamp(0, sortedAsc.length - 1);
    return sortedAsc[index].toDouble();
  }

  NetworkQualityStats get stats {
    if (_samples.isEmpty && _lossSamples.isEmpty) {
      return NetworkQualityStats.empty;
    }

    final lossTotal = _lossSamples.length;
    final lossLost = _lossSamples.where((lost) => lost).length;
    final lossPercent = lossTotal == 0 ? 0.0 : lossLost * 100 / lossTotal;

    // Las pérdidas no entran en latencia ni jitter: solo se comparan las
    // muestras exitosas consecutivas.
    final ok = _samples.whereType<int>().toList();
    double? avg, jitter, stdDev, pct;
    int? minMs, maxMs;
    if (ok.isNotEmpty) {
      avg = ok.reduce((a, b) => a + b) / ok.length;
      minMs = ok.reduce(math.min);
      maxMs = ok.reduce(math.max);
      final mean = avg;
      stdDev = math.sqrt(
        ok.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) /
            ok.length,
      );
      pct = percentile([...ok]..sort(), config.latencyPercentile);
    }
    if (ok.length >= 2) {
      var sum = 0;
      for (var i = 1; i < ok.length; i++) {
        sum += (ok[i] - ok[i - 1]).abs();
      }
      jitter = sum / (ok.length - 1);
    }

    final (level, cause) = _classify(
      shortTotal: _samples.length,
      successes: ok.length,
      latency: pct,
      jitter: jitter,
      loss: lossPercent,
    );

    return NetworkQualityStats(
      samples: _samples.length,
      successes: ok.length,
      avgMs: avg,
      minMs: minMs,
      maxMs: maxMs,
      percentileMs: pct,
      jitterMs: jitter,
      stdDevMs: stdDev,
      lossTotal: lossTotal,
      lossLost: lossLost,
      lossPercent: lossPercent,
      level: level,
      causeMessage: cause,
    );
  }

  _Grade _grade(double value, double optimal, double problem) => value > problem
      ? _Grade.problem
      : value < optimal
      ? _Grade.optimal
      : _Grade.acceptable;

  (NetworkQualityLevel, String?) _classify({
    required int shortTotal,
    required int successes,
    required double? latency,
    required double? jitter,
    required double loss,
  }) {
    // No se clasifica hasta tener muestras suficientes. Si la ventana corta
    // ya se llenó de intentos (servidor sin responder) tampoco se queda en
    // "Midiendo…" para siempre.
    final ready =
        successes >= config.minSuccessSamples ||
        shortTotal >= config.windowSize;
    if (!ready) return (NetworkQualityLevel.measuring, null);

    if (successes == 0) {
      return (
        NetworkQualityLevel.problematic,
        'El servidor no responde: revisar conexión o servidor',
      );
    }

    final c = config;
    final grades = {
      _Indicator.latency: _grade(
        latency!,
        c.optimalLatencyMs,
        c.problemLatencyMs,
      ),
      _Indicator.jitter: jitter == null
          ? _Grade.optimal
          : _grade(jitter, c.optimalJitterMs, c.problemJitterMs),
      _Indicator.loss: _grade(loss, c.optimalLossPercent, c.problemLossPercent),
    };
    // Gravedad relativa al umbral de problema, para desempatar.
    final scores = {
      _Indicator.latency: latency / c.problemLatencyMs,
      _Indicator.jitter: (jitter ?? 0) / c.problemJitterMs,
      _Indicator.loss: loss / c.problemLossPercent,
    };

    final worst = grades.values.reduce((a, b) => a.index >= b.index ? a : b);
    if (worst == _Grade.optimal) {
      return (NetworkQualityLevel.optimal, 'Conexión estable');
    }

    // Entre los indicadores que fijan el estado, el más grave.
    final culprit = grades.entries
        .where((e) => e.value == worst)
        .map((e) => e.key)
        .reduce((a, b) => scores[a]! >= scores[b]! ? a : b);

    final problematic = worst == _Grade.problem;
    final message = switch (culprit) {
      _Indicator.loss =>
        problematic
            ? 'Pérdidas frecuentes: revisar cobertura Wi‑Fi'
            : 'Algunas pérdidas: vigilar la cobertura Wi‑Fi',
      _Indicator.jitter =>
        problematic
            ? (grades[_Indicator.latency] == _Grade.optimal
                  ? 'Latencia buena, pero la variación es alta: posibles '
                        'congelamientos al escanear'
                  : 'Variación y latencia altas: conexión inestable')
            : 'Variación moderada en la respuesta',
      _Indicator.latency =>
        problematic
            ? 'Latencia alta: red congestionada o servidor lento'
            : 'Latencia moderada',
    };
    return (
      problematic
          ? NetworkQualityLevel.problematic
          : NetworkQualityLevel.acceptable,
      message,
    );
  }
}

enum _Grade { optimal, acceptable, problem }

enum _Indicator { latency, jitter, loss }
