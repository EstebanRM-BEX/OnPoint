import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/core/network/network_quality_metrics.dart';
import 'package:wms_app/core/network/network_quality_probes.dart';
import 'package:wms_app/core/network/network_quality_sampler.dart';
import 'package:wms_app/injection_container.dart' show getIt;
import 'package:wms_app/src/presentation/providers/network_overlay/network_overlay_cubit.dart';

enum _NetQuality { measuring, optimal, acceptable, problematic, offline }

enum _SpeedState { idle, measuring, done, error }

class NetworkQualityOverlay extends StatefulWidget {
  final Widget child;

  const NetworkQualityOverlay({super.key, required this.child});

  /// Desactiva las llamadas de red (ping + speed test) en el entorno de tests.
  @visibleForTesting
  static bool disableNetworkCallsForTesting = false;

  @override
  State<NetworkQualityOverlay> createState() => _NetworkQualityOverlayState();
}

class _NetworkQualityOverlayState extends State<NetworkQualityOverlay>
    with WidgetsBindingObserver {
  static const _config = NetworkQualityConfig();
  static const _speedTestUrl =
      'https://speed.cloudflare.com/__down?bytes=1000000';
  static const _margin = 4.0;

  final _pillKey = GlobalKey();

  // Posición deseada (top-left). null = esquina superior derecha por defecto.
  Offset? _position;

  _NetQuality _quality = _NetQuality.measuring;
  final _window = NetworkQualityWindow(_config);
  late final NetworkQualitySampler _sampler;
  void Function()? _disposeProbe;
  NetworkQualityStats _stats = NetworkQualityStats.empty;
  String _connectionType = '';
  bool _isExpanded = false;

  _SpeedState _speedState = _SpeedState.idle;
  double _speedMbps = 0;

  bool _visible = false;
  bool _foreground = true;
  bool _monitoring = false;
  DateTime? _lastSpeedAt;

  StreamSubscription? _connectivitySub;
  StreamSubscription? _statusSub;
  StreamSubscription? _overlaySub;

  @override
  void initState() {
    super.initState();
    if (NetworkQualityOverlay.disableNetworkCallsForTesting) return;
    WidgetsBinding.instance.addObserver(this);
    final probe = buildRttProbe(_config);
    _disposeProbe = probe.dispose;
    _sampler = NetworkQualitySampler(
      window: _window,
      probe: probe.probe,
      canSample: () => getIt<NetworkInfo>().current != ConnectionStatus.offline,
      onSample: (_) => _publishStats(),
    );
    // El monitoreo solo corre mientras el overlay es visible y la app está en
    // primer plano: oculto o minimizado no debe gastar red ni batería.
    final overlay = context.read<NetworkOverlayCubit>();
    _overlaySub = overlay.stream.listen((visible) {
      _visible = visible;
      _syncMonitoring();
    });
    _visible = overlay.state;
    _syncMonitoring();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncMonitoring();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _overlaySub?.cancel();
    _stopMonitoring();
    _disposeProbe?.call();
    super.dispose();
  }

  void _syncMonitoring() =>
      _visible && _foreground ? _startMonitoring() : _stopMonitoring();

  /// Ajusta [desired] para que la píldora (de tamaño [child]) quede completa
  /// dentro de la pantalla, incluso expandida o tras rotar.
  Offset _clampPosition(Offset? desired, Size screen, Size child) {
    final topPad = MediaQuery.paddingOf(context).top;
    final maxX = math.max(_margin, screen.width - child.width - _margin);
    final maxY = math.max(
      topPad + _margin,
      screen.height - child.height - _margin,
    );
    final d = desired ?? Offset(maxX, topPad + 8);
    return Offset(
      d.dx.clamp(_margin, maxX),
      d.dy.clamp(topPad + _margin, maxY),
    );
  }

  void _onPanUpdate(DragUpdateDetails details, Size screen) {
    final child = _pillKey.currentContext?.size ?? Size.zero;
    final current = _clampPosition(_position, screen, child);
    setState(
      () => _position = _clampPosition(current + details.delta, screen, child),
    );
  }

  void _onTap() {
    final wasExpanded = _isExpanded;
    setState(() => _isExpanded = !_isExpanded);
    if (wasExpanded) return;
    // La descarga de 1 MB solo se lanza al expandir y no más seguido que
    // speedTestMinInterval; el botón de refrescar la repite a pedido.
    final last = _lastSpeedAt;
    if (last == null ||
        DateTime.now().difference(last) >= _config.speedTestMinInterval) {
      _measureSpeed();
    }
  }

  void _startMonitoring() {
    if (_monitoring) return;
    _monitoring = true;
    // Al arrancar o volver de segundo plano las muestras previas ya no
    // representan la red.
    _window.clearShort();
    _stats = _window.stats;
    // Valor inicial: onConnectivityChanged solo emite en cambios.
    Connectivity().checkConnectivity().then(_onConnectivity);
    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      _onConnectivity,
    );
    // El estado offline lo decide NetworkInfo (una sola fuente de verdad);
    // este overlay solo mide cuando hay conexión.
    _statusSub = getIt<NetworkInfo>().onStatusChanged.listen((status) {
      if (!mounted) return;
      _sampler.invalidate();
      _window.clearShort();
      if (status == ConnectionStatus.offline) {
        setState(() {
          _quality = _NetQuality.offline;
          _stats = NetworkQualityStats.empty;
        });
      } else {
        setState(() {
          _quality = _NetQuality.measuring;
          _stats = NetworkQualityStats.empty;
        });
        _sampler.sampleOnce();
      }
    });
    if (getIt<NetworkInfo>().current == ConnectionStatus.offline) {
      _quality = _NetQuality.offline;
    } else {
      _quality = _NetQuality.measuring;
    }
    _sampler.start();
  }

  void _stopMonitoring() {
    _monitoring = false;
    if (NetworkQualityOverlay.disableNetworkCallsForTesting) return;
    _sampler.stop();
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _statusSub?.cancel();
    _statusSub = null;
  }

  void _onConnectivity(List<ConnectivityResult> results) {
    if (!mounted) return;
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    setState(() {
      _connectionType = switch (result) {
        ConnectivityResult.wifi => 'WiFi',
        ConnectivityResult.mobile => 'Datos móviles',
        ConnectivityResult.ethernet => 'Ethernet',
        ConnectivityResult.none => 'Sin red',
        _ => 'Desconocido',
      };
    });
  }

  void _publishStats() {
    if (!mounted) return;
    final stats = _window.stats;
    setState(() {
      _stats = stats;
      _quality = switch (stats.level) {
        NetworkQualityLevel.measuring => _NetQuality.measuring,
        NetworkQualityLevel.optimal => _NetQuality.optimal,
        NetworkQualityLevel.acceptable => _NetQuality.acceptable,
        NetworkQualityLevel.problematic => _NetQuality.problematic,
      };
    });
  }

  Future<void> _measureSpeed() async {
    if (NetworkQualityOverlay.disableNetworkCallsForTesting) return;
    if (_speedState == _SpeedState.measuring) return;
    if (getIt<NetworkInfo>().current == ConnectionStatus.offline) return;
    _lastSpeedAt = DateTime.now();
    setState(() {
      _speedState = _SpeedState.measuring;
      _speedMbps = 0;
    });
    final client = http.Client();
    try {
      final response = await client
          .send(http.Request('GET', Uri.parse(_speedTestUrl)))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw HttpException('${response.statusCode}');
      }
      // El cronómetro arranca con los headers ya recibidos: así DNS, TLS y
      // latencia del primer byte no se cuentan como tiempo de descarga.
      final sw = Stopwatch()..start();
      var bytes = 0;
      await response.stream
          .forEach((chunk) => bytes += chunk.length)
          .timeout(const Duration(seconds: 15));
      sw.stop();
      final seconds = math.max(sw.elapsedMicroseconds, 1) / 1e6;
      final mbps = (bytes * 8) / (seconds * 1e6);
      if (!mounted) return;
      setState(() {
        _speedMbps = mbps;
        _speedState = _SpeedState.done;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _speedState = _SpeedState.error);
    } finally {
      client.close();
    }
  }

  Color get _qualityColor {
    switch (_quality) {
      case _NetQuality.measuring:
        return Colors.white70;
      case _NetQuality.optimal:
        return Colors.greenAccent;
      case _NetQuality.acceptable:
        return Colors.orangeAccent;
      case _NetQuality.problematic:
        return Colors.redAccent;
      case _NetQuality.offline:
        return Colors.grey;
    }
  }

  String get _qualityLabel {
    switch (_quality) {
      case _NetQuality.measuring:
        return 'Midiendo…';
      case _NetQuality.optimal:
        return 'Óptimo';
      case _NetQuality.acceptable:
        return 'Aceptable';
      case _NetQuality.problematic:
        return 'Problemático';
      case _NetQuality.offline:
        return 'Sin señal';
    }
  }

  int get _signalBars {
    switch (_quality) {
      case _NetQuality.measuring:
        return 0;
      case _NetQuality.optimal:
        return 4;
      case _NetQuality.acceptable:
        return 3;
      case _NetQuality.problematic:
        return 1;
      case _NetQuality.offline:
        return 0;
    }
  }

  static String _ms(num? v) => v == null ? '—' : '${v.round()}ms';

  String get _pingText => _ms(_stats.avgMs);

  /// Texto de la píldora colapsada: nunca queda vacía.
  String get _collapsedText {
    if (_quality == _NetQuality.offline) return 'Sin señal';
    if (_stats.avgMs != null) return _pingText;
    if (_stats.samples > 0) return 'Sin resp.';
    return 'Midiendo…';
  }

  String get _latencyLabel => _config.probeMode == NetworkProbeMode.tcpConnect
      ? 'Latencia de red'
      : 'Respuesta del servidor';

  String get _percentileLabel => 'p${_config.latencyPercentile.round()}';

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);

    return BlocBuilder<NetworkOverlayCubit, bool>(
      builder: (context, visible) => Stack(
        children: [
          widget.child,
          if (visible)
            Positioned.fill(
              child: CustomSingleChildLayout(
                delegate: _PillLayoutDelegate(
                  (child) => _clampPosition(_position, screen, child),
                  _position,
                  MediaQuery.paddingOf(context).top,
                ),
                child: GestureDetector(
                  key: _pillKey,
                  behavior: HitTestBehavior.opaque,
                  onTap: _onTap,
                  onPanUpdate: (d) => _onPanUpdate(d, screen),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _qualityColor.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: _isExpanded ? _buildExpanded() : _buildCollapsed(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCollapsed() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ícono de agarre visual
        const Icon(Icons.drag_indicator, color: Colors.white30, size: 12),
        const SizedBox(width: 2),
        _SignalBars(bars: _signalBars, color: _qualityColor, size: 14),
        const SizedBox(width: 5),
        Text(
          _collapsedText,
          style: TextStyle(
            color: _qualityColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildExpanded() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ícono de agarre
        const Padding(
          padding: EdgeInsets.only(top: 2, right: 2),
          child: Icon(Icons.drag_indicator, color: Colors.white30, size: 14),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: _SignalBars(bars: _signalBars, color: _qualityColor, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _qualityLabel,
              style: TextStyle(
                color: _qualityColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _connectionType,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
            if (_quality != _NetQuality.offline) ...[
              for (final line in [
                '$_latencyLabel: $_pingText',
                '$_percentileLabel: ${_ms(_stats.percentileMs)}  '
                    'Mín/Máx: ${_ms(_stats.minMs)} / ${_ms(_stats.maxMs)}',
                'Jitter: ${_ms(_stats.jitterMs)}',
                'Pérdida: ${_stats.lossPercent.toStringAsFixed(1)}% '
                    '(${_stats.lossLost}/${_stats.lossTotal})',
              ])
                Text(
                  line,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              if (_stats.causeMessage != null) ...[
                const SizedBox(height: 3),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 190),
                  child: Text(
                    _stats.causeMessage! +
                        (_sampler.lastError == null
                            ? ''
                            : '\n(${_sampler.lastError})'),
                    style: TextStyle(
                      color: _qualityColor,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ] else if (_quality == _NetQuality.measuring)
                Text(
                  'Muestras: ${_stats.successes}/${_config.minSuccessSamples}',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              const SizedBox(height: 4),
              _buildSpeedRow(),
            ],
          ],
        ),
        const SizedBox(width: 6),
        const Icon(Icons.close, color: Colors.white54, size: 12),
      ],
    );
  }

  Widget _buildSpeedRow() {
    switch (_speedState) {
      case _SpeedState.measuring:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.white54,
              ),
            ),
            SizedBox(width: 5),
            Text(
              'Midiendo...',
              style: TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        );

      case _SpeedState.done:
        return GestureDetector(
          onTap: _measureSpeed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.download, color: Colors.white70, size: 11),
              const SizedBox(width: 3),
              Text(
                '${_speedMbps.toStringAsFixed(1)} Mbps',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.refresh, color: Colors.white38, size: 10),
            ],
          ),
        );

      case _SpeedState.error:
        return GestureDetector(
          onTap: _measureSpeed,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber, color: Colors.orangeAccent, size: 10),
              SizedBox(width: 3),
              Text(
                'Error — reintentar',
                style: TextStyle(color: Colors.orangeAccent, fontSize: 10),
              ),
            ],
          ),
        );

      case _SpeedState.idle:
        return const SizedBox.shrink();
    }
  }
}

/// Ubica la píldora en la posición deseada ya ajustada a su tamaño real.
class _PillLayoutDelegate extends SingleChildLayoutDelegate {
  _PillLayoutDelegate(this.place, this.position, this.topPadding);

  final Offset Function(Size child) place;
  final Offset? position;
  final double topPadding;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) => place(childSize);

  @override
  bool shouldRelayout(_PillLayoutDelegate old) =>
      old.position != position || old.topPadding != topPadding;
}

class _SignalBars extends StatelessWidget {
  final int bars;
  final Color color;
  final double size;

  const _SignalBars({
    required this.bars,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final active = i < bars;
        final height = size * (0.4 + i * 0.2);
        return Padding(
          padding: const EdgeInsets.only(right: 1.5),
          child: Container(
            width: size * 0.22,
            height: height,
            decoration: BoxDecoration(
              color: active ? color : Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
