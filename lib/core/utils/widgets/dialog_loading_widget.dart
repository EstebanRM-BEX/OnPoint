// ignore_for_file: file_names

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DialogLoadingNetwork extends StatelessWidget {
  const DialogLoadingNetwork({
    super.key,
    required this.titel,
  });

  final String titel;

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
            SizedBox(
              height: 100,
              width: 200,
              child: SvgPicture.asset(
                "assets/images/icono2.svg",
                height: 150,
                width: 50,
                fit: BoxFit.cover,
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                'Cargando Información...',
                style: TextStyle(color: primaryColorApp, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            const Text('Espera un momento...',
                style: TextStyle(color: grey, fontSize: 12)),
            // Text(titel, style: TextStyle(color: grey, fontSize: 9)),
          ],
        )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: CircularProgressIndicator(
                color: primaryColorApp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
