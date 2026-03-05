import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

class DialogConfirmProductLoadWidget extends StatelessWidget {
  const DialogConfirmProductLoadWidget({
    super.key,
    required this.productsBatch,
    required this.onAccept,
    this.onCancel,
  });

  final dynamic productsBatch;
  final VoidCallback onAccept;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        title: Center(
          child: Text("Confirmación",
              style: TextStyle(color: primaryColorApp, fontSize: 20)),
        ),
        content: Text.rich(
          TextSpan(
            text: "¿Está seguro que desea comenzar a separar ",
            style: const TextStyle(color: Colors.black), // estilo base
            children: [
              TextSpan(
                text: productsBatch.productId ?? "",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: primaryColorApp),
              ),
              if (productsBatch.lotId != null && productsBatch.lotId != "") ...[
                const TextSpan(
                  text: " con lote: ",
                  style: TextStyle(color: Colors.black),
                ),
                TextSpan(
                  text: productsBatch.lotId ?? "",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: primaryColorApp),
                ),
              ],
              const TextSpan(
                text: "?",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: primaryColorApp),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: grey,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                if (onCancel != null) {
                  onCancel!();
                }
              },
              child: const Text("Cancelar", style: TextStyle(color: white))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColorApp,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                onAccept();
              },
              child: const Text("Aceptar", style: TextStyle(color: white))),
        ],
      ),
    );
  }
}
