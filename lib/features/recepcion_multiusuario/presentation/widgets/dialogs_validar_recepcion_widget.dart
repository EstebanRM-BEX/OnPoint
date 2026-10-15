import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/shared/widgets/selection_dialog.dart';

/// Qué hacer con lo no recibido al validar la recepción multi. Devuelve
/// `true` (crear backorder), `false` (descartar pendiente) o `null`
/// (cancelar).
class DialogBackorderRecepcionWidget extends StatelessWidget {
  const DialogBackorderRecepcionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SelectionDialog(
      icon: Icons.fact_check_outlined,
      title: 'Validar recepción',
      message: '¿Qué hacer con las cantidades que no se recibieron?',
      options: [
        SelectionOption(
          title: 'Crear backorder',
          tag: 'Recomendado',
          description: 'Lo no recibido queda pendiente en otro documento',
          icon: Icons.call_split,
          onTap: () => Navigator.pop(context, true),
        ),
        SelectionOption(
          title: 'Descartar pendiente',
          description: 'Lo no recibido se elimina del documento',
          icon: Icons.delete_outline,
          onTap: () => Navigator.pop(context, false),
        ),
      ],
    );
  }
}

/// Segunda confirmación antes de validar sin backorder. Devuelve `true` si
/// el usuario confirma.
class DialogDescartarPendienteWidget extends StatelessWidget {
  const DialogDescartarPendienteWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        actionsPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        actionsAlignment: MainAxisAlignment.center,
        title: Center(
          child: Text(
            'Descartar pendiente',
            textAlign: TextAlign.center,
            style: TextStyle(color: primaryColorApp, fontSize: 18),
          ),
        ),
        content: Text(
          'Lo que no se recibió se eliminará y no quedará pendiente en '
          'ningún documento. ¿Desea continuar?',
          textAlign: TextAlign.center,
          style: TextStyle(color: black, fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context, false),
            style: ElevatedButton.styleFrom(
              backgroundColor: grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cancelar', style: TextStyle(color: white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Descartar', style: TextStyle(color: white)),
          ),
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
