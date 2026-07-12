import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Menú de orden (fecha/nombre/cliente) + acceso al filtro por propietario,
/// usado en el header de [ListExpeditionScreen].
class ExpedicionSortMenuWidget extends StatelessWidget {
  final String currentFilterKey;
  final void Function(String field, bool ascending) onSort;
  final VoidCallback onFilterPropietario;

  const ExpedicionSortMenuWidget({
    super.key,
    required this.currentFilterKey,
    required this.onSort,
    required this.onFilterPropietario,
  });

  TextStyle _menuStyle(bool active) => TextStyle(
        color: active ? primaryColorApp : black,
        fontWeight: active ? FontWeight.bold : FontWeight.normal,
      );

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (value) {
        switch (value) {
          case 'fecha_desc':
            onSort('fecha', false);
            break;
          case 'fecha_asc':
            onSort('fecha', true);
            break;
          case 'nombre_asc':
            onSort('nombre', true);
            break;
          case 'nombre_desc':
            onSort('nombre', false);
            break;
          case 'cliente_asc':
            onSort('cliente', true);
            break;
          case 'cliente_desc':
            onSort('cliente', false);
            break;
          case 'filter_propietario':
            onFilterPropietario();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          enabled: false,
          child:
              Text('FECHA', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        PopupMenuItem(
          value: 'fecha_desc',
          child: Text('Más reciente primero',
              style: _menuStyle(currentFilterKey == 'fecha_desc')),
        ),
        PopupMenuItem(
          value: 'fecha_asc',
          child: Text('Más antiguo primero',
              style: _menuStyle(currentFilterKey == 'fecha_asc')),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          enabled: false,
          child: Text('CONSECUTIVO',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        PopupMenuItem(
          value: 'nombre_asc',
          child:
              Text('A-Z', style: _menuStyle(currentFilterKey == 'nombre_asc')),
        ),
        PopupMenuItem(
          value: 'nombre_desc',
          child: Text('Z-A',
              style: _menuStyle(currentFilterKey == 'nombre_desc')),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          enabled: false,
          child:
              Text('CLIENTE', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        PopupMenuItem(
          value: 'cliente_asc',
          child: Text('A-Z',
              style: _menuStyle(currentFilterKey == 'cliente_asc')),
        ),
        PopupMenuItem(
          value: 'cliente_desc',
          child: Text('Z-A',
              style: _menuStyle(currentFilterKey == 'cliente_desc')),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'filter_propietario',
          child: Text('Filtrar por propietario'),
        ),
      ],
    );
  }
}
