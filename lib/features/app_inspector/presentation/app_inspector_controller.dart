import 'package:flutter/foundation.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';

/// Visibilidad del botón flotante del inspector (por dispositivo, en prefs).
class AppInspectorController extends ChangeNotifier {
  AppInspectorController._();
  static final AppInspectorController instance = AppInspectorController._();

  bool _visible = false;
  bool get visible => _visible;

  Future<void> load() async {
    _visible = await PrefUtils.getAppInspectorVisible();
    notifyListeners();
  }

  Future<void> setVisible(bool value) async {
    _visible = value;
    notifyListeners();
    await PrefUtils.setAppInspectorVisible(value);
  }
}
