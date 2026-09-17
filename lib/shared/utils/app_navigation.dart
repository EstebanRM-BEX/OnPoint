import 'package:flutter/material.dart';

/// Navegación entre pantallas de un módulo, sin dejar rutas acumuladas.
///
/// `pushReplacementNamed` reemplaza la ruta de ARRIBA del stack, no "la
/// pantalla": si en ese momento hay un diálogo abierto (el de red que abre
/// ApiRequestService con `isLoadinDialog: true`, un loader, una confirmación),
/// se come el diálogo y la pantalla anterior se queda debajo.
///
/// Eso hacía crecer el stack (visto en el árbol de widgets de packing:
/// List → Detail → Scan → Scan → Detail → List → …) y, peor que el consumo de
/// memoria, esas pantallas viejas seguían montadas y suscritas al mismo bloc:
/// reaccionaban a estados que no eran para ellas y navegaban por su cuenta.
///
/// Esto deja siempre UNA sola ruta viva, pase lo que pase con los diálogos.
///
/// Solo para flujos que navegan por nombre. NO usar donde la pantalla anterior
/// deba seguir viva para volver con `Navigator.pop` (pickers de lote,
/// ubicación, impresoras, o pantallas abiertas con `pushNamed`).
Future<T?> goToScreen<T extends Object?>(
  BuildContext context,
  String routeName, {
  Object? arguments,
}) {
  return Navigator.pushNamedAndRemoveUntil<T>(
    context,
    routeName,
    (_) => false,
    arguments: arguments,
  );
}
