import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Diálogo para ver la observación o novedad completa de la expedición
/// cuando excede más de 2 líneas en [ExpedicionDetailTabDetalles].
class DialogObservacionExpedicionWidget extends StatelessWidget {
  final String observacion;
  final String? titulo;

  const DialogObservacionExpedicionWidget({
    super.key,
    required this.observacion,
    this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
        actionsAlignment: MainAxisAlignment.center,
        title: Row(
          children: [
            Icon(Icons.notes_rounded, color: primaryColorApp, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                titulo ?? 'Observación',
                style: TextStyle(
                  color: primaryColorApp,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.45,
          ),
          decoration: BoxDecoration(
            color: grey.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: grey.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: SelectableText(
              observacion,
              style: const TextStyle(
                color: black,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColorApp,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            ),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
