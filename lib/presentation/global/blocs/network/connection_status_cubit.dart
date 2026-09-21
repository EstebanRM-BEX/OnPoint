import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/network/network_info.dart';

@injectable
class ConnectionStatusCubit extends Cubit<ConnectionStatus> {
  final NetworkInfo networkInfo;
  late final StreamSubscription _subscription;

  ConnectionStatusCubit({required this.networkInfo})
      : super(networkInfo.current) {
    _subscription = networkInfo.onStatusChanged.listen(emit);
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    super.close();
  }
}
