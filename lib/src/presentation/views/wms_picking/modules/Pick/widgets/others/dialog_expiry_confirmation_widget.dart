import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Confirmación cuando el backend rechaza el picking por productos con fecha
/// de caducidad alcanzada (error `expiry.picking.confirmation`).
class DialogExpiryConfirmation extends StatelessWidget {
  const DialogExpiryConfirmation({super.key, required this.onConfirm});

  /// Se ejecuta después de cerrar el diálogo cuando el usuario acepta
  /// continuar con los productos vencidos.
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: Colors.white,
        actionsAlignment: MainAxisAlignment.center,
        title: const Text(
          '360 Software Informa',
          style: TextStyle(color: Colors.red, fontSize: 18),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Algunos productos tienen fecha de caducidad alcanzada.\n'
          '¿Desea continuar con la confirmacion aceptando los productos vencidos?',
          style: TextStyle(color: black, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColorApp,
              minimumSize: Size(size.width * 0.9, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Continuar',
              style: TextStyle(color: white, fontSize: 12),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: grey,
              minimumSize: Size(size.width * 0.9, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Descartar',
              style: TextStyle(color: white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
