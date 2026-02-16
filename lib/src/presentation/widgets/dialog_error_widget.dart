import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';

Future<void> showScrollableErrorDialog(String errorMessage) async {
  Get.defaultDialog(
    title: '360 Software Informa',
    titleStyle: const TextStyle(color: Colors.red, fontSize: 18),
    content: Container(
      constraints: const BoxConstraints(
        maxHeight: 300.0,
        minHeight: 50,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10), // Padding interno

      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: Text(
            errorMessage, // Usamos el mensaje dinámico
            style: const TextStyle(color: Colors.black, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
    backgroundColor: Colors.white,
    radius: 10,
    actions: [
      ElevatedButton(
        onPressed: () {
          Get.back(); // Cierra el diálogo
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColorApp,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Aceptar',
          style: TextStyle(color: white),
        ),
      ),
    ],
  );
}
