import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Confirmación del pedido. [createBackorder] es la política del tipo de
/// operación en Odoo: `ask` (el operario elige), `always` o `never`.
///
/// Devuelve null si cancela, o si se crea backorder (true/false). Con
/// [onImprimir] muestra el botón de imprimir.
Future<bool?> showBackorderPackDialog(
  BuildContext context, {
  required double progresoEmpacado,
  required bool hayPendientes,
  required String createBackorder,
  VoidCallback? onImprimir,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => _BackorderPackDialog(
      progresoEmpacado: progresoEmpacado,
      hayPendientes: hayPendientes,
      createBackorder: createBackorder.isEmpty ? 'ask' : createBackorder,
      onImprimir: onImprimir,
    ),
  );
}

class _BackorderPackDialog extends StatelessWidget {
  final double progresoEmpacado;
  final bool hayPendientes;
  final String createBackorder;
  final VoidCallback? onImprimir;

  const _BackorderPackDialog({
    required this.progresoEmpacado,
    required this.hayPendientes,
    required this.createBackorder,
    this.onImprimir,
  });

  bool get _completo => progresoEmpacado >= 100 && !hayPendientes;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width * 0.9;
    final mensaje = _completo || createBackorder == 'never'
        ? '¿Estás seguro de confirmar el pedido para ser enviado?'
        : 'Usted ha procesado cantidades de productos menores que los '
              'requeridos en el movimiento original.';

    ButtonStyle estilo(Color c) => ElevatedButton.styleFrom(
      backgroundColor: c,
      minimumSize: Size(ancho, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: white,
        actionsAlignment: MainAxisAlignment.center,
        title: Text(
          'Confirmar Pedido',
          textAlign: TextAlign.center,
          style: TextStyle(color: primaryColorApp, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 90,
              child: SvgPicture.asset('assets/images/icono.svg'),
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: black, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              'Empacado: ${progresoEmpacado.toStringAsFixed(0)} %',
              style: TextStyle(color: primaryColorApp, fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (onImprimir != null)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onImprimir!();
              },
              style: estilo(primaryColorApp),
              icon: const Icon(Icons.print, color: white),
              label: const Text('Imprimir', style: TextStyle(color: white)),
            ),
          if (createBackorder == 'ask' && !_completo)
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: estilo(primaryColorApp),
              child: const Text(
                'Confirmar y Crear un Backorder',
                style: TextStyle(color: white, fontSize: 12),
              ),
            ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, createBackorder == 'always'),
            style: estilo(primaryColorApp),
            child: const Text(
              'Confirmar Pedido',
              style: TextStyle(color: white, fontSize: 12),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: estilo(grey),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
