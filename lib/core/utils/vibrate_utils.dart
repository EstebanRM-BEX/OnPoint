import 'package:vibration/vibration.dart';

class VibrationService {
  // 1. Instancia Singleton: Se inicializa una única vez
  static final VibrationService _instance = VibrationService._internal();

  // 2. Factory constructor para devolver la instancia única
  factory VibrationService() {
    return _instance;
  }

  // 3. Constructor privado para evitar que se creen nuevas instancias
  VibrationService._internal();

  /// Hace que el dispositivo vibre por una duración específica (en milisegundos).
  Future<void> vibrate({int duration = 500}) async {
    // 1. Verificar si el dispositivo tiene un vibrador
    if (await Vibration.hasVibrator() ?? false) {
      // 2. Hacer que vibre
      Vibration.vibrate(duration: duration);
      print("Vibración ejecutada por $duration ms.");
    } else {
      print("El dispositivo no puede vibrar.");
    }
  }
}