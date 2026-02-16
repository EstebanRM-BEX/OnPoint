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

  // Keep a reference to the subscription to cancel it if needed (though singleton usually lives forever)
  // ignore: unused_field
  StreamSubscription<List<ConnectivityResult>>? _connectionSubscription;

  NetworkInfoImpl(this.connectivity) {
    _connectionSubscription = connectivity.onConnectivityChanged.listen((_) {
      _checkInternetConnection();
    });
    // Initial check
    _checkInternetConnection();
  }

  @override
  Future<bool> get isConnected async {
    return await _checkInternetConnection();
  }

  @override
  Stream<ConnectionStatus> get onStatusChanged => _controller.stream;

  Future<bool> _checkInternetConnection() async {
    try {
      // Small delay to allow network to settle if switching networks
      await Future.delayed(const Duration(milliseconds: 500));
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _controller.add(ConnectionStatus.online);
        return true;
      } else {
        _controller.add(ConnectionStatus.offline);
        return false;
      }
    } on SocketException catch (_) {
      _controller.add(ConnectionStatus.offline);
      return false;
    }
  }

  @disposeMethod
  void dispose() {
    _connectionSubscription?.cancel();
    _controller.close();
  }
}
