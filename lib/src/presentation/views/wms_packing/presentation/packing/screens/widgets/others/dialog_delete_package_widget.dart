import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/packing_response_model.dart';

/// Confirmación para eliminar un paquete completo (transferencias/delete_pack).
///
/// A diferencia de [DialogUnPacking], que saca un solo producto, acá se van el
/// paquete y todos sus productos, que vuelven a "por hacer".
class DialogDeletePackage extends StatelessWidget {
  const DialogDeletePackage({
    super.key,
    required this.package,
    required this.onConfirm,
  });

  final Paquete package;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final cantidad = package.cantidadProductos ?? 0;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: Center(
          child: Text(
            'Eliminar paquete',
            style: TextStyle(color: primaryColorApp, fontSize: 16),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: black),
                children: [
                  const TextSpan(text: '¿Seguro que deseas eliminar el '),
                  TextSpan(
                    text: '${package.name ?? package.consecutivo ?? ''}',
                    style: TextStyle(
                      color: primaryColorApp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              cantidad > 0
                  ? 'Se eliminará el paquete y sus $cantidad producto(s) volverán a "Por hacer".'
                  : 'Se eliminará el paquete y sus productos volverán a "Por hacer".',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: grey),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cancelar', style: TextStyle(color: white)),
          ),
          ElevatedButton(
            onPressed: () {
              // Se cierra primero: si la navegación o un loader llegan con el
              // diálogo abierto, terminan reemplazando la ruta equivocada.
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Eliminar', style: TextStyle(color: white)),
          ),
        ],
      ),
    );
  }
}
