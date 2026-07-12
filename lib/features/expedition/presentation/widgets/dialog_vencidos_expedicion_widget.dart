import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Reintento cuando complete_transfer falla porque hay productos con fecha
/// de vencimiento superada (error backend `expiry.picking.confirmation`) —
/// mismo caso que Tab1PedidoScreen de packing, pero como widget propio.
class DialogVencidosExpedicionWidget extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onDiscard;

  const DialogVencidosExpedicionWidget({
    super.key,
    required this.onContinue,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        title: Center(
          child: Text(
            '360 Software Informa',
            textAlign: TextAlign.center,
            style: TextStyle(color: red, fontSize: 18),
          ),
        ),
        content: const Text(
          'Algunos productos tienen fecha de caducidad alcanzada.\n'
          '¿Desea continuar con la confirmación aceptando los productos vencidos?',
          textAlign: TextAlign.center,
          style: TextStyle(color: black, fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: onDiscard,
            style: ElevatedButton.styleFrom(
              backgroundColor: grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Descartar', style: TextStyle(color: white)),
          ),
          ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColorApp,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Continuar', style: TextStyle(color: white)),
          ),
        ],
      ),
    );
  }
}
