import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:injectable/injectable.dart';
import '../interfaces/i_vibration_service.dart';

@LazySingleton(as: IVibrationService)
class VibrationServiceImpl implements IVibrationService {
  @override
  Future<void> vibrate({int duration = 500}) async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: duration);
      debugPrint("Vibración ejecutada por $duration ms.");
    } else {
      debugPrint("El dispositivo no puede vibrar.");
    }
  }
}
