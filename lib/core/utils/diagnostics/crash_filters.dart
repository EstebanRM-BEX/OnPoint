import 'package:flutter/foundation.dart';

/// Errores de Flutter conocidos que no rompen la app y no deben contarse como
/// fatales en Crashlytics (afectan las métricas de "usuarios sin bloqueos").

/// Toque en un ítem de la rueda de selección de fecha (`CupertinoPicker`, la
/// usa `flutter_holo_date_picker`) cuando su controlador no tiene posición
/// asociada: `FixedExtentScrollController.selectedItem` → `ScrollController
/// .position` → `List.single` lanza "Bad state: No element".
///
/// Ocurre dentro del manejador del toque, Flutter lo atrapa y el único efecto
/// es que ese toque no selecciona el ítem; la app sigue funcionando. Se
/// reporta como no fatal para que no cuente como bloqueo.
bool isBenignDatePickerTapError(FlutterErrorDetails details) {
  final exception = details.exception;
  if (exception is! StateError) return false;
  if (!exception.message.contains('No element')) return false;
  final stack = details.stack?.toString() ?? '';
  return stack.contains('_CupertinoPickerState._handleChildTap');
}
