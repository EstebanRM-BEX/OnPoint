import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Confirmación antes de reclamar un producto del pool (tab "Por hacer") —
/// evita que un toque accidental sobre la lista lo asigne sin querer.
class DialogConfirmarTomarProductoWidget extends StatelessWidget {
  const DialogConfirmarTomarProductoWidget({
    super.key,
    required this.productName,
    required this.onAccepted,
    required this.onCancel,
  });

  final String productName;
  final VoidCallback onAccepted;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        actionsPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        actionsAlignment: MainAxisAlignment.center,
        title: Center(
          child: Text(
            'Tomar producto',
            textAlign: TextAlign.center,
            style: TextStyle(color: primaryColorApp, fontSize: 18),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '¿Quieres tomar "$productName"? Quedará asignado a ti y '
                'bloqueado para los demás operarios.',
                textAlign: TextAlign.center,
                style: TextStyle(color: black, fontSize: 14),
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
            child: const Text('Tomar', style: TextStyle(color: white)),
          ),
        ],
      ),
    );
  }
}
