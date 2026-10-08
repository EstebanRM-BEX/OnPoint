import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Menú de la cabecera del detalle de ubicación: editar y transferencia
/// masiva.
class LocationInfoMenu extends StatelessWidget {
  final bool isEdit;
  final bool massTransferActive;
  final VoidCallback onEdit;
  final VoidCallback onToggleMassTransfer;

  const LocationInfoMenu({
    super.key,
    required this.isEdit,
    required this.massTransferActive,
    required this.onEdit,
    required this.onToggleMassTransfer,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Material(
        color: Colors.white.withOpacity(0.15),
        shape: const CircleBorder(),
        child: SizedBox.square(
          dimension: 40,
          child: Icon(
            isEdit ? Icons.close : Icons.more_vert,
            color: white,
            size: 20,
          ),
        ),
      ),
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'mass_transfer') {
          onToggleMassTransfer();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(isEdit ? Icons.close : Icons.edit, color: Colors.black54),
              const SizedBox(width: 10),
              Text(isEdit ? "Cancelar edición" : "Editar ubicación"),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'mass_transfer',
          child: Row(
            children: [
              const Icon(Icons.swap_horiz, color: Colors.black54),
              const SizedBox(width: 10),
              Text(
                massTransferActive
                    ? "Desactivar transferencia masiva"
                    : "Activar transferencia masiva",
              ),
            ],
          ),
        ),
      ],
    );
  }
}
