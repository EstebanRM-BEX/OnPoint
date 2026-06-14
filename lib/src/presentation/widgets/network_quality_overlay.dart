import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:wms_app/src/presentation/providers/network_overlay/network_overlay_cubit.dart';

enum _NetQuality { excellent, good, poor, offline }

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

class _NetworkQualityOverlayState extends State<NetworkQualityOverlay> {
  static const _pingHost = 'google.com';
  static const _pingInterval = Duration(seconds: 5);
  static const _speedTestUrl =
      'https://speed.cloudflare.com/__down?bytes=512000';

  // Posición draggable — null hasta que se conoce el tamaño de pantalla
  Offset? _position;

  _NetQuality _quality = _NetQuality.excellent;
  int _pingMs = 0;
  String _connectionType = '';
  bool _isExpanded = false;

  _SpeedState _speedState = _SpeedState.idle;
  double _speedMbps = 0;

  Timer? _pingTimer;
  StreamSubscription? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  // Posición inicial: esquina superior derecha, calculada una sola vez
  Offset _initialPosition(Size screen) {
    return Offset(screen.width - 90, MediaQuery.of(context).padding.top + 8);
  }

  void _onPanUpdate(DragUpdateDetails details, Size screen) {
    final current = _position!;
    const margin = 4.0;
    final newX =
        (current.dx + details.delta.dx).clamp(margin, screen.width - 80);
    final newY = (current.dy + details.delta.dy)
        .clamp(MediaQuery.of(context).padding.top + margin, screen.height - 60);
    setState(() => _position = Offset(newX, newY));
  }

  void _onTap() {
    final wasExpanded = _isExpanded;
    setState(() => _isExpanded = !_isExpanded);
    if (!wasExpanded) _measureSpeed();
  }

  void _startMonitoring() {
    if (NetworkQualityOverlay.disableNetworkCallsForTesting) return;
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      _updateConnectionType(result);
    });
    _pingTimer = Timer.periodic(_pingInterval, (_) => _measurePing());
    _measurePing();
  }

  void _updateConnectionType(ConnectivityResult result) {
    if (!mounted) return;
    setState(() {
      switch (result) {
        case ConnectivityResult.wifi:
          _connectionType = 'WiFi';
        case ConnectivityResult.mobile:
          _connectionType = 'Datos móviles';
        case ConnectivityResult.ethernet:
          _connectionType = 'Ethernet';
        case ConnectivityResult.none:
          _connectionType = 'Sin conexión';
          _quality = _NetQuality.offline;
        default:
          _connectionType = 'Desconocido';
      }
    });
  }

  Future<void> _measurePing() async {
    if (!mounted) return;
    try {
      final sw = Stopwatch()..start();
      final socket = await Socket.connect(_pingHost, 80,
          timeout: const Duration(seconds: 4));
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
      if (!mounted) return;
      setState(() {
        _quality = _NetQuality.offline;
        _pingMs = 0;
      });
    }
  }

  Future<void> _measureSpeed() async {
    if (NetworkQualityOverlay.disableNetworkCallsForTesting) return;
    if (_speedState == _SpeedState.measuring) return;
    setState(() {
      _speedState = _SpeedState.measuring;
      _speedMbps = 0;
    });
    try {
      final sw = Stopwatch()..start();
      final response = await http
          .get(Uri.parse(_speedTestUrl))
          .timeout(const Duration(seconds: 15));
      sw.stop();
      final mbps =
          (response.bodyBytes.length * 8) / (sw.elapsedMilliseconds / 1000.0 * 1000000);
      if (!mounted) return;
      setState(() {
        _speedMbps = mbps;
        _speedState = _SpeedState.done;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _speedState = _SpeedState.error);
    }
  }

  Color get _qualityColor {
    switch (_quality) {
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

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    _position ??= _initialPosition(screen);

    return BlocBuilder<NetworkOverlayCubit, bool>(
      builder: (context, visible) => Stack(
        children: [
          widget.child,
          if (visible)
          Positioned(
            left: _position!.dx,
            top: _position!.dy,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _onTap,
              onPanUpdate: (d) => _onPanUpdate(d, screen),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _qualityColor.withOpacity(0.6), width: 1),
                ),
                child: _isExpanded ? _buildExpanded() : _buildCollapsed(),
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
          _quality == _NetQuality.offline ? 'Sin señal' : '${_pingMs}ms',
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
                'Ping: ${_pingMs}ms',
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
                  strokeWidth: 1.5, color: Colors.white54),
            ),
            SizedBox(width: 5),
            Text('Midiendo...',
                style: TextStyle(color: Colors.white54, fontSize: 10)),
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
                    fontWeight: FontWeight.bold),
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
              Text('Error — reintentar',
                  style:
                      TextStyle(color: Colors.orangeAccent, fontSize: 10)),
            ],
          ),
        );

      case _SpeedState.idle:
        return const SizedBox.shrink();
    }
  }
}

class _SignalBars extends StatelessWidget {
  final int bars;
  final Color color;
  final double size;

  const _SignalBars(
      {required this.bars, required this.color, required this.size});

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
