import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/network/connectivity_extensions.dart';
import 'package:wms_app/core/network/reachability_probe.dart';

enum ConnectionStatus {
  online,
  offline,
}

/// Motivo por el que [ConnectionStatus.offline] (para mensajes al usuario).
enum NetworkIssue { none, noInternet, serverUnreachable }

/// Fuente única de verdad del estado de red.
abstract class NetworkInfo {
  /// Último estado conocido. Lectura síncrona y gratuita (sin I/O).
  ConnectionStatus get current;

  NetworkIssue get issue;

  /// Estado verificado. Usa caché corta: no repite la sonda si se acaba de
  /// verificar. Para operaciones críticas usar [verify] con `force`.
  Future<bool> get isConnected;

  Future<bool> verify({bool force = false});

  /// Una petición real falló por red: reverifica sin esperar a un timer.
  void reportNetworkError();

  Stream<ConnectionStatus> get onStatusChanged;
  void dispose();
}

/// Implementación event-driven: sin polling mientras la conexión es estable.
///
/// - `connectivity_plus` avisa de cambios de interfaz (barato, definitivo
///   cuando dice "none").
/// - [ReachabilityProbe] confirma el alcance real (servidor Odoo / internet).
/// - Estando offline reintenta con backoff exponencial (2→30 s).
/// - Se pausa en segundo plano y verifica al volver a primer plano.
@LazySingleton(as: NetworkInfo)
class NetworkInfoImpl with WidgetsBindingObserver implements NetworkInfo {
  final Connectivity connectivity;
  final ReachabilityProbe probe;
  final _controller = StreamController<ConnectionStatus>.broadcast();

  static const Duration _debounceDelay = Duration(milliseconds: 500);
  static const Duration _retryDelay = Duration(milliseconds: 500);
  static const Duration _onlineTtl = Duration(seconds: 8);
  static const Duration _offlineTtl = Duration(seconds: 2);
  static const Duration _maxBackoff = Duration(seconds: 30);
  static const int _failuresToGoOffline = 2;

  StreamSubscription<List<ConnectivityResult>>? _connectionSubscription;
  Timer? _debounceTimer;
  Timer? _backoffTimer;
  Future<bool>? _inFlight;

  ConnectionStatus _status = ConnectionStatus.online;
  NetworkIssue _issue = NetworkIssue.none;
  DateTime? _lastCheckAt;
  Duration _backoff = const Duration(seconds: 2);
  bool _paused = false;

  NetworkInfoImpl(this.connectivity, this.probe) {
    _connectionSubscription = connectivity.onConnectivityChanged.listen((_) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(_debounceDelay, () => verify(force: true));
    });
    WidgetsBinding.instance.addObserver(this);
    verify(force: true);
  }

  @override
  ConnectionStatus get current => _status;

  @override
  NetworkIssue get issue => _issue;

  @override
  Stream<ConnectionStatus> get onStatusChanged => _controller.stream;

  @override
  Future<bool> get isConnected => verify();

  @override
  Future<bool> verify({bool force = false}) {
    if (!force && _isFresh()) {
      return Future.value(_status == ConnectionStatus.online);
    }
    // Llamadas concurrentes comparten una sola sonda.
    return _inFlight ??= _check().whenComplete(() => _inFlight = null);
  }

  bool _isFresh() {
    final last = _lastCheckAt;
    if (last == null) return false;
    final ttl = _status == ConnectionStatus.online ? _onlineTtl : _offlineTtl;
    return DateTime.now().difference(last) < ttl;
  }

  @override
  void reportNetworkError() {
    // Con la sonda en curso o recién hecha no aporta nada.
    if (_inFlight != null || _isFresh() && _status == ConnectionStatus.offline) {
      return;
    }
    verify(force: true);
  }

  Future<bool> _check() async {
    // Sin interfaz de red: veredicto inmediato, sin tráfico.
    final interfaces = await connectivity.checkConnectivity();
    if (interfaces.isOffline) {
      _apply(ProbeResult.noInternet);
      return false;
    }

    // Histéresis: hacen falta 2 fallos seguidos para declarar offline.
    var result = ProbeResult.ok;
    for (var attempt = 1; attempt <= _failuresToGoOffline; attempt++) {
      result = await probe.check();
      if (result == ProbeResult.ok) break;
      if (attempt < _failuresToGoOffline) await Future.delayed(_retryDelay);
    }
    _apply(result);
    return result == ProbeResult.ok;
  }

  void _apply(ProbeResult result) {
    _lastCheckAt = DateTime.now();
    final online = result == ProbeResult.ok;
    _issue = switch (result) {
      ProbeResult.ok => NetworkIssue.none,
      ProbeResult.noInternet => NetworkIssue.noInternet,
      ProbeResult.serverUnreachable => NetworkIssue.serverUnreachable,
    };

    final next = online ? ConnectionStatus.online : ConnectionStatus.offline;
    if (next != _status) {
      _status = next;
      if (!_controller.isClosed) _controller.add(next);
    }

    _backoffTimer?.cancel();
    if (online) {
      _backoff = const Duration(seconds: 2);
    } else if (!_paused) {
      _backoffTimer = Timer(_backoff, () => verify(force: true));
      final doubled = _backoff * 2;
      _backoff = doubled > _maxBackoff ? _maxBackoff : doubled;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _paused = false;
      verify(force: true);
    } else if (state == AppLifecycleState.paused) {
      _paused = true;
      _backoffTimer?.cancel();
    }
  }

  @override
  @disposeMethod
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    _backoffTimer?.cancel();
    _connectionSubscription?.cancel();
    _controller.close();
  }
}
