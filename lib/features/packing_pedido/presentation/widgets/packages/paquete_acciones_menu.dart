import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

enum _AccionPaquete { imprimir, editar, eliminar }

/// Menú ⋮ de una caja: imprimir siempre; editar peso y eliminar solo si el
/// pedido es editable.
class PaqueteAccionesMenu extends StatelessWidget {
  final bool editable;
  final VoidCallback onImprimir;
  final VoidCallback onEditarPeso;
  final VoidCallback onEliminar;

  const PaqueteAccionesMenu({
    super.key,
    required this.editable,
    required this.onImprimir,
    required this.onEditarPeso,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_AccionPaquete>(
      tooltip: 'Opciones',
      color: white,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 150),
      icon: Icon(Icons.more_vert, color: primaryColorApp, size: 24),
      onSelected: (accion) => switch (accion) {
        _AccionPaquete.imprimir => onImprimir(),
        _AccionPaquete.editar => onEditarPeso(),
        _AccionPaquete.eliminar => onEliminar(),
      },
      itemBuilder: (_) => [
        _item(
          _AccionPaquete.imprimir,
          Icons.print,
          'Imprimir',
          primaryColorApp,
        ),
        if (editable) ...[
          _item(
            _AccionPaquete.editar,
            Icons.edit,
            'Editar peso',
            primaryColorApp,
          ),
          _item(
            _AccionPaquete.eliminar,
            Icons.delete_forever,
            'Eliminar',
            Colors.red,
          ),
        ],
      ],
    );
  }

  PopupMenuItem<_AccionPaquete> _item(
    _AccionPaquete value,
    IconData icon,
    String texto,
    Color color,
  ) => PopupMenuItem(
    value: value,
    child: Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Text(texto, style: TextStyle(fontSize: 14, color: color)),
      ],
    ),
  );
}
