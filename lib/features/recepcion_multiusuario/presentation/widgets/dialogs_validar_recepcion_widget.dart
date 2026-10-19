import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/shared/widgets/selection_dialog.dart';

/// Opción elegida en [DialogConfirmarRecepcionMultiWidget].
enum OpcionConfirmarRecepcion { imprimir, conBackorder, sinBackorder }

/// Confirmación al validar la recepción multi, mismo diseño que el de
/// recepción individual (tab1.dart): Imprimir, Confirmar y Crear un
/// Backorder (solo si falta recibir), Confirmar Recepcion y Cancelar.
/// Devuelve la opción elegida o `null` (cancelar).
class DialogConfirmarRecepcionMultiWidget extends StatelessWidget {
  const DialogConfirmarRecepcionMultiWidget({
    super.key,
    required this.recepcionCompleta,
  });

  /// progress_percent >= 100: no hay nada pendiente para un backorder.
  final bool recepcionCompleta;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    Widget boton(
      String texto,
      OpcionConfirmarRecepcion? opcion, {
      IconData? icon,
      Color color = primaryColorApp,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context, opcion),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            minimumSize: Size(size.width * 0.9, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: white),
                const SizedBox(width: 5),
              ],
              Text(texto, style: const TextStyle(color: white, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: Colors.white,
        actionsAlignment: MainAxisAlignment.center,
        title: Text(
          'Confirmar Recepcion',
          style: TextStyle(color: primaryColorApp, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 100,
              width: 200,
              child: SvgPicture.asset(
                'assets/images/icono.svg',
                height: 150,
                width: 50,
                fit: BoxFit.cover,
              ),
            ),
            Text(
              recepcionCompleta
                  ? '¿Estás seguro de confirmar la recepción y dejarla lista para ser enviada?'
                  : 'Usted ha procesado cantidades de productos menores que los requeridos en el movimiento original.',
              style: TextStyle(color: black, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          boton(
            'Imprimir',
            OpcionConfirmarRecepcion.imprimir,
            icon: Icons.print,
          ),
          if (!recepcionCompleta)
            boton(
              'Confirmar y Crear un Backorder',
              OpcionConfirmarRecepcion.conBackorder,
            ),
          boton('Confirmar Recepcion', OpcionConfirmarRecepcion.sinBackorder),
          boton('Cancelar', null, color: grey),
        ],
      ),
    );
  }
}

/// Odoo rechazó la validación por lotes vencidos. Devuelve `true` (recibir
/// también los vencidos), `false` (seguir sin ellos) o `null` (cancelar).
class DialogLotesVencidosWidget extends StatelessWidget {
  const DialogLotesVencidosWidget({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SelectionDialog(
      icon: Icons.event_busy_outlined,
      title: 'Lotes vencidos',
      message: message,
      options: [
        SelectionOption(
          title: 'Recibir también los vencidos',
          description: 'Se validan todos los lotes, incluidos los vencidos',
          icon: Icons.check_circle_outline,
          onTap: () => Navigator.pop(context, true),
        ),
        SelectionOption(
          title: 'Seguir sin los vencidos',
          description: 'Se valida dejando afuera los lotes vencidos',
          icon: Icons.remove_circle_outline,
          onTap: () => Navigator.pop(context, false),
        ),
      ],
    );
  }
}
