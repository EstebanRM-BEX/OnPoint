import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Avisos de Información Rápida con el mismo estilo del módulo legacy.
class InfoRapidaSnackbar {
  const InfoRapidaSnackbar._();

  static void success(String message) =>
      _show(message, const Icon(Icons.check_circle, color: Colors.green));

  static void error(String message, {bool progress = false}) => _show(
    message,
    const Icon(Icons.error, color: Colors.red),
    progress: progress,
    duration: progress ? const Duration(seconds: 5) : null,
  );

  static void warning(String message) => _show(
    message,
    const Icon(Icons.error, color: Colors.amber),
    progress: true,
    duration: const Duration(seconds: 5),
  );

  static void blocked(String message) => _show(
    message,
    const Icon(Icons.block, color: Colors.red),
    duration: const Duration(seconds: 4),
  );

  static void info(String title, String message) => _show(
    message,
    const Icon(Icons.info_outline, color: primaryColorApp),
    title: title,
  );

  static void _show(
    String message,
    Icon icon, {
    String title = '360 Software Informa',
    bool progress = false,
    Duration? duration,
  }) {
    Get.snackbar(
      title,
      message,
      backgroundColor: white,
      colorText: primaryColorApp,
      icon: icon,
      showProgressIndicator: progress,
      duration: duration ?? const Duration(seconds: 3),
    );
  }
}
