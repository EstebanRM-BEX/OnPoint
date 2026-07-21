import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/main.dart'; // Acceso al navigatorKey global

/// Muestra un diálogo de error con contenido scrolleable.
///
/// Usa el `navigatorKey` global (igual que HttpResponseHandler), por lo que
/// puede llamarse desde cualquier parte sin necesidad de un BuildContext.
Future<void> showScrollableErrorDialog(String errorMessage) async {
  final context = navigatorKey.currentContext;
  if (context == null) return;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: const Text(
        '360 Software Informa',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.red, fontSize: 18),
      ),
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
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(dialogContext).pop(); // Cierra el diálogo
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
    ),
  );
}
