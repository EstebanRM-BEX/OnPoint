import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Opciones de búsqueda manual. Devuelve la opción elegida con
/// `Navigator.pop`; la página decide a dónde ir.
enum BusquedaManualOpcion { productos, ubicaciones, paquetes }

class BusquedaManualDialog extends StatelessWidget {
  const BusquedaManualDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: Colors.white,
        actionsAlignment: MainAxisAlignment.center,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'INFORMACIÓN RÁPIDA',
              textAlign: TextAlign.center,
              style: TextStyle(color: primaryColorApp, fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text(
              'Seleccione una de las siguientes opciones para realizar la búsqueda manual',
              textAlign: TextAlign.center,
              style: TextStyle(color: black, fontSize: 12),
            ),
            const SizedBox(height: 20),

            OptionCard(
              label: 'PRODUCTOS',
              onTap: () =>
                  Navigator.pop(context, BusquedaManualOpcion.productos),
            ),
            OptionCard(
              label: 'UBICACIONES',
              onTap: () =>
                  Navigator.pop(context, BusquedaManualOpcion.ubicaciones),
            ),
            OptionCard(
              label: 'PAQUETES',
              onTap: () =>
                  Navigator.pop(context, BusquedaManualOpcion.paquetes),
            ),
          ],
        ),
      ),
    );
  }
}

class OptionCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const OptionCard({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: primaryColorApp,
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        title: Center(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
