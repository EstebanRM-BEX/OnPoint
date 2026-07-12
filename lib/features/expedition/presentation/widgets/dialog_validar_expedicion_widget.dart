import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Diálogo de confirmación antes de validar un paquete o producto suelto en
/// scan_product_screen. Propio de expedition.
class DialogValidarExpedicionWidget extends StatelessWidget {
  final String message;
  final VoidCallback onAccepted;
  final VoidCallback onCancel;

  const DialogValidarExpedicionWidget({
    super.key,
    required this.message,
    required this.onAccepted,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        actionsPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        actionsAlignment: MainAxisAlignment.center,
        title: Center(
          child: Text(
            'Validar expedición',
            textAlign: TextAlign.center,
            style: TextStyle(color: primaryColorApp, fontSize: 18),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: black, fontSize: 14),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: onCancel,
            style: ElevatedButton.styleFrom(
              backgroundColor: grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cancelar', style: TextStyle(color: white)),
          ),
          ElevatedButton(
            onPressed: onAccepted,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColorApp,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Validar', style: TextStyle(color: white)),
          ),
        ],
      ),
    );
  }
}
