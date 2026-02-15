import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wms_app/src/core/constans/colors.dart';

class DialogInfo extends StatelessWidget {
  const DialogInfo({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        title: Center(
            child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(color: primaryColorApp, fontSize: 20),
        )),
        content: Text(
          body,
          style: const TextStyle(color: black, fontSize: 16),
        ),
        actions: [
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColorApp,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text(
                'Aceptar',
                style: TextStyle(color: white),
              ))
        ],
      ),
    );
  }
}
