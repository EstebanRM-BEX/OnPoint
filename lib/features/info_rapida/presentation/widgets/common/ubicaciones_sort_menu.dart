import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Menú "Ordenar" de las ubicaciones del producto. Devuelve el criterio del
/// bloc (`location`, `lote`, `date` = caducidad, `entrada`) y la dirección.
class UbicacionesSortMenu extends StatelessWidget {
  final void Function(String criterio, bool ascendente) onSelected;

  const UbicacionesSortMenu({super.key, required this.onSelected});

  static const _opciones = <String, (String, bool)>{
    'location_asc': ('location', true),
    'location_desc': ('location', false),
    'lote_asc': ('lote', true),
    'lote_desc': ('lote', false),
    'date_asc': ('date', true),
    'date_desc': ('date', false),
    'entrada_asc': ('entrada', true),
    'entrada_desc': ('entrada', false),
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: primaryColorApp, size: 20),
      onSelected: (value) {
        final opcion = _opciones[value];
        if (opcion != null) onSelected(opcion.$1, opcion.$2);
      },
      itemBuilder: (_) => <PopupMenuEntry<String>>[
        _titulo('UBICACIÓN'),
        _item('location_asc', Icons.arrow_upward, 'Nombre (A-Z)'),
        _item('location_desc', Icons.arrow_downward, 'Nombre (Z-A)'),
        const PopupMenuDivider(),
        _titulo('LOTE'),
        _item('lote_asc', Icons.arrow_upward, 'Ascendente (A-Z)'),
        _item('lote_desc', Icons.arrow_downward, 'Descendente (Z-A)'),
        const PopupMenuDivider(),
        _titulo('FECHA CADUCIDAD'),
        _item('date_asc', Icons.calendar_month, 'Más Próximas'),
        _item('date_desc', Icons.calendar_month, 'Más Lejanas'),
        _titulo('FECHA ENTRADA'),
        _item('entrada_asc', Icons.calendar_month, 'Más Antiguas'),
        _item('entrada_desc', Icons.calendar_month, 'Más Recientes'),
      ],
    );
  }

  PopupMenuItem<String> _titulo(String text) => PopupMenuItem<String>(
    enabled: false,
    height: 30,
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: Colors.grey,
      ),
    ),
  );

  PopupMenuItem<String> _item(String value, IconData icon, String label) =>
      PopupMenuItem<String>(
        value: value,
        height: 40,
        child: Row(
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      );
}
