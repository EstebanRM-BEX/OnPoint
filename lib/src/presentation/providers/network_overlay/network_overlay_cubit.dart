import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';

class NetworkOverlayCubit extends Cubit<bool> {
  NetworkOverlayCubit() : super(false) {
    _loadFromPrefs();
  }

  /// Constructor solo para tests: establece el estado inicial sin leer prefs.
  @visibleForTesting
  NetworkOverlayCubit.withState(super.initial);

  Future<void> _loadFromPrefs() async {
    final visible = await PrefUtils.getNetworkOverlayVisible();
    emit(visible);
  }

  Future<void> setVisible(bool visible) async {
    await PrefUtils.setNetworkOverlayVisible(visible);
    emit(visible);
  }

  // Llamado en logout — restablece a true sin guardar en prefs
  // (clearPrefs ya removió la key, al next init leerá el default true)
  void reset() => emit(false);
}
