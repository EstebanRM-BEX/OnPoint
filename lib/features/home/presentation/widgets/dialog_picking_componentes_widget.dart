// ignore_for_file: file_names

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

class DialogPickingComponentes extends StatelessWidget {
  const DialogPickingComponentes({
    super.key,
    required this.contextHome,
  });

  final BuildContext contextHome;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: Colors.white,
        actionsAlignment: MainAxisAlignment.center,
        title: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SELECCION DE PICKING COMPONENTES',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryColorApp,
                  fontSize: 16,
                )),
            const SizedBox(height: 10),
            Center(
              child: Text(
                  'Seleccione una de las siguientes opciones para realizar el proceso de picking',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: black,
                    fontSize: 12,
                  )),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);

                  Navigator.pushReplacementNamed(
                    contextHome,
                    'picking-componentes-batch',
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 40),
                  backgroundColor: primaryColorApp,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('POR BATCH',
                    style: TextStyle(
                      color: white,
                      fontSize: 12,
                    ))),
            ElevatedButton(
                onPressed: () {
                  //cerramos el dialogo
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(
                    context,
                    'picking-componentes',
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 40),
                  backgroundColor: primaryColorApp,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('POR PICK',
                    style: TextStyle(
                      color: white,
                      fontSize: 12,
                    ))),
            ElevatedButton(
                onPressed: () {
                  //cerramos el dialogo
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: grey,
                  minimumSize: const Size(200, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('CANCELAR',
                    style: TextStyle(
                      color: white,
                      fontSize: 12,
                    ))),
          ],
        )),
      ),
    );
  }
}
