import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Diálogo de confirmación antes de tomar una expedición (asignar
/// responsable + iniciar tiempo). Propio de expedition, no reusa el de
/// packing para mantener el módulo autocontenido.
class DialogAsignarExpedicionWidget extends StatelessWidget {
  final VoidCallback onAccepted;
  final VoidCallback onCancel;

  const DialogAsignarExpedicionWidget({
    super.key,
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
            'Asignar a usuario',
            textAlign: TextAlign.center,
            style: TextStyle(color: primaryColorApp, fontSize: 18),
          ),
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '¿Está seguro de tomar esta expedición? Una vez asignada, no se puede modificar el responsable desde la app, se registrara el tiempo de inicio de la expedición.',
                textAlign: TextAlign.center,
                style: TextStyle(color: black, fontSize: 14),
              ),
              SizedBox(height: 10),
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
            child: const Text('Empezar', style: TextStyle(color: white)),
          ),
        ],
      ),
    );
  }
}
