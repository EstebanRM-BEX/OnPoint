import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/injection_container.dart' show getIt;
import 'package:wms_app/src/presentation/providers/network_overlay/network_overlay_cubit.dart';

enum _NetQuality { measuring, excellent, good, poor, offline }

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
  // Fallback cuando aún no hay URL de empresa (pre-login).
  static const _fallbackPingHost = 'www.gstatic.com';
  static const _pingInterval = Duration(seconds: 5);
  static const _pingTimeout = Duration(seconds: 4);
  static const _pingTargetTtl = Duration(minutes: 1);
  static const _speedTestUrl =
      'https://speed.cloudflare.com/__down?bytes=1000000';
  static const _margin = 4.0;

  final _pillKey = GlobalKey();

  // Posición deseada (top-left). null = esquina superior derecha por defecto.
  Offset? _position;

  _NetQuality _quality = _NetQuality.measuring;
  int? _pingMs;
  String _connectionType = '';
  bool _isExpanded = false;

  _SpeedState _speedState = _SpeedState.idle;
  double _speedMbps = 0;

  bool _visible = false;
  bool _foreground = true;
  bool _pinging = false;
  (String, int)? _pingTarget;
  DateTime? _pingTargetAt;

  Timer? _pingTimer;
  StreamSubscription? _connectivitySub;
  StreamSubscription? _statusSub;
  StreamSubscription? _overlaySub;

  @override
  void initState() {
    super.initState();
    if (NetworkQualityOverlay.disableNetworkCallsForTesting) return;
    WidgetsBinding.instance.addObserver(this);
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
    if (!wasExpanded) _measureSpeed();
  }

  void _startMonitoring() {
    if (_pingTimer != null) return;
    // Valor inicial: onConnectivityChanged solo emite en cambios.
    Connectivity().checkConnectivity().then(_onConnectivity);
    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      _onConnectivity,
    );
    // El estado offline lo decide NetworkInfo (una sola fuente de verdad);
    // este overlay solo mide la latencia cuando hay conexión.
    _statusSub = getIt<NetworkInfo>().onStatusChanged.listen((status) {
      if (!mounted) return;
      if (status == ConnectionStatus.offline) {
        setState(() {
          _quality = _NetQuality.offline;
          _pingMs = null;
        });
      } else {
        setState(() => _quality = _NetQuality.measuring);
        _measurePing();
      }
    });
    _pingTimer = Timer.periodic(_pingInterval, (_) => _measurePing());
    _measurePing();
  }

  void _stopMonitoring() {
    _pingTimer?.cancel();
    _pingTimer = null;
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

  /// Host y puerto del ping: el servidor Odoo activo (lo que importa a la app).
  /// Se cachea un minuto para no leer prefs en cada ping.
  Future<(String, int)> _resolvePingTarget() async {
    final at = _pingTargetAt;
    if (_pingTarget != null &&
        at != null &&
        DateTime.now().difference(at) < _pingTargetTtl) {
      return _pingTarget!;
    }
    final url = await PrefUtils.getEnterprise();
    final uri = Uri.tryParse(url.trim());
    final target = (uri == null || uri.host.isEmpty)
        ? (_fallbackPingHost, 443)
        : (
            uri.host,
            uri.hasPort ? uri.port : (uri.scheme == 'http' ? 80 : 443),
          );
    _pingTarget = target;
    _pingTargetAt = DateTime.now();
    return target;
  }

  Future<void> _measurePing() async {
    if (!mounted || _pinging) return;
    final network = getIt<NetworkInfo>();
    if (network.current == ConnectionStatus.offline) {
      if (_quality != _NetQuality.offline) {
        setState(() {
          _quality = _NetQuality.offline;
          _pingMs = null;
        });
      }
      return;
    }
    _pinging = true;
    try {
      final (host, port) = await _resolvePingTarget();
      final sw = Stopwatch()..start();
      final socket = await Socket.connect(host, port, timeout: _pingTimeout);
      sw.stop();
      socket.destroy();
      final ms = sw.elapsedMilliseconds;
      if (!mounted) return;
      setState(() {
        _pingMs = ms;
        _quality = ms < 100
            ? _NetQuality.excellent
            : ms < 300
            ? _NetQuality.good
            : _NetQuality.poor;
      });
    } catch (_) {
      // Un ping fallido no es "sin conexión": eso lo decide NetworkInfo.
      if (!mounted) return;
      setState(() {
        _pingMs = null;
        _quality = network.current == ConnectionStatus.offline
            ? _NetQuality.offline
            : _NetQuality.poor;
      });
    } finally {
      _pinging = false;
    }
  }

  Future<void> _measureSpeed() async {
    if (NetworkQualityOverlay.disableNetworkCallsForTesting) return;
    if (_speedState == _SpeedState.measuring) return;
    if (getIt<NetworkInfo>().current == ConnectionStatus.offline) return;
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
      case _NetQuality.excellent:
        return Colors.greenAccent;
      case _NetQuality.good:
        return Colors.orangeAccent;
      case _NetQuality.poor:
        return Colors.redAccent;
      case _NetQuality.offline:
        return Colors.grey;
    }
  }

  String get _qualityLabel {
    switch (_quality) {
      case _NetQuality.measuring:
        return 'Midiendo…';
      case _NetQuality.excellent:
        return 'Excelente';
      case _NetQuality.good:
        return 'Regular';
      case _NetQuality.poor:
        return 'Débil';
      case _NetQuality.offline:
        return 'Sin señal';
    }
  }

  int get _signalBars {
    switch (_quality) {
      case _NetQuality.measuring:
        return 0;
      case _NetQuality.excellent:
        return 4;
      case _NetQuality.good:
        return 3;
      case _NetQuality.poor:
        return 1;
      case _NetQuality.offline:
        return 0;
    }
  }

  String get _pingText => _pingMs == null ? '—' : '${_pingMs}ms';

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
                    child: _isExpanded ? _buildExpanded() : _buildCollapsed(),
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
          _quality == _NetQuality.offline ? 'Sin señal' : _pingText,
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
              Text(
                'Ping: $_pingText',
                style: const TextStyle(color: Colors.white70, fontSize: 10),
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
