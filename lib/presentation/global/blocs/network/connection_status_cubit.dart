import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/network/network_info.dart';

@injectable
class ConnectionStatusCubit extends Cubit<ConnectionStatus> {
  final NetworkInfo networkInfo;
  late final StreamSubscription _subscription;

  ConnectionStatusCubit({required this.networkInfo})
      : super(ConnectionStatus.online) {
    _subscription = networkInfo.onStatusChanged.listen(emit);
    // Initialize with current status if possible or just wait for stream
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    final isConnected = await networkInfo.isConnected;
    if (isConnected) {
      emit(ConnectionStatus.online);
    } else {
      emit(ConnectionStatus.offline);
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    super.close();
  }
}
