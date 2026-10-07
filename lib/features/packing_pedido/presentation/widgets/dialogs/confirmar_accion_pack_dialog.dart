import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Confirmación simple (sí/no) para acciones del packing. Devuelve true si
/// el operario acepta.
Future<bool> confirmarAccionPack(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String aceptar = 'Aceptar',
  bool destructiva = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: white,
      title: Text(
        titulo,
        textAlign: TextAlign.center,
        style: TextStyle(color: primaryColorApp, fontSize: 16),
      ),
      content: Text(
        mensaje,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, color: black),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: destructiva ? Colors.red[400] : primaryColorApp,
          ),
          child: Text(aceptar, style: const TextStyle(color: white)),
        ),
      ],
    ),
  );
  return r ?? false;
}
