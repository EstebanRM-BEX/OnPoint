// ignore_for_file: file_names

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

class DialogProductsNotSends extends StatelessWidget {
  const DialogProductsNotSends({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: Colors.white,
        actionsAlignment: MainAxisAlignment.center,
        title: Center(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning,
              color: Colors.amber[200],
              size: 80,
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                'Hay productos sin enviar',
                style: TextStyle(color: primaryColorApp, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
                'Por favor verifica los productos que estan pendientes de enviar en los batchs, para poder cargar mas procesos',
                style: TextStyle(color: grey, fontSize: 12)),
          ],
        )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColorApp,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(color: white),
                )),
          ],
        ),
      ),
    );
  }
}
