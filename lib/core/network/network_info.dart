import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

enum ConnectionStatus {
  online,
  offline,
}

/// Abstract interface for network connectivity checking.
abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<ConnectionStatus> get onStatusChanged;
  void dispose();
}

/// Implementation of [NetworkInfo] using connectivity_plus and InternetAddress verification.
@LazySingleton(as: NetworkInfo)
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;
  final _controller = StreamController<ConnectionStatus>.broadcast();

  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);
  static const Duration _debounceDelay = Duration(seconds: 1);
  static const Duration _lookupTimeout = Duration(seconds: 5);
  static const Duration _periodicInterval = Duration(seconds: 15);

  StreamSubscription<List<ConnectivityResult>>? _connectionSubscription;
  Timer? _debounceTimer;
  Timer? _periodicTimer;

  ConnectionStatus _lastStatus = ConnectionStatus.online;

  NetworkInfoImpl(this.connectivity) {
    _connectionSubscription = connectivity.onConnectivityChanged.listen((_) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(_debounceDelay, () {
        _checkInternetConnectionWithRetry();
      });
    });

    // Verificación periódica para detectar intermitencia sin eventos de red
    _periodicTimer = Timer.periodic(_periodicInterval, (_) {
      _checkInternetConnectionWithRetry();
    });

    // Verificación inicial
    _checkInternetConnectionWithRetry();
  }

  @override
  Future<bool> get isConnected async {
    return await _checkInternetConnectionWithRetry();
  }

  @override
  Stream<ConnectionStatus> get onStatusChanged => _controller.stream;

  Future<bool> _checkInternetConnectionWithRetry() async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      final connected = await _lookup();
      if (connected) {
        _emitIfChanged(ConnectionStatus.online);
        return true;
      }
      if (attempt < _maxRetries) {
        await Future.delayed(_retryDelay);
      }
    }
    _emitIfChanged(ConnectionStatus.offline);
    return false;
  }

  /// Solo emite al stream si el estado cambió, evitando rebuilds innecesarios
  /// en la UI por el timer periódico cuando la conexión es estable.
  void _emitIfChanged(ConnectionStatus status) {
    if (_lastStatus != status) {
      _lastStatus = status;
      _controller.add(status);
    }
  }

  Future<bool> _lookup() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(_lookupTimeout);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    }
  }

  @override
  @disposeMethod
  void dispose() {
    _debounceTimer?.cancel();
    _periodicTimer?.cancel();
    _connectionSubscription?.cancel();
    _controller.close();
  }
}
