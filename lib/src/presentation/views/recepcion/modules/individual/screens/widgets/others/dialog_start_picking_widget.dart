import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

class DialogAsignUserWidget extends StatelessWidget {
  final VoidCallback onAccepted; // Callback para la acción a ejecutar
  final VoidCallback onCancel;
  final String title;

  const DialogAsignUserWidget(
      {super.key,
      required this.onAccepted,
      required this.title,
      required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: 5,
        sigmaY: 5,
      ),
      child: AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        title: Center(
          child: Text(
            'Asignar a usuario',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryColorApp,
              fontSize: 18,
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: black,
                    fontSize: 14,
                  )),
              const SizedBox(height: 10),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
              onPressed: () {
                onCancel();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: grey,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: white),
              )),
          ElevatedButton(
              onPressed: () {
                onAccepted(); // Llama al callback
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColorApp,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text(
                'Empezar',
                style: TextStyle(color: white),
              ))
        ],
      ),
    );
  }
}
